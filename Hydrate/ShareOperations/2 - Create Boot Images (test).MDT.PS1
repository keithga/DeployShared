
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

"Create Test Build" | write-Verbose

###############################################################################

"Change Password" | write-Verbose
$Password = New-UserPassword -length 14

Net.exe user MDTUser $Password  | out-string | write-verbose

@"
[Settings]
Priority=Default

[Default]
DeployRoot=\\$env:ComputerName\$DeploymentNetShare
SkipBDDWelcome=YES
UserID=MDTUser
UserDomain=$env:ComputerName
UserPassword=$Password
Role001=AutoBuildout
"@ | Set-Content -Path "$DeploymentLocalPath\Control\Bootstrap.ini"

if ( -not ( Test-Path "$($DPDrive)`:")) 
{
    new-PSDrive -Name $DPDrive -PSProvider "MDTProvider" -Root $DeploymentLocalPath -Description "MDT Share" -scope script
}

Write-Verbose " disable x64 for speed"

set-itemproperty -path "$($DPDrive)`:" -name SupportX64 -Value "False"
set-itemproperty -path "$($DPDrive)`:" -name "Boot.x86.LiteTouchISOName" -Value "LitetouchPE_Automated_x86.iso"

update-MDTDeploymentShare -path "$($DPDrive)`:"

write-verbose "restore settings! "

set-itemproperty -path "$($DPDrive)`:" -name SupportX64 -Value "True"
set-itemproperty -path "$($DPDrive)`:" -name "Boot.x86.LiteTouchISOName" -Value "LitetouchPE_x86.iso"