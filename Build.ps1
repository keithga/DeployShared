
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
    [string] $ScriptVars = "$PSScriptRoot\test\ScriptBlock.xml",
    [switch] $test,
    [switch] $Run,
    [switch] $asJob
)

$ErrorActionPreference = 'stop'

#region Clean
##############################################################################
Write-Verbose "Clean"

Remove-Item -Recurse -Force $PSScriptRoot\Bin -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $PSScriptRoot\library -Include *.psm1,*.psd1 -ErrorAction SilentlyContinue

#endregion

#region Rebuild Powershell Module Libararies
##############################################################################
Write-Verbose "Rebuild Powershell Module Libararies"

$ModuleCommon = @{
    Author = "Keith Garner (KeithGa@DeploymentLive.com)"
    CompanyName  = "https://github.com/keithga/DeployShared" 
    Copyright = "Copyright Keith Garner (KeithGa@DeploymentLive.com), all Rights Reserved."
    ModuleVersion = "1.0.0030.0"
    PowershellVersion = "2.0"
    Description = "DeployShared Powershell Library"
    GUID = [GUID]::NewGUID()
}

Foreach ( $libPath in get-childitem -path $PSscriptRoot\Library -Directory )
{
    Write-Verbose "if not exist $($libPath.FullName)\*.psm1, then create"

    $FileList = get-childitem -path $libPath.FullName *.ps1 -recurse | %{ (split-path -leaf (split-path $_.fullname )) + "\" + ( split-path -leaf $_ )}
    $ModuleName = Get-ChildItem "$($libPath.FullName)\*.psm1" | Select-Object -ExpandProperty Name -First 1
    $ManifestName = Get-ChildItem "$($libPath.FullName)\*.psd1" | Select-Object -ExpandProperty Name -First 1

    if ( -not $ModuleName ) 
    {
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

. `$PSScriptROot\$($FileList -join "`n. `$PSScriptRoot\")

Export-ModuleMember -Function * 

"@ | Out-File -Encoding ascii -FilePath $ModuleName

    }

    if ( -not $ManifestName ) 
    {
        $ManifestName = "$($LibPath.FullName)\$($LibPath.Name).psd1"
        New-ModuleManifest @Modulecommon -path $ManifestName -ModuleToProcess (split-path -leaf $ModuleName) -FileList $FileList -ModuleList $FileList
    }

}

#endregion 


exit



#region Create Wizard
##############################################################################
Write-Verbose "Create Wizard"

if ( -not ( Test-Path $PSScriptROot\..\..\PS2Wiz\PS2Wiz.ps1 ) ) { throw "Missing PS2Wiz.ps1  http://ps2wiz.codeplex.com" }

New-Item -ItemType Directory -Force -Path $PSScriptRoot\Bin -ErrorAction SilentlyContinue | Out-Null

& "$PSScriptRoot\..\..\PS2Wiz\PS2Wiz.ps1" -verbose "$PSScriptRoot\setup\Hydrate.ps1" -OutputFolder "$PSScriptRoot\bin" -Admin
& "$PSScriptRoot\..\..\PS2Wiz\PS2Wiz.ps1" -verbose "$PSScriptRoot\setup\Hydrate.ps1" -Target Clean

#endregion

#region CRC Check of files
##############################################################################
Write-Verbose "Get a list of hashes for MDT scripts that are being replaced in by DeployShared"

Get-ChildItem "$PSScriptRoot\Source\MDT2013U2\scripts\*" | 
    Where-Object { Test-Path "$PSScriptRoot\Templates\Distribution\Scripts\$($_.Name)" } |
    Get-FileHash | 
    ForEach-Object { [PSCustomObject] @{ Hash = $_.Hash; Name = (split-path -leaf $_.Path) } } |
    Export-Clixml -path $PSscriptRoot\Hydrate\ShareOperations\DeploySharedCRC.xml

#endregion

#region Create MSI Package
##############################################################################
Write-Verbose "Create MSI Package"

if ( -not ( test-path env:wix ) ) { throw "missing WIX" }

New-Item -ItemType Directory -Force -Path  "$PSScriptRoot\setup\DeployShared\obj" -ErrorAction SilentlyContinue | Out-Null

& "$env:WIX\bin\heat.exe" dir "$PSScriptRoot\Templates"  -var var.TemplatesDir -dr INSTALLFOLDER -cg TemplatesComponents -nologo -ag -scom -sreg -sfrag –srd -o "$PSScriptRoot\setup\DeployShared\obj\Templates.wxs"
& "$env:WIX\bin\heat.exe" dir "$PSScriptRoot\Library"  -var var.LibraryDir -dr INSTALLFOLDER -cg LibarayComponents -nologo -ag -scom -sreg -sfrag –srd -o "$PSScriptRoot\Setup\DeployShared\obj\Library.wxs"
& "$env:WIX\bin\heat.exe" dir "$PSScriptRoot\Hydrate"  -var var.HydrateDir -dr INSTALLFOLDER -cg HydrateComponents -nologo -ag -scom -sreg -sfrag –srd -o "$PSScriptRoot\Setup\DeployShared\obj\Hydrate.wxs"

$MSBuildPath = get-childitem HKLM:\Software\Microsoft\Msbuild\ToolsVersions | 
    Where-Object Property -eq 'MSBuildToolsPath' | 
    Get-ItemProperty -Name 'MsBuildToolsPath' | 
    Select-Object -ExpandProperty 'MSBuildToolsPath' | 
    Where-Object { test-path "$_\msbuild.exe" } | 
    Select-object -first 1

if ( -not $MSBuildPath ) { throw "Missing MSBuild" }

& $MSBuildPath\msbuild.exe /nologo /verbosity:quiet "$PSScriptRoot\Setup\DeployShared\DeployShared.wixproj"

#endregion

#region Run Test if present
##############################################################################

if ( $test -or $Run)
{

    $MSIPackage = get-childitem $PSScriptRoot\Bin\*.msi -recurse | 
        Select-Object -First 1

    if ( -not $MSIPackage ) { throw "Missing MSI Package Output" }

    $ScriptXML = Import-Clixml $ScriptVars
    $scriptXML | out-string | Write-Verbose

    Write-verbose "Copy Scripts to Host for testing  $PSScriptRoot\test\HostTest  $($ScriptXML.HostShare)"
    new-psdrive -Name TestTarget -PSProvider FileSystem -root $ScriptXML.HostShare -Credential $scriptxml.HostCredentials | out-string | Write-verbose
    copy-item $PSScriptRoot\test\HostTest\* "$($ScriptXML.HostShare)\Staging" -Recurse -Force | out-string | Write-verbose
    copy-item $MsiPackage "$($ScriptXML.HostShare)\Staging" -Force | out-string | Write-verbose

    write-verbose "Invoke-Command -ScriptBlock {$($ScriptXML.HostCommand)} "

    $RemoteParams = @{
        ComputerName = $ScriptXML.HostComputer
        Credential = $ScriptXML.HostCredentials
        AsJob = $AsJob.IsPresent
        ScriptBlock = [Scriptblock]::Create($scriptxml.HostCommand)
    }

    if ( $run )
    {
        ">"*80 + ">"*80 + "`nbegin remote command`n" + ">"*80 + ">"*80 | Write-Verbose
        $RemoteParams | out-string | Write-verbose
        Invoke-Command @RemoteParams
    }

}

#endregion

Write-Verbose "Built!"
