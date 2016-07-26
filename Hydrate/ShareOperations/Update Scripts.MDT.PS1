
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
    [switch] $quiet,

    [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share.")]
    [string] $DeploymentLocalPath, # Example: c:\DeploymentShare

    [parameter(ValueFromRemainingArguments=$true)] $Remaining
)

###############################################################################

$CRCList = import-clixml "$PSScriptRoot\DeploySharedCRC.xml"

if ( -not $quiet )
{
    write-host @"
    If you have any existing MDT Deployment Shares, you can update the existing 
    MDT scripts to the latest versions from this MDT Extensions
    Select any drive(s) below:
"@ 

    $DrivesToUpgrade = get-MDTPersistentDrive |out-gridview -OutputMode Multiple

    Write-Host @"
    You will be asked to *CONFIRM* to replace each script that is not an MDT 2013 Original Script.
"@

}
else
{
    $DrivesToUpgrade = @{ path = $DeploymentLocalPath }
}

foreach ( $MDT in $DrivesToUpgrade )
{
    $BadList = @()
    foreach ( $Script in get-childitem (Join-path $MDT.path "Scripts") )
    {
        if ( $CRCList.Contains( $Script.Name ) ) 
        {
            $Confirm = (Get-FileHash $Script.FullName).Hash -ne $CRCList.Item( $SCript.Name ) -and ( -not $quiet )
            $Src = (join-path (split-path -parent "$PSScriptRoot\..\..\Templates\Distribution\Scripts\ZTIUtility.vbs") $Script.Name)
            write-verbose "Copy-item $src to $($MDT.Path)\scripts\$($Script.Name)  Confirm: $Confirm"
            copy-item -path $src -destination "$($MDT.Path)\scripts\$($Script.Name)" -force -confirm:$Confirm
        }
    }

}

