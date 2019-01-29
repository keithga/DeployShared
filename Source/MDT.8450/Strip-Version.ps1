
param (
	$Version = "6.3.8450.1000"
)

new-item -type directory $PSScriptRoot\scripts.1 -force | Out-Null

foreach ( $file in get-childitem $PSScriptRoot\scripts\* ) 
{
	type -raw $PSScriptRoot\scripts\$($File.Name) | %{ $_.replace( $Version ,"<VERSION>")} | set-content -path $PSScriptRoot\scripts.1\$($File.name) -Encoding ascii
}