
<#

.SYNOPSIS 
Hydration Script Module - Main Build Scripts

.DESCRIPTION
Hydration Environment for MDTEx Powershell Common Modules
Build environment

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>

[cmdletbinding()]
param(
)

$ModuleCommon = @{
    Author = "Keith Garner (KeithGa@DeploymentLive.com)"
    CompanyName  = "https://github.com/keithga/DeployShared" 
    Copyright = "Copyright Keith Garner (KeithGa@DeploymentLive.com), all Rights Reserved."
    ModuleVersion = "1.0.0032.0"
    PowershellVersion = "2.0"
    Description = "DeployShared Powershell Library"
    GUID = [GUID]::NewGUID()
}

Foreach ( $libPath in get-childitem -path $PSscriptRoot -Directory )
{
    Write-Verbose "if not exist $($libPath.FullName)\*.psm1, then create"

    $FileList = get-childitem -path $libPath.FullName *.ps1 -recurse | where-object name -notmatch 'tests.ps1' | %{ (split-path -leaf (split-path $_.fullname )) + "\" + ( split-path -leaf $_ )}

    $ModuleName = "$($LibPath.FullName)\$($LibPath.Name).psm1"

@"

<#
.SYNOPSIS 
WPF4PS PowerShell Library

.DESCRIPTION
Windows Presentation Framework for PowerShell Module Library

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>

[CmdletBinding()]
param(
    [parameter(Position=0,Mandatory=`$false)]
    [Switch] `$Verbose = `$false
)

if (`$Verbose) { `$VerbosePreference = 'Continue' }

. `$PSScriptRoot\$($FileList -join "`r`n. `$PSScriptRoot\")

Export-ModuleMember -Function * 

"@ | Out-File -Encoding ascii -FilePath $ModuleName


    $ManifestName = "$($LibPath.FullName)\$($LibPath.Name).psd1"
    New-ModuleManifest @Modulecommon -path $ManifestName -ModuleToProcess (split-path -leaf $ModuleName) -FileList $FileList -ModuleList $FileList

}

