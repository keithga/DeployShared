


[cmdletbinding()]
param(
    $SourcePath = 'D:\_Scratch\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US',

    $ISOTarget = "$env:temp\Cattle.iso",

    [ValidateSet("EFISys", "EFISys_noprompt","None")]
    $EFIBoot = 'EFISys_noprompt',
    
    $OSCDPath = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg',

    $VMName = "Cattle Test"
)

#region Restore any VM if selected
##############################################

if ( get-vm $VMName -ErrorAction SilentlyContinue )
{
    Write-Verbose "Stop VM $VMName"
    get-vm $VMName -ErrorAction SilentlyContinue | get-vmsnapshot | select-object -first 1 | Restore-VMSnapshot -confirm:$false
    start-sleep 1
}

#endregion

#region Extract ISO Source
##############################################

if ( Test-Path "$SourcePath\sources\install.wim" )
{
    robocopy /mir /ndl /nfl $SourcePath $env:temp\CattleSrc 
    copy-item -Force -Recurse -Path "$psscriptroot\src" $env:temp\CattleSrc
    $ISOSource = "$env:temp\CattleSrc"
}
else
{
    $ISOSource = "$psscriptroot\src"
}

#endregion

#region Create ISO Image
##############################################

$BootData = ''

if ( $EFIBoot -ne 'None' )
{
    $BootData = """-bootdata:2#p0,e,b$OSCDPath\etfsboot.com#pEF,e,b$OSCDPath\$($EFIBOOT).bin"""
}

write-verbose  "$OSCDPath\oscdimg.exe -u2 -udfver102 -m -o -h -w4 '$BootData' $ISOSource $isotarget"
&          "$OSCDPath\oscdimg.exe" -u2 -udfver102 -m -o -h -w4 $BootData $ISOSource $isotarget   | Out-String | write-verbose

& icacls.exe $ISOTarget /grant Everyone:F    | Out-String | write-verbose
start-sleep 1

#endregion

#region Restart VM
##############################################

Start-VM $VMName -ErrorAction SilentlyContinue

#endregion

