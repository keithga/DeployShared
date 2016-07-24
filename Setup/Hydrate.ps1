
<#

.SYNOPSIS 
Hydration Script Module - Main Wizard Entry Point

.DESCRIPTION
Hydration Environment for MDTEx Powershell Common Modules
Logging Support

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>

[CmdletBinding()]
param()

$Host.UI.RawUI.WindowTitle = "Working"

$ScriptDir = split-path ( Split-Path ([PowerShell_Wizard_Host.PSHostCallBack]::GetHostExe) )

if ( $ScriptDir ) 
{
    write-host "Calling $ScriptDir\Hydrate\Hydrate.ps1 ..."

    & "$ScriptDir\Hydrate\Hydrate.ps1"

    ##############################################
    cls
    $Host.UI.RawUI.WindowTitle = "Finished"
    [PowerShell_Wizard_Host.PSHostCallBack]::DisplayHyperLink("CodePlex Documentation XXX TBD","https://github.com/keithga/DeployShared","")

}
else 
{
    Write-Host "ScriptDir Missing!"
}


Write-Host "`n`n`nPress Any Key to Continue"
$host.ui.RawUI.ReadKey() | out-null
