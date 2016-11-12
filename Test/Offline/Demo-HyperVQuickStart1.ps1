
#requires -version 4.0
#requires -runasadministrator

<#
.SYNOPSIS
Hyper-V Quick Starter program

.DESCRIPTION
Given a source *.iso image will auto mount and start the os locally in a Virtual Machine.

.LINK
http://ps2wiz.codeplex.com

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com) all rights reserved.
Microsoft Reciprocal License (Ms-RL) 
http://www.microsoft.com/en-us/openness/licenses.aspx

#>


[CmdletBinding()]
Param(

    [switch] $SkipPackage, # For recursion

    [parameter(HelpMessage="Operating System Source, as WIM or ISO")]
    [string] $SourceImageFile = 'e:\_cache\WIN2012R2S\9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO',

    [string] $VHDFile = 'd:\Virtual Hard Disks\ServerParent.vhdx',
    [string] $TargetWIM = 'E:\Release\_Server\ISO\Sources\install.wim',
    [string] $Gen1VHDFile = 'E:\Release\_Server\Gen1\ServerParent.vhdx',
    [string] $Gen2VHDFile = 'E:\Release\_Server\Gen2\ServerParent.vhdx',

    [string] $ExtraDir,

    [parameter(HelpMessage="Operating System Source index within WIM file")]
    [int] $ImageIndex = 2,

    [parameter(HelpMessage="Hyper-V Client Generation")]
    [int] $Generation = 1

)

$ErrorActionPreference = 'stop'


######################################################################

Function RunConsoleCommand 
{
<# 
.SYNOPSIS
Run a Console program Hidden and capture the output.

.PARAMETER
FilePath - Program Executable

.PARAMETER
ArgumentList - Array of arguments

.PARAMETER
RedirectStandardInput - text file for StdIn

.NOTES
Will output StdOut to Verbose.

#>
param
(
    [string] $FilePath,
    [string[]] $ArgumentList,
    [string] $RedirectStandardInput
)

    $DiskPartOut = [System.IO.Path]::GetTempFileName()
    $DiskPartErr = [System.IO.Path]::GetTempFileName()

    $DiskPartOut, $DiskPartErr | write-verbose
    $ArgumentList | out-string |write-verbose

    $prog = start-process -WindowStyle Hidden -PassThru -RedirectStandardError $DiskPartErr -RedirectStandardOutput $DiskPartOut @PSBoundParameters

    $Prog.WaitForExit()

    get-content $DiskPartOut | Write-Verbose
    get-content $DiskPartErr | Write-Error

    $DiskPartOut, $DiskPartErr, $RedirectStandardInput | Remove-Item -ErrorAction SilentlyContinue

}

function RunDiskPartCmds ( [string[]] $DiskPartCommands )
{
    $DiskPartCmd = [System.IO.Path]::GetTempFileName()
    $DiskPartCommands | out-file -encoding ascii -FilePath $DiskPartCmd
    RunConsoleCommand -FilePath "DiskPart.exe" -RedirectStandardInput $DiskPartCmd
}

######################################################################

