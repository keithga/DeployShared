
[cmdletbinding()]
param(
    
    [parameter(mandatory=$true,HelpMessage="DeploymentShare")]
    $DeploymentShare
)

foreach ( $LogPath in get-childitem -verbose -recurse -path $DeploymentShare\Captures\ZTIAppVerify.log | Select-Object -ExpandProperty FullName)
{
    $TargetDir = join-path "$DeploymentShare\Captures\Updates" (split-path -leaf ( split-path ( split-path $LogPath ) ))

    if ( -not ( Test-Path $TargetDir ) ) 
    {
        New-item -ItemType Directory $TargetDir -Force | out-string | Write-verbose
    }

    get-content $LogPath | 
        where-object { $_ -match "WU\(([0-9]{3})\).*(http://.*/content[^\t]*)/([^\t/]*)" } | 
        where-object { -not $Matches[3].ToUpper().EndsWith('.EXE') } | 
        where-object { -not ( test-path "$TargetDir\$($matches[1])-$($matches[3])" ) } | 
        ForEach-Object { 
            [pscustomobject] @{ 
                Source = "$($matches[2])/$($matches[3])"
                Destination = "$TargetDir\$($matches[1])-$($matches[3])" 
            }        
        } | Start-BitsTransfer

}

