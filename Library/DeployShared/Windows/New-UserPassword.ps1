
<#

.SYNOPSIS 
New USer Password

.DESCRIPTION
Hydration Environment for MDTEx Powershell Common Modules
Common Utilities

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared


#>


function New-UserPassword( [ValidateRange(3,14)] [uint32] $Length = 8 )
{
    # Ensure password meets complexity requirements http://technet.microsoft.com/en-us/library/hh994562(v=ws.10).aspx
    [Reflection.Assembly]::LoadWithPartialName("System.Web") | out-null
    do
    {
        $Pass = [System.Web.Security.Membership]::GeneratePassword($Length,2)
        $Complexity = 0
        if ( $Pass -cmatch "\d") {$Complexity++}
        if ( $Pass -cmatch "\W") {$Complexity++}
        if ( $Pass -cmatch "[A-Z]") {$Complexity++}
        if ( $Pass -cmatch "[a-z]") {$Complexity++}
    }
    while ( $Complexity -lt 3 )
    $Pass | Write-Output
}