function Get-WimData
{
<# 
.SYNOPSIS
Get the Wim File ready for extraction

.PARAMETER
SourceImageFile - Source file (Either *.wim or *.iso). 

.NOTES
Will mount the *.iso image if required.

#>
param(
    [parameter(Mandatory=$true,HelpMessage="Operating System Source, as WIM or ISO")]
    [System.IO.FileInfo] $SourceImageFile,
    [parameter(HelpMessage="Operating System Source index within WIM file")]
    [int] $ImageIndex = 0
)

    if ( $SourceImageFile.Extension -in ".iso",".img" )
    {

        Write-Verbose "DVD ISO processing..."
        if ((get-diskimage $SourceImageFile.FullName -erroraction silentlycontinue | Get-Volume) -isnot [object])
        {
            write-verbose "Mount DVD:  $($SourceImageFile.FullName)"
            mount-diskimage $SourceImageFile.FullName
        }

        $DVDDrive = Get-DiskImage $SourceImageFile.FullName | get-Volume
        $DVDDrive | out-string | write-verbose
        if ( $DVDDrive -isnot [Object] )
        { throw "Get-DiskImage Failed for $($SourceImageFile.FullName)" }

        $WimImage = "$($DVDDrive.DriveLetter)`:\sources\install.wim"
    }
    elseif ( $SourceImageFile.Extension -eq ".WIM" )
    {
        $WimImage = $SourceImageFile.FullName
    }

    if ( $ImageIndex -eq 0 )
    {
        Write-Verbose "Got image, now let's get the index $WimImage"
        $result = get-windowsimage -ImagePath $WimImage -LogPath ([System.IO.Path]::GetTempFileName()) |Select-object ImageIndex,ImageSize,ImageName | out-GridView -PassThru
        if ( $result.ImageIndex-as [int] -is [int] ) { $ImageIndex = $result.ImageIndex}
    }

    Write-Verbose "get info on $WimImage $ImageIndex  $($PWD.path)"
    $DetailedInfo = get-windowsimage -ImagePath $WimImage -Index $ImageIndex -LogPath ([System.IO.Path]::GetTempFileName())
    $DetailedInfo | out-string | write-verbose

    return $DetailedInfo

}

######################################################################

function new-DiskPartCmds
{
<# 
We use diskpart for format the new VHD(x), rather than native powershell commands due to uEFI limitations in PowerShell
http://www.altaro.com/hyper-v/creating-generation-2-disk-powershell/
#>
param(
    [parameter(Mandatory=$true)]
    [ValidateRange(1,20)]
    [int] $DiskID,
    [ValidateRange(1,2)]
    [int]  $Generation = 2,
    [string] $System = 'S',
    [string] $Windows = 'W',
    [string] $WinRE,
    [string] $Recovery,
    [int]  $recoverysize = 8KB
)

    function Set-DriveLetter ( [string] $VOl )
    {
        if ( $Vol.length -eq 1 ) { Write-Output "assign letter=""$Vol""" }
        elseif ( $Vol.length -gt 1 -and ( test-path $VOl ) ) { Write-Output "assign mount=""$Vol""" }
        else { throw "Bad assignment of VOlume Drive Letter or Mount Point $Vol" }
    }
    
    $PartType = 'mbr'
    $ReType = 'set id=27'
    $SysType = 'primary'
    if ( $Generation -eq 2 )
    {
        $PartType = 'gpt'
        $ReType = 'set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"','gpt attributes=0x8000000000000001'
        $SysType = 'efi'
    }
    
    $DiskPartCmds = @( "list disk","select disk $DiskID","clean","convert $PartType" )
    if ( $WinRE )
    {
        $DiskPartCmds += "rem == Windows RE tools partition ============"
        $DiskPartCmds += "create partition primary size=350",'format quick fs=ntfs label="Windows RE tools"'
        $DiskPartCmds += Set-DriveLetter $WinRE
        $DiskPartCmds += $ReType
    }

    $DiskPartCmds += "rem == System partition ======================"
    $DiskPartCmds += "create partition $SysType size=350", 'format quick fs=fat32 label="System"'
    $DiskPartCmds += Set-DriveLetter $System
    if ( $Generation -ne 2 ) 
    {
        $DiskPartCmds += "active"
    }
    else
    {
        $DiskPartCmds += "rem == Microsoft Reserved (MSR) partition ====","create partition msr size=128"
    }
    
    $DiskPartCmds += "rem == Windows partition ====================="
    $DiskPartCmds += "create partition primary"

    $DiskPartCmds += "rem == Create space for the recovery image ==="
    if ($RecoveryLetter) { $DiskPartCmds += "shrink minimum=$recoverysize" }

    $DiskPartCmds += "format quick fs=ntfs label=""Windows""" 
    if ( $Windows.Length -eq 1 ) { $DiskPartCmds += "assign letter=""$Windows""" } 
    if ( $Windows.Length -gt 1 -and ( test-path $Windows ) ) { $DiskPartCmds += "assign mount=""$Windows""" }

    if ( $Recovery )
    {
        $DiskPartCmds += "rem == Recovery image partition =============="
        $DiskPartCmds += "create partition primary",'format quick fs=ntfs label="Recovery image"'
        $DiskPartCmds += Set-DriveLetter $Recovery
        $DiskPartCmds += $ReType
    }

    $DiskPartCmds += "list volume","exit" 
    $DiskPartCmd = [System.IO.Path]::GetTempFileName()
    $DiskPartCmds | write-verbose
    $DiskPartCmds | out-file -encoding ascii -FilePath $DiskPartCmd
    RunConsoleCommand -FilePath "DiskPart.exe" -RedirectStandardInput $DiskPartCmd
}

