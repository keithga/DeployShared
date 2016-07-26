
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
    [string] $UserName = "MDTUser",
    [parameter(ValueFromRemainingArguments=$true)] $Remaining
)

<#

Create a local account on this computer that has *NO* user permissions, and a random password. Used by automated MDT scripts.

#>

if ( -not (get-wmiobject -class win32_useraccount -filter "Name='MDTUser'" ))
{
    Write-Verbose "Create Local TEst Account(s) [$UserName]"
    $Password = New-UserPassword -Length 14
    net.exe user /add MDTUser /Active:Yes /Expires:Never $Password | out-string | write-verbose
    net.exe localgroup users /del MDTUser | out-string | write-verbose
    Get-WmiObject -Class Win32_UserAccount -Filter "name='MDTUser'"  | Set-WmiInstance -Argument @{PasswordExpires = 0}  | out-string | write-verbose
}

