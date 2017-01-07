
function Convert-VHDtoWIM
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory=$true)]
        [string] $ImagePath,
        [parameter(Mandatory=$true)]
        [string] $VHDFile,
        [string] $Name,
        # [string] $Description,
        [ValidateSet("Fast", "Max", "None")]
        [string] $CompressionType = 'fast',
        [switch] $Turbo,
        [switch] $Force
    )

    Write-Verbose "WIM [$ImagePath]  to VHD [$VHDFile]"
    Write-Verbose "SizeBytes=$SIzeBytes  Generation:$Generation Force: $Force Index: $Index"

    ####################################################

    Write-verbose "mount the VHD file"

    $NewDisk = Mount-VHD -Passthru -Path $VHDFile
    $NewDisk | Out-String | Write-Verbose
    $NewDiskNumber = Get-VHD $VhdFile | Select-Object -ExpandProperty DiskNumber

    if ( -not ( Get-VHD $VhdFile | Select-Object -ExpandProperty DiskNumber ) )
    {
        throw "Unable to Mount VHD File"
    }

    Write-Verbose "Initialize Disk"

    $CapturePath = $NewDisk | get-partition | get-volume | where-object FileSystem -eq 'NTFS' | 
        sort -Property Size | Select-Object -last 1 | Foreach-object { $_.DriveLetter + ":" }

    write-verbose "Capture Path: $CapturePath"

    if ( -not $CapturePath ) { throw "Missing Capture path for Disk $NewDisk" }

    ####################################################

    if ( $Turbo )
    {
        
        write-Verbose "Capture Windows Image /ImageFile:$ImagePath /CaptureDir:$CapturePath"
        & dism.exe /capture-image "/ImageFile:$ImagePath" "/CaptureDir:$CapturePath" "/Name:$Name" "/Compress:$CompressionType" "/ConfigFile:C:\Program Files\Microsoft Deployment Toolkit\Templates\Wimscript.ini"

    }
    else
    {

        $StdArgs = $PSBoundParameters | get-HashTableSubset -include 'CompressionType','ConfigFilePath','Description','CapturePath','ImagePath','Name'
        $StdArgs | Out-String | Write-verbose
        $LogArgs = Get-NewDismArgs

        write-verbose "Capture Windows Image"       
        New-WindowsImage @StdArgs @LogArgs

    }

    ####################################################

    write-verbose "dismount-vhd $VHDfile"
    dismount-vhd $VHDFile 

}
