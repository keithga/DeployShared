
<#

.SYNOPSIS 
get Shell Folder Path

.DESCRIPTION
Hydration Environment for MDTEx Powershell Common Modules
Common Utilities

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>


Function Get-SHGetFolderPath( $GUID )
{
    write-verbose "Get the $GUID directory..."
    $sig = @’ 
    [DllImport("shell32.dll")]
    public static extern int SHGetFolderPath(
        IntPtr   hwndOwner, 
        int      nFolder, IntPtr   hToken,
        int      dwFlags, StringBuilder lpszPath);
‘@
    $type = Add-Type -MemberDefinition $sig -Name getfolderpath -Namespace Pinvoke -Using System.Text -PassThru 
    $builder = New-Object System.Text.StringBuilder 1024 
    $returncode=$type::SHGetFolderPath([IntPtr]::Zero,$GUID,[IntPtr]::Zero,  0, $builder)
    write-verbose "Return code is: $returncode"
    return $builder.ToString()
}