Function Prepare-VHDFile
{
<# 
.SYNOPSIS
Create a VHD File

.PARAMETER
VHDFile - Name of the VHD File to create.

.OUTPUTS
Returns a custom object of the drives created.

.NOTES
Can create a Gen 1 or Gen 2 computer 

#>
param(
    [parameter(Mandatory=$True,HelpMessage="Name of the Target VHD(x) file")]
    [string] $VHDFile,

    [int64] $sizebytes = 80GB,

    [parameter(HelpMessage="Hyper-V Client Generation")]
    [int] $Generation = 2
)

    write-Verbose "Cleanup First..."
    if ( test-path $VHDFile ) 
    {
        dismount-vhd -Path $VHDFile -erroraction SilentlyContinue |out-null
        remove-item $VHDFile -confirm -force |out-null  
    }

    Write-Verbose "New VHD: $VHDFile"
    $Mount = New-VHD -Path $VHDFile -Dynamic -SizeBytes $sizebytes | Mount-VHD -PassThru
    $MOunt | out-string |write-verbose

    $Available = Get-ChildItem function:[F-Z]: -n | ? {([IO.DriveInfo] $_).DriveType -eq 'noRootdirectory' }
    $Windows = $Available[1]

    Write-Verbose "initialize-disk Generation($Generation)  $($mount.DiskNUmber)"
    New-DiskPartCmds -DiskID $($mount.DiskNUmber) -Generation $Generation -System $Available[0][0] -Windows $Windows[0] 
    
    Write-Verbose "Get the partition objects again so we can get the updated drive letters"
    return [PSCustomObject]@{ SystemPartition = $Available[0] ; OSPartition = $Windows } 

}

