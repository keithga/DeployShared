
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
    [string] $SourceImageFile,

    [string] $VHDFile,

    [string] $ExtraDir,

    [parameter(HelpMessage="Operating System Source index within WIM file")]
    [int] $ImageIndex = 0,

    [parameter(HelpMessage="Hyper-V Client Generation")]
    [int] $Generation = 2

)


######################################################################

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
Function RunConsoleCommand 
(
    [string] $FilePath,
    [string[]] $ArgumentList,
    [string] $RedirectStandardInput
)
{

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

<# 
.SYNOPSIS
Get the Wim File ready for extraction

.PARAMETER
SourceImageFile - Source file (Either *.wim or *.iso). 

.NOTES
Will mount the *.iso image if required.

#>
function Get-WimData
(
    [parameter(Mandatory=$true,HelpMessage="Operating System Source, as WIM or ISO")]
    [System.IO.FileInfo] $SourceImageFile,
    [parameter(HelpMessage="Operating System Source index within WIM file")]
    [int] $ImageIndex = 0
)
{
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
        $result = get-windowsimage -ImagePath $WimImage |Select-object ImageIndex,ImageSize,ImageName | out-GridView -PassThru
        if ( $result.ImageIndex-as [int] -is [int] ) { $ImageIndex = $result.ImageIndex}
    }

    $DetailedInfo = get-windowsimage -ImagePath $WimImage -Index $ImageIndex
    $DetailedInfo | out-string | write-verbose

    return $DetailedInfo

}

######################################################################

function new-DiskPartCmds
(
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
{

<# 
We use diskpart for format the new VHD(x), rather than native powershell commands due to uEFI limitations in PowerShell
http://www.altaro.com/hyper-v/creating-generation-2-disk-powershell/
#>

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
Function Prepare-VHDFile
(
    [parameter(Mandatory=$True,HelpMessage="Name of the Target VHD(x) file")]
    [string] $VHDFile,

    [int64] $sizebytes = 80GB,

    [parameter(HelpMessage="Hyper-V Client Generation")]
    [int] $Generation = 2
)
{

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

######################################################################
##
##   Verification 
##
######################################################################

#############################
write-verbose "Export Source"
$DetailedInfo = Get-WimData -SourceImageFile $SourceImageFile -ImageIndex $ImageIndex

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
    $wimfile =  [System.IO.Path]::GetTempFileName() + ".WIM"
    Write-Verbose "Update Packages and save to $WimFile"
    $Features = @( "NetFx3", "MSRDC-Infrastructure", "BITS", "ActiveDirectory-PowerShell", "WCF-NonHTTP-Activation", "WCF-HTTP-Activation", "WCF-HTTP-Activation45", "IIS-WMICompatibility", "IIS-ASPNET" )
    Enable-WindowsOptionalFeature -FeatureName $Features -All -LimitAccess -Path "$($MountedDrives.OSPartition)\" -Source "$(split-path $detailedinfo.imagepath)\Sxs"
}

#############################

write-verbose "Cleanup ISO Image: $ISOImage"
if ( (Get-ChildItem $SourceImageFile).Extension -in ".iso",".img" )
{
    Dismount-DiskImage -ImagePath (Get-ChildItem $SourceImageFile).FullName
}

if ( -not $SkipPackage )
{
    & dism.exe /image:$($MountedDrives.OSPartition)\ /Add-Package /Packagepath:"$PSScriptRoot\Updates" /logpath:$([System.IO.Path]::GetTempFileName())
    & Dism /Cleanup-Image /image:$($MountedDrives.OSPartition)\

    New-WindowsImage -ImagePath $wimfile -CapturePath "$($MountedDrives.OSPartition)\" -Name "ServerPatched" -CompressionType none -LogPath ([System.IO.Path]::GetTempFileName()) | Out-String | write-verbose
    dismount-Vhd -path $VHDFile

    Move-Item $VHDFile "$($VHDFile)`.PrePatched`.Vhdx" -Force

    Write-Verbose "############ START RECURSION!"
    # Recursion!!
    & $PSScriptRoot\$($MyInvocation.MyCommand.Name) -VHDFile $VHDFile -SourceImageFile $wimfile -ImageIndex 1 -Generation $Generation -SkipPackage
    Write-Verbose "############ END RECURSION!"

    Remove-Item $wimfile

}

