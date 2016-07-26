
<#
.SYNOPSIS 
Hydration Script for MDTEx

.DESCRIPTION
_TEMPLATE_

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>

[CmdletBinding()]
param(
    [parameter(mandatory=$true,HelpMessage="Hash Table of CS.ini values.")]
    $CSSettings,
    [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share.")]
    [string] $DeploymentLocalPath, # Example: c:\DeploymentShare

    [parameter(ValueFromRemainingArguments=$true)] $Remaining
)

"cs.ini" | Write-Verbose

foreach ( $setting in $CSSettings.Keys ) 
{
    Set-MDTCustomSettings -DPShare $DeploymentLocalPath -Category "Default" -Key $Setting -Value $CSSettings[$Setting]
}