function Install-PackageWithADK
{
param(
    [string] $ForceADKDISM,
    [string] $Path,
    [string[]] $PackagePath
)

    write-verbose "Apply Packages"

    foreach ( $Package in $PackagePath )
    {

        for ( $I = 0; $i -lt 2; $i++ )
        {

            try 
            {
                $LogPath =[System.IO.Path]::GetTempFileName()
                write-verbose "Add-WindowsPackage $Package Log: $LogPath Pass $i"

                if ( $ForceADKDISM )
                {
                     & $ForceADKDISM "/image:$Path" /Add-Package "/PackagePath:$Package" /logpath:$LogPath # /PreventPending
                    if ( -not $? ) 
                    {
                        Write-Warning "DISM return $lastExitCode"
                        throw new-object System.InvalidOperationException
                    }
                }
                else 
                {
                    Add-WindowsPackage -LogPath $LogPath -NoRestart -PackagePath $Package -Path $Path # -PreventPending
                }
                $Success = $true
                break
            }
            catch [System.Runtime.InteropServices.COMException],[System.InvalidOperationException]
            {
                write-verbose "ARGH, for whatever reason, DISM is FAILING the first time, run again"
                write-warning ("retry {0}: '{1}'" -f ($_.Exception.GetType().FullName), ($_.Exception.Message))
            }
            catch
            {
                write-error ("error: {0}: '{1}'" -f ($_.Exception.GetType().FullName), ($_.Exception.Message)) -ErrorAction SilentlyContinue
                break;
                $Success = $False
            }

        }

<#
        # Imediate Cleanup...
        $tmplog = [System.IO.Path]::GetTempFileName()
        write-verbose "'$($MountedDrives.OSPartition)\windows\system32\Dism.exe' /Cleanup-Image '/image:$($MountedDrives.OSPartition)\'  '/logpath:$tmplog'"
        & "$($MountedDrives.OSPartition)\windows\system32\Dism.exe" /Cleanup-Image "/image:$($MountedDrives.OSPartition)\"  "/logpath:$tmplog" /StartComponentCleanup /ResetBase
        if ( -not $? ) 
        {
            Write-Warning "DISM return $lastExitCode"
            $tmplog = [System.IO.Path]::GetTempFileName()
            & "$($MountedDrives.OSPartition)\windows\system32\Dism.exe" /Cleanup-Image "/image:$($MountedDrives.OSPartition)\"  "/logpath:$tmplog" /StartComponentCleanup # /ResetBase

            if ( -not $? ) 
            {
                write-warning "detected failure"
                return $false
            }

        }
#>

    }

    return $true

}


######################################################################
##
##   Verification 
##
######################################################################

write-verbose "Export Source $SourceImageFile $ImageIndex"
$DetailedInfo = Get-WimData -SourceImageFile (get-item $SourceImageFile) -ImageIndex $ImageIndex

#############################
write-verbose "Create VHD Container"

$MountedDrives = Prepare-VHDFile -VHDFile $VhdFile -Generation $Generation

#############################
Write-verbose "Applying Image..."

if ( ! ( test-path "$($MountedDrives.OSPartition)\windows\System32\NTOSKRNL.exe" ) )
{
    Write-Verbose "Apply the Image $($DetailedInfo.ImagePath) to $($MountedDrives.OSPartition)   $($DetailedInfo.ImageIndex)"
    Expand-WindowsImage -ImagePath $($DetailedInfo.ImagePath) -ApplyPath $MountedDrives.OSPartition -Index $($DetailedInfo.ImageIndex) -confirm -LogPath ([System.IO.Path]::GetTempFileName()) | Out-String | write-verbose

}

# We may need to remap some of the boot entries if the Operating System Volume was mounted to a folder rather than a drive letter.
Write-Verbose "Apply the boot files to: $($MountedDrives.SystemPartition)"
$BCDArgs = "$($MountedDrives.OSPartition)\windows","/s",$MountedDrives.SystemPartition
if ( $Generation -eq 2 )
{
    Write-Verbose "BCDBOOT /F all"
    RunConsoleCommand -FilePath "BCDBoot.exe" -ArgumentList $BCDArgs, "/F","ALL" 
}
else
{
    Write-Verbose "BCDBOOT /F BIOS"
    RunConsoleCommand -FilePath "BCDBoot.exe" -ArgumentList $BCDArgs, "/F","BIOS" 
}

#############################

if ( $ExtraDir ) 
{
    if ( test-path $ExtraDir ) 
    {
        robocopy /e $ExtraDir "$($MountedDrives.OSPartition)\"
    }
}

#############################

