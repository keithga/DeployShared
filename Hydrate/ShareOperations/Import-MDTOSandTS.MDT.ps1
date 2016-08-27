
<#

.SYNOPSIS 
Hydration Script Module - Profile

.DESCRIPTION
Hydration Environment for MDTEx Powershell Common Modules
PrivateProfile tools (INI files)

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>

[CmdletBinding()]
param(
    [string] $CSVPackage,
    [string] $Cache,
    [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share.")]
    [string] $DeploymentLocalPath, # Example: c:\DeploymentShare
    [string] $DPDrive = "DS001",
    [parameter(ValueFromRemainingArguments=$true)] $Remaining
)

#region Prepare MDT environment 
##########################################################################
Write-Verbose "import-MDTOSandTS"

if ( -not ( Test-Path "$($DPDrive)`:")) 
{
    new-PSDrive -Name $DPDrive -PSProvider "MDTProvider" -Root $DeploymentLocalPath -Description "MDT Share" -scope script | out-string |write-verbose
}

new-item -ItemType directory -path $DeploymentLocalPath\TMP_cache -force -ErrorAction SilentlyContinue | out-null

$SwitchName = Get-VMSwitch -SwitchType External | Select-Object -First 1 -ExpandProperty Name

#endregion


foreach ( $OSTSItem in Import-Csv $CSVPackage )
{
    if ( -not $OSTSItem.Source ) { Continue }
    if ( $OSTSItem.Skip) { Continue }
    Write-Verbose ('*' * 79)
    $OSTSItem | Out-String | Write-Verbose
    $OSSourcePath = $OSTSItem.Source
    $OSIndex = 0

    #region copy image to cache
    ##########################################################################

    if ( $OSTSItem.Index ) 
    {
        $OSIndex = $OSTSItem.Index - 1
    }

    Write-Verbose "Test for ISO Image"
    if ( $OSTSItem.Source.ToUpper().EndsWith('.ISO') )
    {
        if ( -not ( Test-Path "$Cache\$($OSTSItem.OSID)" ) ) 
        {
            Write-Verbose "output: 'C:\Program Files\7-Zip\7z.exe' x '-o$Cache\$($OSTSItem.OSID)'  $($OSTSItem.Source)"
            & 'C:\Program Files\7-Zip\7z.exe' x "-o$Cache\$($OSTSItem.OSID)"  $OSTSItem.Source | Out-String |write-verbose
            $OSSourcePath = "$Cache\$($OSTSItem.OSID)"

            if ( $OSTSItem.WimOveride )
            {
                Write-Verbose "This is just a placeholder for future custom image, strip it and recapture."

                Move-Item "$OSSourcePath\Sources\Install.wim" "$OSSourcePath\Sources\Install.Old.wim" -Force
                Dism.exe /Export-Image "/SourceImageFile:$OSSourcePath\Sources\Install.Old.wim" "/SourceIndex:$($OSIndex + 1)" "/DestinationImageFile:$OSSourcePath\Sources\Install.wim" /DestinationName:CapturedImage 
                Remove-Item "$OSSourcePath\Sources\Install.Old.wim"
                $OSIndex = 0

            }
            elseif ( $OSTSItem.ForceUpdate )
            {
                $UpdateParams = @{
                    ImagePath = "$OSSourcePath\Sources\Install.wim"
                    Path = "$Cache\Updates\$($OSTSItem.OSID)\MountDir"
                    PackagePath = "$Cache\Updates\$($OSTSItem.OSID)"
                    Patches = ($ostsitem.forceupdate -split ',')
                    LogPath = "$env:temp\dism-update.log"
                    ForceADKDISM = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\dism.exe"
                    Index = $OSIndex + 1
                    }
                & $PSSCriptRoot\Support\Update-WIndows7.ps1 @UPdateParams -verbose

            }

        }
    }
    else
    {
        throw "unknown type $Source"
    }

    #endregion

    #region Import Operating Systems
    ##########################################################################

    $OSParams = @{
        Path = "$($DPDrive)`:\Operating Systems\$($OSTSItem.OSID)"
        DestinationFolder = "$($OSTSItem.OSID)"
        SourcePath = $OSSourcePath
    }

    $OSes = get-childitem -path "$($DPDrive)`:\Operating Systems" -Recurse | where-object Source -match $OSTSItem.OSID 
    if ( -not $OSes ) 
    {

        if ( $Cache )
        {
            "Create a Mklink pointer " | Write-Verbose
            if (-not ( test-path "$DeploymentLocalPath\TMP_Cache\$($OSTSItem.OSID)\sources\install.wim" ))
            {
                write-verbose "mklink /J '$DeploymentLocalPath\TMP_Cache\$($OSTSItem.OSID)' '$Cache\$($OSTSItem.OSID)'"
                & cmd.exe /c mklink /J "$DeploymentLocalPath\TMP_Cache\$($OSTSItem.OSID)" "$Cache\$($OSTSItem.OSID)"
            }
            $OSParams.Move = $True
            $OSParams.SourcePath = "$DeploymentLocalPath\TMP_Cache\$($OSTSItem.OSID)"
        }

        if ( -not ( Test-Path $OSParams.Path ) ) 
        {
            Write-Verbose "create OS Directory: $($OSParams.path)"
            new-item -ItemType Directory $OSParams.Path -Force | out-string | Write-Verbose
        }


        $OSParams | out-string | write-verbose
        $OSes = Import-MDTOperatingSystem @OSParams
    }

    $OSEs | Out-String |Write-Verbose

    #endregion

    #region Import Task Sequence 
    ##########################################################################

    if ( ($OSes |Measure-Object).count -gt 1 ) 
    {
        $SourceOS = $OSes[$OSIndex]
    }
    else
    {
        $SourceOS = $OSes | Select-Object -First 1
    }

    if ( -not ( Test-Path "$($DPDrive)`:\Task Sequences\$($OSTSItem.TSPath)" ) ) 
    {
        Write-Verbose "create TS Directory: $($OSParams.TSPath)"
        new-item -ItemType Directory "$($DPDrive)`:\Task Sequences\$($OSTSItem.TSPath)" -Force | out-string | write-verbose
    }

    $CommonParams = @{ 
        Path = "$($DPDrive)`:\Task Sequences\$($OSTSItem.TSPath)"
        template = $OSTSItem.template
        ID = $OSTSItem.TSID
        Name = $OSTSItem.Name
        OperatingSystem = $SourceOS
        FullName = 'Corporate User'
        OrgName = 'Corporate IT Department'
        HomePage = 'about:tabs'
    }

    $CommonParams | Out-String | write-verbose
    $NewTS = import-MDTTaskSequence @CommonParams

    if ( $OSTSItem.Hide) { $NewTS.Item('Hide') = $OSTSItem.Hide }

    #endregion

    #region Create entries in CS.ini


    if ( $OSTSItem.HyperV )
    {
        $Name = $OSTSItem.TSID
        Write-Verbose "Prepare for Hyper-V  [$Name]"

        $VHDPath = "$((get-vmHost).VirtualHardDiskPath)\$($Name).vhd"
        Remove-item -Force $VHDPath -ErrorAction SilentlyContinue

        remove-item $VHDPath -ErrorAction SilentlyContinue
        stop-vm -Name $Name -force -ErrorAction SilentlyContinue | Out-Null
        remove-vm -Name $Name -force -ErrorAction SilentlyContinue

        New-VHD -Path $VHDPath -SizeBytes 80GB | out-string | Write-Verbose
        $NewVM = New-VM -Name $Name -SwitchName $SwitchName -VHDPath $VHDPath
        Set-VM -VM $NewVM -ProcessorCount 4 -DynamicMemory -MemoryStartupBytes 3GB -MemoryMinimumBytes 3GB
        if ( Test-Path "$DeploymentLocalPath\boot\LitetouchPE_Automated_x86.iso" )
        {
            set-VMDVDDrive -VMName $NewVM.Name -Path "$DeploymentLocalPath\boot\LitetouchPE_Automated_x86.iso" 
        }

        $uuid = (get-wmiobject -Namespace "Root\virtualization\v2" -class Msvm_VirtualSystemSettingData -Property BIOSGUID -Filter ("InstanceID = 'Microsoft:{0}'" -f $NewVM.VMId.Guid)).BIOSGUID.SubString(1,36)
        Set-MDTCustomSettings -DPShare $DeploymentLocalPath -Category $uuid -Key "TaskSequenceID" -Value "$($Name)"
        Set-MDTCustomSettings -DPShare $DeploymentLocalPath -Category $uuid -Key "BackupFile" -Value "$($Name).wim"

        foreach ( $Property in 'OSRoleIndex','OSFeatures' )
        {
            if ( -not [string]::IsNullOrEmpty( $OSTSItem."$Property" ) )
            {
                Set-MDTCustomSettings -DPShare $DeploymentLocalPath -Category $uuid -Key "$Property" -Value $OSTSItem."$Property"
            }
        }

        CheckPoint-VM -VM $NewVM -SnapShotName "Empty Virtual Machine"
        Start-VM -VM $NewVM

    }

    #endregion
}

remove-item -path $DeploymentLocalPath\TMP_cache -force -ErrorAction SilentlyContinue 

Write-Verbose "Done OS import!"
