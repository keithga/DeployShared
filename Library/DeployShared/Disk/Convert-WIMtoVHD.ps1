
function Convert-WIMtoVHD
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory=$true)]
        [string] $ImagePath,
        [parameter(Mandatory=$true)]
        [string] $VHDFile,
        [parameter(Mandatory=$true,ParameterSetName="Index")]
        [int]    $Index,
        [parameter(Mandatory=$true,ParameterSetName="Name")]
        [string] $Name,
        [int]    $Generation = 1,
        [uint64]  $SizeBytes = 120GB,
        [scriptblock] $AdditionalContent,
        $Aux,
        [switch] $Force
    )

    Write-Verbose "WIM [$WimFile]  to VHD [$VHDFile]"
    Write-Verbose "SizeBytes=$SIzeBytes  Generation:$Generation Force: $Force Index: $Index"

    if ( ( Test-Path $VHDFile) -and $Force )
    {
        dismount-vhd $VHDFile -ErrorAction SilentlyContinue | out-null
        remove-item -Force -Path $VHDFile | out-null
    }

    New-VHD -Path $VHDFile -SizeBytes $SizeBytes | Out-String | write-verbose

    $NewDisk = Mount-VHD -Passthru -Path $VHDFile
    $NewDisk | Out-String | Write-Verbose
    $NewDiskNumber = Get-VHD $VhdFile | Select-Object -ExpandProperty DiskNumber

    if ( -not  $NewDiskNumber )
    {
        throw "Unable to Mount VHD File"
    }

    Write-Verbose "Initialize Disk"

    Format-NewDisk -DiskID $NEwDiskNumber -Generation $Generation | write-verbose

    $ApplyPath = $NewDisk | get-partition | get-volume | where-object FileSystem -eq 'NTFS' | 
        sort -Property Size | Select-Object -last 1 | Foreach-object { $_.DriveLetter + ":" }

    # $ApplySys = $NewDisk | get-partition | where-object { ($_.Type -eq 'System') -or ( $_.Type -eq 'FAT32 XINT13') } | get-volume | Foreach-object { $_.DriveLetter + ":" }
    $ApplySys = $NewDisk | get-partition | get-volume | where-object FileSystemLabel -eq 'SYSTEM' | Foreach-object { $_.DriveLetter + ":" }
    
    write-verbose "Expand-WindowsImage Path [$ApplyPath] and System: [$ApplySys]"
    if ( -not $ApplySys ) { $ApplySys = $ApplyPath }
    write-verbose "Expand-WindowsImage Path [$ApplyPath] and System: [$ApplySys]"

    ########################################################

    $StdArgs = $PSBoundParameters | get-HashTableSubset -include ImagePath,Index,Name
    $StdArgs | Out-String | Write-verbose

    $LogArgs = Get-NewDismArgs
    write-verbose "Get WIM image information for $ImagePath"
    get-windowsimage -ImagePath $ImagePath | out-string | write-verbose
    Get-WindowsImage -ImagePath $ImagePath | %{ Get-WindowsImage -ImagePath $ImagePath -index $_.ImageIndex } | write-verbose
        
    $LogArgs = Get-NewDismArgs
    write-verbose "Expand-WindowsImage Path [$ApplyPath]"
    Expand-WindowsImage -ApplyPath "$ApplyPath\" @StdArgs @LogArgs | Out-String | Write-Verbose

    ########################################################

    write-verbose "Additional Content here!   param( $TargetDisk, $TargetDrive, $Aux ) "

    if ( $AdditionalContent )
    {
        Invoke-Command -ScriptBlock $AdditionalContent -ArgumentList $newDisk,$ApplySys, $aux
    }

    ########################################################

    Write-Verbose "$ApplyPath\Windows\System32\bcdboot.exe $ApplyPath\Windows /s $ApplySys /v"

    if ( $Generation -eq 1)
    {
        $BCDBootArgs = "$ApplyPath\Windows","/s","$ApplySys","/v"  # ,"/F","BIOS"
    }
    else
    {
        $BCDBootArgs = "$ApplyPath\Windows","/s","$ApplySys","/v","/F","UEFI"
    }
    start-CommandHidden -FilePath $ApplyPath\Windows\System32\bcdboot.exe -ArgumentList $BCDBootArgs | write-verbose

    if ( -not ( test-path "$ApplySys\boot\memtest.exe" ) ) { throw "missing $ApplySys\boot\memtest.exe" }

    write-verbose "Convert-WIMtoVHD FInished"

    Dismount-VHD -Path $VhdFile

}