if ( -not $SkipPackage )
{
    Write-Verbose "install packages:  $($PWD.path)"
    $result = Install-PackageWithADK -Path "$($MountedDrives.OSPartition)\" -PackagePath (get-childitem $PSScriptRoot\Updates -File | Select-Object -ExpandProperty FullName) -ForceADKDISM "$($MountedDrives.OSPartition)\windows\system32\Dism.exe"

    if ( $result[-1] -eq $false ) 
    {
        Dismount-DiskImage -ImagePath (Get-ChildItem $SourceImageFile).FullName
        dismount-Vhd -path $VHDFile

        write-error "failure to update"
        exit
    }

    Write-Verbose "Update Packages and save to $TargetWim"
    $Features = @( "NetFx3", "MSRDC-Infrastructure", "BITS", "ActiveDirectory-PowerShell", "WCF-NonHTTP-Activation", "WCF-HTTP-Activation", "WCF-HTTP-Activation45", "IIS-WMICompatibility", "IIS-ASPNET", "Bitlocker" )
    Enable-WindowsOptionalFeature -FeatureName $Features -All -LimitAccess -Path "$($MountedDrives.OSPartition)\" -Source "$(split-path $detailedinfo.imagepath)\Sxs" -LogPath ([System.IO.Path]::GetTempFileName())

    $tmplog = [System.IO.Path]::GetTempFileName()
    write-verbose "'$($MountedDrives.OSPartition)\windows\system32\Dism.exe' /Cleanup-Image '/image:$($MountedDrives.OSPartition)\'  '/logpath:$tmplog'"
    & "$($MountedDrives.OSPartition)\windows\system32\Dism.exe" /Cleanup-Image "/image:$($MountedDrives.OSPartition)\"  "/logpath:$tmplog" /StartComponentCleanup /ResetBase
    if ( -not $? ) 
    {
        Write-Warning "DISM return $lastExitCode"
        $tmplog = [System.IO.Path]::GetTempFileName()
        & "$($MountedDrives.OSPartition)\windows\system32\Dism.exe" /Cleanup-Image "/image:$($MountedDrives.OSPartition)\"  "/logpath:$tmplog" /StartComponentCleanup # /ResetBase

        if ( -not $? ) 
        {
            write-warning "detected failure"
            # return $false
        }

    }

}

write-verbose "Cleanup ISO Image: $ISOImage"
if ( (Get-ChildItem $SourceImageFile).Extension -in ".iso",".img" )
{
    Dismount-DiskImage -ImagePath (Get-ChildItem $SourceImageFile).FullName
}

if ( -not $SkipPackage )
{
    write-verbose "Create Windows image $TargetWim  current path: $($PWD.path)"
    if ( -not ( Test-Path  ( split-path $TargetWim) ) ) 
    {
        New-Item -ItemType Directory -path ( split-path $TargetWim) -ErrorAction SilentlyContinue -Force | out-null
    }
    if ( Test-Path $TargetWim )
    {
        Remove-Item $TargetWIM -Force 
    }
    
    New-WindowsImage -ImagePath $TargetWim -CapturePath "$($MountedDrives.OSPartition)\" -Name "ServerPatched" -CompressionType maximum -LogPath ([System.IO.Path]::GetTempFileName()) | Out-String | write-verbose

    dismount-Vhd -path $VHDFile

    Write-Verbose "############ START RECURSION!  $($PWD.path)"
    # THe only way to defragment the VHDX file is to export to a WIM and re-apply. 
    if ( Test-Path $Gen1VHDFile ) { Remove-Item -path $Gen1VHDFile -Force }
    & $PSScriptRoot\$($MyInvocation.MyCommand.Name) -VHDFile $Gen1VHDFile -SourceImageFile $TargetWim -ImageIndex 1 -Generation 1 -SkipPackage
    if ( Test-Path $Gen2VHDFile ) { Remove-Item -path $Gen2VHDFile -Force }
    & $PSScriptRoot\$($MyInvocation.MyCommand.Name) -VHDFile $Gen2VHDFile -SourceImageFile $TargetWim -ImageIndex 1 -Generation 2 -SkipPackage
    Write-Verbose "############ END RECURSION!"

    # remove-item $VHDFile
    # Remove-Item $TargetWim

}
else
{
    Dismount-VHD -Path $VhdFile
}
