
<#
.SYNOPSIS
In-Box App Remover

.DESCRIPTION
Removes in box Store/Modern/Metro applications from Windows 8.1

.NOTES

Microsoft Deployment Toolkit Extensions http://MDTEx.codeplex.com
Copyright Keith Garner, all rights reserved.

#>


<#     
    ************************************************************************************************************ 
    Purpose:    Remove built in apps specified in list 
    Pre-Reqs:    Windows 8.1 
    ************************************************************************************************************ 
 #>

[CmdletBinding()]
param(
    [switch] $FullRemoval = $False
)


# List of Applications that will be removed

$AppsFluff = @(
	"Microsoft.BingFinance",
	"Microsoft.BingSports",
	"Microsoft.BingNews",
	"Microsoft.BingFoodAndDrink",
	"Microsoft.BingHealthAndFitness",
	"Microsoft.ZuneVideo",
	"Microsoft.XboxLIVEGames"
)

$AppsMisc = @(
	"Microsoft.BingMaps",
	"Microsoft.BingTravel",
	"Microsoft.BingWeather",
	"Microsoft.ZuneMusic"
)

$AppsWork = @(
	"microsoft.windowscommunicationsapps",
	"Microsoft.Media.PlayReadyClient.2",
	"Microsoft.HelpAndTips",
	"Microsoft.WindowsReadingList",
	"Microsoft.WindowsAlarms",
	"Microsoft.Reader",
	"Microsoft.WindowsCalculator",
	"Microsoft.WindowsScan",
	"Microsoft.WindowsSoundRecorder",
	"Microsoft.SkypeApp",
	"Microsoft.Office.OneNote"
	)

if ( $FullRemoval ) { $AppList = $AppsFluff + $AppsMisc + $AppsWork } else { $AppList = $AppsFluff }

ForEach ($App in $AppList ) {
	write-verbose "Remove: $App"
	#$AppxPackage = Get-AppxProvisionedPackage -online | Where {$_.DisplayName -eq $App}
	#Remove-AppxProvisionedPackage -online -packagename ($AppxPackage.PackageName)
	#Remove-AppxPackage ($AppxPackage.PackageName)
}

