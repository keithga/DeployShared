
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
    [switch] $Quiet,

    [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share.")]
    [string] $DeploymentLocalPath, # Example: c:\DeploymentShare

    [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share from network.")]
    [string] $DeploymentNetShare, #Example: DeploymentShare$

    [string] $DPDrive = "DS001",

    [parameter(ValueFromRemainingArguments=$true)] $Remaining
)

"Create Test Build" | Write-Verbose

###############################################################################

@"
[Settings]
Priority=Default

[Default]
DeployRoot=\\$env:ComputerName\$DeploymentNetShare
UserDomain=$env:ComputerName
"@ | Set-Content -Path "$DeploymentLocalPath\Control\Bootstrap.ini"

if ( -not ( Test-Path "$($DPDrive)`:")) 
{
    new-PSDrive -Name $DPDrive -PSProvider "MDTProvider" -Root $DeploymentLocalPath -Description "MDT Share" -scope script
}

update-MDTDeploymentShare -path "$($DPDrive)`:"

