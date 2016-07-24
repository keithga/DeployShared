#Requires -Version 3
#Requires -RunAsAdministrator

<#
.SYNOPSIS 
Hydration Script for test machine

.DESCRIPTION
Hydration Environment for MDT

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared
#>

[CmdletBinding()]
param(
    [string] $ScriptVars = "$PSScriptRoot\ScriptBlock.xml"
)

$ErrorActionPreference = 'stop'

#region Start Environment
##############################################################################

$MDTExPath = "${env:programfiles(x86)}\DeployShared"

$ScriptXML = Import-Clixml $ScriptVars
$scriptXML | out-string | Write-Verbose

#endregion

#region Cleanup
##############################################################################

if (gwmi win32_share -filter "name='$($scriptXML.DeploymentNetShare)'")
{
    write-verbose "Remove Deployment share to ensure no open files "
    'Y' | net.exe share /Del $scriptXML.DeploymentNetShare| out-string |Write-Verbose
}

if ( test-path $scriptXML.DeploymentLocalPath )
{
    "remove all Junction points from DeploymentShare" | Write-Verbose
    get-childitem -path $scriptXML.DeploymentLocalPath -recurse -Attributes ReparsePoint | %{ $_.Delete() }
    "Remove local Deployment Directory" |Write-Verbose
    Remove-Item -Recurse -Force $scriptXML.DeploymentLocalPath
}

if ( Test-Path $MDTExPath ) {Remove-Item -Recurse -Force $MDTExPath }

##
##  TBD: Remove Running Virutal Machines...
##

#endregion

#region Install The MSI package
##############################################################################

$ExistingMDTEx = gwmi win32_product -filter "Name = 'DeployShared'"
if ( $ExistingMDTEx )
{
    "remove MSIPackage: $($ExistingMDTEx.IdentifyingNumber)" | Write-Verbose
    & msiexec.exe /qb /x $($ExistingMDTEx.IdentifyingNumber) | out-null
}

Remove-Item $PSScriptRoot\MDTEX_MSI.log -Force -ErrorAction SilentlyContinue | out-null
"install MSI Package: $PSScriptRoot\DeployShared.msi" | write-verbose
& msiexec.exe /qb- /i $PSScriptRoot\DeployShared.msi /l*v $PSScriptRoot\MDTEX_MSI.log | out-null

#endregion

#region Hydrate
##############################################################################

$scriptXML.HydrationScripts = get-childitem -recurse -path $MDTExPath\hydrate -Include "*.mdt.ps1" 
& $MDTExPath\hydrate\Hydrate.ps1 -ConfigBlock $scriptXML

#endregion


<#

if ( Test-Path "$($scriptxml.DeploymentLocalPath)\Control\*.cre")
{
    $VMList = get-childitem -path "$($scriptxml.DeploymentLocalPath)\Control\*.cre" -directory | %{ $_.Name.Replace(".CRE","") } | get-vm -erroraction SilentlyContinue | ?{ $_.State -ne 'Off' }
    $vmList | stop-VM -Force -TurnOff
    if ($VMList) { Start-Sleep 10 }
}

#>
