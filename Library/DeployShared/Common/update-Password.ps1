<#
Update the password in a CLIXML file.
#>

function Parse-HashTable {
    param( 
        [HashTable] $Hash,
        [string] $password
    )

    $MyKeys = $Hash.Keys -as [string[]]
    foreach ( $Key in $MyKeys ) {
        write-verbose "Looking at $($hash[$key])"
        if ( $Hash[$key].gettype().Name -eq 'Hashtable' ) {
            Parse-HashTable -hash $Hash[$Key] -password $Password
        }
        elseif ( $Hash[$key].gettype().Name -eq 'PSCredential' ) {
            $newPassword = ConvertTo-SecureString -force -AsPlainText $password
            $hash[$key] = New-Object System.Management.Automation.PSCredential ($hash[$key].UserName, $NewPassword)
        }
        elseif ( $Hash[$key].gettype().Name -eq 'SecureString' ) {
            $hash[$key] = ConvertTo-SecureString -Force -AsPlainText $password
        }
    }
}

Update-Password {
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
