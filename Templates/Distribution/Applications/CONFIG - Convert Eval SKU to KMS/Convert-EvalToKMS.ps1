<#
 .SYNOPSIS
Convert Windows Eval SKU to KMS.

.DESCRIPTION
Idea Stolen from Deployment Bunny.
http://deploymentbunny.com/2013/10/17/nice-to-know-how-to-change-from-evaluation-to-the-real-stuff-in-windows-server-2012-r2/

Assumes that you have a KMS server. 

.NOTES
Copyright Keith Garner, All rights reserved. 
#>

foreach ( $Product in gwmi SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f'" )
{
	If ( $Product.PartialProductKey -is [string] )
	{
		Write-Host "Found License: $($Product.LicenseFamily)"
		$NewSKU = $Product.LicenseFamily.Replace("Eval","")
		switch -wildcard ($Product.LicenseFamily)
		{
			"ENTERPRISEEVAL"
			{
				write-Host "Found $NewSKU SKU, ready to configure for KMS"
				dism /online /set-edition:$NewSKU /productkey:MHF9N-XY6XB-WVXMC-BTDCT-MKKG7 /accepteula /NoRestart |out-null
                break
			}
			"SERVERSTANDARDEVAL*"
			{
				write-Host "Found $NewSKU SKU, ready to configure for KMS"
				dism /online /set-edition:$NewSKU /productkey:D2N9P-3P6X9-2R39C-7RTCD-MDVJX /accepteula /NoRestart |out-null
                break
			}
			"SERVERDATACENTEREVAL*"
			{
				write-Host "Found $NewSKU SKU, ready to configure for KMS"
				dism /online /set-edition:$NewSKU /productkey:W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9 /accepteula /NoRestart |out-null
                break
			}
			default
			{
				write-Error "Not a Recognized Eval SKU: $NewSKU"
			}
		}
	}
}

exit
