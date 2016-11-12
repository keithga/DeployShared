
<#

.SYNOPSIS 
Hydration Script Module - Patches

.DESCRIPTION
Hydration Environment for MDTEx Powershell Common Modules
PrivateProfile tools (INI files)

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>

[CmdletBinding()]
param(
    [string] $CSVPatches,
    [string] $Cache,
    [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share.")]
    [string] $DeploymentLocalPath, # Example: c:\DeploymentShare
    [string] $DPDrive = "DS001",
    [parameter(ValueFromRemainingArguments=$true)] $Remaining
)

#region Prepare MDT environment 
##########################################################################
Write-Verbose "import-Patches"

if ( -not ( Test-Path "$($DPDrive)`:")) 
{
    new-PSDrive -Name $DPDrive -PSProvider "MDTProvider" -Root $DeploymentLocalPath -Description "MDT Share" -scope script | out-string |write-verbose
}

new-item -ItemType directory -path $DeploymentLocalPath\TMP_cache -force -ErrorAction SilentlyContinue | out-null

$SwitchName = Get-VMSwitch -SwitchType External | Select-Object -First 1 -ExpandProperty Name

#endregion

foreach ( $Patch in Import-Csv $CSVPatches )
{
    Write-Verbose "Adding Patch: $($Patch.Description)"

    $URI = $Patch.URL

    if ( $Cache )
    {
        $PackagePath = "$Cache\Updates\$($Patch.ID)"
    }
    else
    {
        $PackagePath = "$env:temp\Updates\$($Patch.ID)"
    }

    $LocalFile = join-path $PackagePath ( split-path -leaf $uri )
    New-Item -ItemType Directory $PackagePath -Force -ErrorAction SilentlyContinue

    if ( -not ( Test-Path $LocalFile ) )
    {
        Write-verbose "download FIle $uri to $LocalFile"
        (New-Object net.webclient).DownloadFile($uri,$LocalFile)
        # Invoke-WebRequest -Uri $uri -OutFile $LocalFile   #Too SLOW!
    }

    ##########################################################################

    $TargetPath = "$($DPDrive)`:\Packages\$($Patch.Profile)"

    if ( -not ( Test-Path $TargetPath ) ) 
    {
        Write-Verbose "create OS Directory: $TargetPath"
        new-item -ItemType Directory $TargetPath -Force | out-string | Write-Verbose
    }

    if ( $false ) # ( $Cache )
    {
        "Create a Mklink pointer " | Write-Verbose
        if (-not ( test-path "$DeploymentLocalPath\TMP_Cache\$($Patch.ID)\*" ))
        {
            write-verbose "mklink /J '$DeploymentLocalPath\TMP_Cache\$($Patch.ID)' '$Cache\$($Patch.ID)'"
            & cmd.exe /c mklink /J "$DeploymentLocalPath\TMP_Cache\$($Patch.ID)" "$Cache\$($Patch.ID)"
        }
    }

    Import-MDTPackage -path $TargetPath -SourcePath $PackagePath  | Out-String | write-verbose

    if ( -not ( test-path "$($DPDrive)`:\Selection Profiles\Package_$($Patch.Profile)" ) ) 
    {
        new-item -path "$($DPDrive)`:\Selection Profiles" -Name "Package_$($Patch.Profile)" -ReadOnly $False -Definition "<SelectionProfile><Include path=""Packages\$($Patch.Profile)"" /></SelectionProfile>"
    }

}

get-childitem -path $DeploymentLocalPath\TMP_cache -recurse -Attributes ReparsePoint | %{ $_.Delete() }

remove-item -path $DeploymentLocalPath\TMP_cache -force -ErrorAction SilentlyContinue -Confirm:$False

Write-Verbose "Done OS import!"
