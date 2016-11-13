

function New-HyperVirtualMachine
{
    param
    (
        [switch] $Force,
        [string] $Name,
        [string] $SwitchName,
        [string] $ISOFile,
        [int]   $ProcessorCount = 2,
        [ulong] $MemoryStartupBytes = 2GB,
        [ulong] $SizeBytes = 120GB,
        [int] $Generation = 1,
        [int] $Version = 5,
        [switch] $Startup,
        [swtich] $EmptyCheckpoint,
        [string] $GUID
    )

    Write-Verbose "Create a Virutal Machine: [$Name]"

    Write-Verbose "Fix/test any parameters"
    if ( -not (Get-VMHost).VirutalHardDiskPath ) { Throw 'get-VMHost.VirtualHardDiskPath not found!'}

    $VHDPath = "$((get-vmHost).VirtualHardDiskPath)\$($Name).vhd"

    if ( (Test-Path $VHDPath) -and $force)
    {
        Remove-item -Force $VHDPath -ErrorAction SilentlyContinue
    }

    if ( (Get-VM $Name) -and $force)
    {
        stop-vm -Name $Name -force -ErrorAction SilentlyContinue | Out-Null
        remove-vm -Name $Name -force -ErrorAction SilentlyContinue
    }

    if ( -not $SwitchName )
    {
        if ( Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue )
        {
            if ( (Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue | Measure-Object).Count -eq 1 )
            {
                $SwitchName = Get-VMSwitch -SwitchType External | Select-Object -ExpandProperty Name
            }
        }
    }
    if ( -not $SwitchName ) { throw "Missing Switch!" }

    Write-Verbose "new Virutal Machine"

    New-VHD -Path $VHDPath -SizeBytes $SizeBytes | Out-String | Write-Verbose
    $newVM = New-VM -Name $Name -SwitchName $SwitchName -VHDPath $VHDPath -Generation $Generation -Version $Version
    Set-VM -VM $NewVM -ProcessorCount $ProcessorCount -DynamicMemory -MemoryStartupBytes $MemoryStartupBytes -MemoryMinimumBytes $MemoryStartupBytes  | Out-String | Write-verbose

    if ( -not ( Test-Path $ISOFile )) { throw "Missing VHD: $VHDPath" }
    Set-VMDvdDrive -VMName $newVM.Name -Path $ISOFile | Out-String | Write-verbose

    if ( $GUID )
    {
        Write-Verbose "Force the GUID to $GUID"
        # TBD ???

    }

    if ( $EmptyCheckPoint ) { CheckPoint-VM -VM $NewVM -SnapShotName "Empty Virtual Machine"  | Out-String | Write-Verbose }
    if ( $Startup ) { Start-VM -VM $NewVM | Out-String | Write-Verbose }

    $NewVM | Out-Default

    <#
        Set-MDTCustomSettings -DPShare $DeploymentLocalPath -Category $uuid -Key "TaskSequenceID" -Value "$($Name)"
        Set-MDTCustomSettings -DPShare $DeploymentLocalPath -Category $uuid -Key "BackupFile" -Value "$($Name).wim"
        foreach ( $Property in 'OSRoleIndex','OSFeatures' )
        {
            if ( -not [string]::IsNullOrEmpty( $OSTSItem."$Property" ) )
            {
                Set-MDTCustomSettings -DPShare $DeploymentLocalPath -Category $uuid -Key "$Property" -Value $OSTSItem."$Property"
            }
        }
    #>

}