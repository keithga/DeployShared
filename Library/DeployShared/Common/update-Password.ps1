<#
Update the password in a CLIXML file.
#>

function Update-Password {
    [cmdletbinding()]
    PARAM(
        [parameter(Mandatory=$true)]
        $path,
        [parameter(Mandatory=$true)]
        $Password
    )

    $hash = Import-Clixml -Path $path
    $hash | out-string | Write-Verbose
    Parse-HashTable -Hash $hash -password $Password
    move -Path $path -Destination ( $path + ".old" ) -Force
    $hash | Export-Clixml -Path $Path
}
