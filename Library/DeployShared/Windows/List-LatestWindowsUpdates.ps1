
function List-LatestWindowsUpdates {
    <#
    .SYNOPSIS
    Get the latest Cumilitave update for Windows

    .DESCRIPTION
    This script will return a list of updates based on a search string

    .PARAMETER OSBuild
    The build number to search against. Default 15063.
    This argument is used to filter against Micorosoft document KB4000816.

    .PARAMETER SearchString
    This search filter against avaiable builds on Windows Update Catalog.
    The parameter is a Regular Expression search of the Descriptoin.

    .NOTES
    Copyright Keith Garner, All rights reserved.

    .LINKS
    https://support.microsoft.com/en-us/help/4000823

    .EXAMPLE

    Get the latest Windows 10 Cumulitave Update x64 (this is the default)

    .\get-latestUpdate.ps1 

    .EXAMPLE

    Get the latest Windows 10 Cumulitave Update x86

    .\get-latestUpdate.ps1 -SearchString 'Cumulative.*x86'

    .EXAMPLE

    Get the latest Windows Server 2016 Cumulitave Update x64 

    .\get-latestUpdate.ps1 -SearchString 'Cumulative.*Server.*x64' -OSBuild 14393


    #>

    [cmdletbinding()]
    param(
        [string] $StartKB = 'https://support.microsoft.com/api/content/asset/4000816',
        [ValidateSet('15063','14393','10586','10240')]
        [string] $OSBuild = '15063',
        [string] $SearchString = 'Cumulative.*x64'
    )

    #region Support Routine

    function Find-LatestUpdate {
        [CmdletBinding(SupportsShouldProcess=$True)]
        param(
            [parameter(Mandatory=$true, 
            ValueFromPipeline=$true)]
            $Updates
        )
        Begin { 
            $MaxObject = $null
            $MaxValue = [version]::new("0.0")
        }
        Process {
            foreach ( $Update in $updates ) {
                Select-String -InputObject $Update -AllMatches -Pattern "(\d+\.)?(\d+\.)?(\d+\.)?(\*|\d+)" |
                ForEach-Object { $_.matches.value } |
                ForEach-Object { $_ -as [version] } |
                ForEach-Object { 
                    if ( $_ -gt $MaxValue ) { $MaxObject = $Update; $MaxValue = $_ }
                }
            }
        }
        End { 
            $MaxObject | Write-Output 
        }
    }

    #endregion

    #region Find the KB Article Number

    write-verbose "download $StartKB and get a list of Updates"
    $KBID = iwr $StartKB |
        Select-Object -ExpandProperty Content |
        ConvertFrom-Json |
        Select-Object -ExpandProperty Links |
        Where-Object level -eq 2 |
        where-object text -match $OSBuild |
        Find-LatestUpdate |
        Select-Object -First 1

    #endregion

    #region get the download link from Windows Update

    write-verbose "Found KBID: http://www.catalog.update.microsoft.com/Search.aspx?q=KB$($KBID.articleID)"
    $KBObj = iwr "http://www.catalog.update.microsoft.com/Search.aspx?q=KB$($KBID.articleID)" 

    $Available_KBIDs = $KBObj.InputFields | 
        where-object { $_.type -eq 'Button' -and $_.Value -eq 'Download' } | 
        Select-Object -ExpandProperty  ID

    $Available_KBIDs | out-string | write-verbose

    $KBIDs = $KBObj.Links | 
        where-object ID -match '_link' |
        Where-Object InnerText -match $SearchString |
        ForEach-Object { $_.id.replace('_link','') } |
        Where-Object { $_ -in $Available_KBIDs }

    foreach ( $KBID in $KBIDs )
    {
        Write-Verbose "`t`tDownload $KBID"
        $Post = @{ size = 0; updateID = $KBID; uidInfo = $KBID } | ConvertTo-Json -Compress
        $PostBody = @{ updateIDs = "[$Post]" } 
        Invoke-WebRequest -Uri 'http://www.catalog.update.microsoft.com/DownloadDialog.aspx'  -Method Post -Body $postBody |
            Select-Object -ExpandProperty Content |
            select-string -AllMatches -Pattern "(http[s]?\://download\.windowsupdate\.com\/[^\'\""]*)" | 
            ForEach-Object { $_.matches.value }
    }

    #endregion

}