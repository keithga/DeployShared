
#Requires -Version 3
#Requires -RunAsAdministrator

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
    [HashTable] $ConfigBlock
)

$ErrorActionPreference = 'stop'




#region Something
##############################################################################

Write-Host "DOne!"

#endregion

Write-Verbose "Hydrated!"