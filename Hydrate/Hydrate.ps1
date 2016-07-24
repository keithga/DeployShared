
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

[cmdletbinding()]
param(
    [string] $ScriptVars = "$PSScriptRoot\test\ScriptBlock.xml",
    [switch] $test,
    [switch] $Run,
    [switch] $asJob
)

$ErrorActionPreference = 'stop'




#region Something
##############################################################################


#endregion

Write-Verbose "Hydrated!"