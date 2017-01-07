
function Format-NewDisk
{
    <# 
    Foramt a disk in canonical way.

    We use diskpart for format the new VHD(x), rather than native powershell commands due to uEFI limitations in PowerShell
    http://www.altaro.com/hyper-v/creating-generation-2-disk-powershell/

    #>

    param
    (
        [parameter(Mandatory=$true)]
        [ValidateRange(1,20)]
        [int] $DiskID,

        [ValidateRange(1,2)]
        [int] $Generation = 1,

        [switch] $System = $True,
        [switch] $WinRE,
        [switch] $Recovery,
        [uint64] $recoverysize = 8GB
    )

    $PartType = 'mbr'
    $ReType = 'set id=27'
    $SysType = 'primary'
    if ( $Generation -eq 2 )
    {
        $PartType = 'gpt'
        $ReType = 'set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"','gpt attributes=0x8000000000000001'
        $SysType = 'efi'
    }

    write-verbose "Create Diskpart Commands"

    $DiskPartCmds = @( "list disk","select disk $DiskID","clean","convert $PartType" )

    if ( $WinRE )
    {
        $DiskPartCmds += "rem == Windows RE tools partition ============"
        $DiskPartCmds += "create partition primary size=350",'format quick fs=ntfs label="Windows RE tools"'
        # NO need to assign the WinRE Partition, Windows will auto mount during Setup.
        # $DiskPartCmds += "assign"
        $DiskPartCmds += $ReType
    }

    if ( $Generation -eq 2 -or $System )
    {
        $DiskPartCmds += "rem == System partition ======================"
        $DiskPartCmds += "create partition $SysType size=350", 'format quick fs=fat32 label="System"'
        $DiskPartCmds += "assign"
        if ( $Generation -ne 2 ) { $DiskPartCmds += "active" }
    }

    if ( $Generation -eq 2 ) 
    {
        $DiskPartCmds += "rem == Microsoft Reserved (MSR) partition ====","create partition msr size=128"
    }

    $DiskPartCmds += "rem == Windows partition ====================="
    $DiskPartCmds += "create partition primary"

    $DiskPartCmds += "rem == Create space for the recovery image ==="
    if ($Recovery) { $DiskPartCmds += "shrink minimum=" + ( ($RecoverySize / 1MB) -as [int] ) }
    $DiskPartCmds += "format quick fs=ntfs label=""Windows""","assign"

    if ( $Recovery )
    {
        $DiskPartCmds += "rem == Recovery image partition =============="
        $DiskPartCmds += "create partition primary",'format quick fs=ntfs label="Recovery image"'
        # $DiskPartCmds += "assign"
        $DiskPartCmds += $ReType
    }

    $DiskPartCmds += "list volume","exit" 

    write-verbose "Closeout Diskpart Commands"
    $DiskPArtCmds | write-verbose

    $ShellHWDetection = get-Service -Name ShellHWDetection
    if ( $ShellHWDetection.Status -eq 'Running' ) { Stop-service -name ShellHWDetection }

    Invoke-DiskPart -Commands $DiskPartCmds | Write-Output

    if ( $ShellHWDetection.Status -eq 'Running' ) { Start-service -name ShellHWDetection }

}
