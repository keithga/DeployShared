
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

#region PreReq Check
##############################################################################

if ( -not ( Test-Path "$env:programfiles\7-zip\7z.exe" ) )
{
    msiexec /qb- /i http://sourceforge.net/projects/sevenzip/files/7-Zip/9.22/7z922-x64.msi
}

if ( -not ( Test-Path "$env:programfiles\Microsoft Deployment Toolkit\Bin\Microsoft.BDD.Core.dll" ) )
{
    msiexec /qb- /i https://download.microsoft.com/download/3/0/1/3012B93D-C445-44A9-8BFB-F28EB937B060/MicrosoftDeploymentToolkit2013_x64.msi
}
elseif (  (get-item "$env:programFiles\Microsoft Deployment Toolkit\Bin\Microsoft.BDD.PSSnapIn.dll").VersionInfo.FileVersion -ne "6.3.8330.1000" )
{
    msiexec /qb- /i https://download.microsoft.com/download/3/0/1/3012B93D-C445-44A9-8BFB-F28EB937B060/MicrosoftDeploymentToolkit2013_x64.msi
}

# ConfigMgr SDK would also be nice: https://download.microsoft.com/download/5/0/8/508918E1-3627-4383-B7D8-AA07B3490D21/ConfigMgrTools.msi
# We also require ADK. http://download.microsoft.com/download/0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk/adksetup.exe

#endregion

#region Environment Check
##############################################################################

if ( -not [environment]::Is64BitOperatingSystem )
{
	write-Warning "Must be running on a 64-bit Operating System"
}

#endregion

#region Load MDT powershell modules 
##############################################################################

remove-module MDT,WIndows,MicrosoftDeploymentToolkit -force -ErrorAction SilentlyContinue

Import-Module "$env:ProgramFiles\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
Import-Module "$PSScriptRoot\..\Library\MDT"
Import-Module "$PSScriptRoot\..\Library\Windows" 

#endregion

#region Create the MDT Deployment Share
##############################################################################

Write-Verbose "!!!!!!!!!!New MDTDeploymentShare"
New-MDTDeploymentShare @ConfigBlock

Copy-Item "$PSScriptRoot\..\templates\*.xml" "$env:ProgramFiles\Microsoft Deployment Toolkit\templates" -Force 

#endregion

#region Run CLient SCripts
##############################################################################

function Resolve-Error ($ErrorRecord=$Error[0])
{
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {
       "$i" * 10
       $Exception |Format-List * -Force
   }
}


if ( $ConfigBlock.contains("HydrationScripts") )
{
    $HydrationScripts = $ConfigBlock.HydrationScripts
}
else
{
    "Enumerate through all *.MDTEx.PS1 scripts." | Write-verbose

    $HydrationScripts  = @()
    $HydrationScripts += get-childitem -recurse -path $PSScriptRoot\ShareOperations -Include "*.mdt.ps1" -Exclude "*.Optional.mdt.ps1"
    $HydrationScripts += get-childitem -recurse -path $PSScriptRoot\ShareOperations -Include "*.Optional.mdt.ps1" | Out-GridView -OutputMode Multiple
}

">>>>>>>>>>> Start Hydration" |Write-verbose

foreach ( $FileItem in $HydrationScripts )
{
    ">"*80 + "`r`n>    Run Command $($FileItem.FullName)`r`n" + ">"*80 | Write-verbose
    try
    {
        & $($FileItem.FullName) @ConfigBlock
    }
    catch
    {
         Resolve-Error | out-string | Write-Error
        $_.Exception | Write-Warning
        break
    }
}

">>>>>>>>>>> Finished Hydration" |Write-verbose

#endregion


#region Run CLient SCripts
##############################################################################

write-verbose "Continue with installation"

if ( test-path $ConfigBlock.CSVPackage ) 
{
    $vmList = import-csv E:\Staging\OSandTS.csv | where-object HyperV -eq TRUE | select-object -ExpandProperty TSID

    write-verbose "Start all Hyper-V Machines"
    Start-VM -Name $VMList
    while ( Get-VM -Name $VMList | where-object State -eq 'Off' )
    {
        Write-Verbose 'Not All machines are stopped: $(Get-Date)'
        Start-Sleep -Seconds 60
    }

    # Post Build cleanup
}

#endregion

Write-Verbose "Hydrated!"

