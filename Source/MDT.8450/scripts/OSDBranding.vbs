'////////////////////////////////////////////////////////////////////////
' OSD Deploy Tool Branding Script
'////////////////////////////////////////////////////////////////////////
' Brand OSD variables to registry
'////////////////////////////////////////////////////////////////////////
' V2.00 6.11.2009 MICHS
'////////////////////////////////////////////////////////////////////////
' Include/Exclude
'////////////////////////////////////////////////////////////////////////
' 1. Include or exclude variables "starting with"
' 2. Use semicolon to separate multiple values
' 3. Exclude takes precedence over includes
'////////////////////////////////////////////////////////////////////////
Option Explicit

	'||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	' Constants
	'||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	Const	REG32			= "%windir%\System32\reg.exe"
	Const	REG64			= "%windir%\Sysnative\reg.exe"
	Const	REGBRANDPATH	= "HKLM\Software\Microsoft\MPSD\OSD"

    'Const	includeMap		= "OSD;_SMSTSClientGUID;_SMSTSClientIdentity;USMT_;APPLICATIONs;PACKAGES"
    Const   tsAppVariableName      = "TsApplicationBaseVariable"
    Const   tsWindowsAppPackageAppVariableName = "TsWindowsAppPackageAppBaseVariable"
    Const   tsAppInstall           = "TsAppInstall"
    Const	includeMap		= "OSD;_SMSTSClientGUID;_SMSTSClientIdentity;USMT_;TSType;TSVersion;OldComputerName;PACKAGES;OSDBaseVariableName;DeploymentType"
	Const	excludeMap		= "OSDJoinPassword;_SMSTSReserved;OSDLocalAdminPassword"

	'||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	' Globals
	'||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	Dim REGBRAND
	Dim oWSH 				: SET oWSH = CreateObject("WScript.Shell")
	Dim oTSE				: SET oTSE = CreateObject("Microsoft.SMS.TSEnvironment")

	'[##############################################################################################################################]
	' MAIN
	'[##############################################################################################################################]

	'||||||||||||||||||||||||||||||||
	' Determine 32/64 Sysnative
	'||||||||||||||||||||||||||||||||
	Call LogArea("Environmental Setup")
	IF ( IsSysnative() = TRUE ) Then REGBRAND = REG64 Else REGBRAND = REG32

	'||||||||||||||||||||||||||||||||
	' Build Exclude/Include Arrays
	'||||||||||||||||||||||||||||||||
	Call LogArea("Mapping Inclusions and Exclusions")

    Dim applicationsPrefix : applicationsPrefix = oTSE(tsAppVariableName)
    Dim windowsAppPackageAppPrefix : windowsAppPackageAppPrefix = oTSE(tsWindowsAppPackageAppVariableName)
    Dim appInstall : appInstall = oTSE(tsAppInstall)

    'Brand Base Variable Values
    'And Variables that start with these Prefixes

    Dim incArray : incArray = Split( includeMap & ";" & tsAppVariableName & ";" & tsAppInstall & ";" & appInstall & ";" & tsWindowsAppPackageAppVariableName & ";" & windowsAppPackageAppPrefix  , ";" )
	Dim excArray : excArray = Split( excludeMap, ";" )

	'||||||||||||||||||||||||||||||||
	' Loop through TS Variables
	'||||||||||||||||||||||||||||||||
	Call LogArea("Branding Registry")
	Call BrandValue( "InstalledOn", Date )

	Dim tV
    For Each tV in oTSE.GetVariables()
		IF (MatchMaker( tV, incArray ) = TRUE) Then
			IF (MatchMaker( tV, excArray ) = FALSE ) Then
				Call BrandValue( tV, oTSE(tV) )
			End IF
		End IF
    Next


   'Brand Applications
   If( Len(Trim(applicationsPrefix)) > 0 ) Then
        For Each tV in oTSE.GetVariables()
            If ( InStr(1, tV, applicationsPrefix, 1) = 1 ) Then
			    IF (MatchMaker( tV, excArray ) = FALSE ) Then
                        Call BrandValue( Replace(tV, applicationsPrefix, UCase(applicationsPrefix) & "0",1,-1, 1), oTSE(tV) )
			    End IF
		    End IF
        Next
    End If

	WScript.Quit(0)

	'[##############################################################################################################################]
	' FUNCTIONS
	'[##############################################################################################################################]

	' ////////////////////////////////////////////////////
	' Brand a name and value to registry
	' ////////////////////////////////////////////////////
	Sub BrandValue( theName, theValue )

		Dim retVal : retVal = 0
		Dim runCmd : runCmd = REGBRAND & " ADD " & REGBRANDPATH & " /F /V " & theName & " /T REG_SZ /D """ & theValue & """"

		Wscript.Echo " Branding : [" & runCmd & "]"
		retVal = oWSH.Run( runCMD, 0, True )
		Wscript.Echo " Result   : [" & retVal & "]"

	End Sub

	' ////////////////////////////////////////////////////
	' Match "StartsWith" against an array of values
	' ////////////////////////////////////////////////////
	Function MatchMaker(theItem, theArray)
		Dim retVal : retVal = FALSE

		Dim anItem
		For Each anItem in theArray
			If ( Len(anItem)=0 ) Then Exit For
			' ||||||||||||||||||||||||||||||||
			'  - StartsWith is position 1
			'  - Case/Text Insensitive is 1
			' ||||||||||||||||||||||||||||||||
			If ( InStr(1, theItem, anItem, 1) = 1 ) Then
				retVal = TRUE
				Exit For
			End If
		Next

		MatchMaker = retVal

	End Function

	' ////////////////////////////////////////////////////
	' Detects if 32-bit environment on 64-bit OS
	' ////////////////////////////////////////////////////
	Function IsSysnative()

		Dim	PARCH1 : PARCH1 = UCASE( oWSH.ExpandEnvironmentStrings("%PROCESSOR_ARCHITECTURE%") )
		Dim	PARCH2 : PARCH2 = UCASE( oWSH.ExpandEnvironmentStrings("%PROCESSOR_ARCHITEW6432%") )

		wscript.echo "%PROCESSOR_ARCHITECTURE% = [" & PARCH1 & "]"
		wscript.echo "%PROCESSOR_ARCHITEW6432% = [" & PARCH2 & "]"

		IF ( (PARCH1 = "X86") AND (PARCH2 = "AMD64") ) Then IsSysnative=TRUE _
		ELSE IsSysnative = FALSE

		wscript.echo "32-BIT Environment on a 64-BIT OS: [" & IsSysnative & "]"

	End Function

	' ////////////////////////////////////////////////////
	' Log Area
	' ////////////////////////////////////////////////////
	Sub LogArea( theText )

		Wscript.Echo
		Wscript.Echo "---------------------------------------------------"
		Wscript.Echo " " & theText
		Wscript.Echo "---------------------------------------------------"
		Wscript.Echo

	End Sub

    Sub SetRunOnce()

    Dim sKey, sCommand
    sKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\AppInstall"
    sValue = ""

       on error resume next
   wshshell.RegWrite sKey, sValue, REG_SZ

    End Sub
'' SIG '' Begin signature block
'' SIG '' MIIatQYJKoZIhvcNAQcCoIIapjCCGqICAQExCzAJBgUr
'' SIG '' DgMCGgUAMGcGCisGAQQBgjcCAQSgWTBXMDIGCisGAQQB
'' SIG '' gjcCAR4wJAIBAQQQTvApFpkntU2P5azhDxfrqwIBAAIB
'' SIG '' AAIBAAIBAAIBADAhMAkGBSsOAwIaBQAEFNIEPBPn7mpg
'' SIG '' 7z2nZcle4lLAcYhBoIIVgjCCBMMwggOroAMCAQICEzMA
'' SIG '' AAAz5SeGow5KKoAAAAAAADMwDQYJKoZIhvcNAQEFBQAw
'' SIG '' dzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
'' SIG '' b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
'' SIG '' Y3Jvc29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWlj
'' SIG '' cm9zb2Z0IFRpbWUtU3RhbXAgUENBMB4XDTEzMDMyNzIw
'' SIG '' MDgyM1oXDTE0MDYyNzIwMDgyM1owgbMxCzAJBgNVBAYT
'' SIG '' AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
'' SIG '' EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
'' SIG '' cG9yYXRpb24xDTALBgNVBAsTBE1PUFIxJzAlBgNVBAsT
'' SIG '' Hm5DaXBoZXIgRFNFIEVTTjpGNTI4LTM3NzctOEE3NjEl
'' SIG '' MCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
'' SIG '' dmljZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
'' SIG '' ggEBAMreyhkPH5ZWgl/YQjLUCG22ncDC7Xw4q1gzrWuB
'' SIG '' ULiIIQpdr5ctkFrHwy6yTNRjdFj938WJVNALzP2chBF5
'' SIG '' rKMhIm0z4K7eJUBFkk4NYwgrizfdTwdq3CrPEFqPV12d
'' SIG '' PfoXYwLGcD67Iu1bsfcyuuRxvHn/+MvpVz90e+byfXxX
'' SIG '' WC+s0g6o2YjZQB86IkHiCSYCoMzlJc6MZ4PfRviFTcPa
'' SIG '' Zh7Hc347tHYXpqWgoHRVqOVgGEFiOMdlRqsEFmZW6vmm
'' SIG '' y0LPXVRkL4H4zzgADxBr4YMujT5I7ElWSuyaafTLDxD7
'' SIG '' BzRKYmwBjW7HIITKXNFjmR6OXewPpRZIqmveIS8CAwEA
'' SIG '' AaOCAQkwggEFMB0GA1UdDgQWBBQAWBs+7cXxBpO+MT02
'' SIG '' tKwLXTLwgTAfBgNVHSMEGDAWgBQjNPjZUkZwCu1A+3b7
'' SIG '' syuwwzWzDzBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
'' SIG '' Y3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0
'' SIG '' cy9NaWNyb3NvZnRUaW1lU3RhbXBQQ0EuY3JsMFgGCCsG
'' SIG '' AQUFBwEBBEwwSjBIBggrBgEFBQcwAoY8aHR0cDovL3d3
'' SIG '' dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNyb3Nv
'' SIG '' ZnRUaW1lU3RhbXBQQ0EuY3J0MBMGA1UdJQQMMAoGCCsG
'' SIG '' AQUFBwMIMA0GCSqGSIb3DQEBBQUAA4IBAQAC/+OMA+rv
'' SIG '' fji5uXyfO1KDpPojONQDuGpZtergb4gD9G9RapU6dYXo
'' SIG '' HNwHxU6dG6jOJEcUJE81d7GcvCd7j11P/AaLl5f5KZv3
'' SIG '' QB1SgY52SAN+8psXt67ZWyKRYzsyXzX7xpE8zO8OmYA+
'' SIG '' BpE4E3oMTL4z27/trUHGfBskfBPcCvxLiiAFHQmJkTkH
'' SIG '' TiFO3mx8cLur8SCO+Jh4YNyLlM9lvpaQD6CchO1ctXxB
'' SIG '' oGEtvUNnZRoqgtSniln3MuOj58WNsiK7kijYsIxTj2hH
'' SIG '' R6HYAbDxYRXEF6Et4zpsT2+vPe7eKbBEy8OSZ7oAzg+O
'' SIG '' Ee/RAoIxSZSYnVFIeK0d1kC2MIIE7DCCA9SgAwIBAgIT
'' SIG '' MwAAALARrwqL0Duf3QABAAAAsDANBgkqhkiG9w0BAQUF
'' SIG '' ADB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
'' SIG '' Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
'' SIG '' TWljcm9zb2Z0IENvcnBvcmF0aW9uMSMwIQYDVQQDExpN
'' SIG '' aWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQTAeFw0xMzAx
'' SIG '' MjQyMjMzMzlaFw0xNDA0MjQyMjMzMzlaMIGDMQswCQYD
'' SIG '' VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
'' SIG '' A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
'' SIG '' IENvcnBvcmF0aW9uMQ0wCwYDVQQLEwRNT1BSMR4wHAYD
'' SIG '' VQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24wggEiMA0G
'' SIG '' CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDor1yiIA34
'' SIG '' KHy8BXt/re7rdqwoUz8620B9s44z5lc/pVEVNFSlz7SL
'' SIG '' qT+oN+EtUO01Fk7vTXrbE3aIsCzwWVyp6+HXKXXkG4Un
'' SIG '' m/P4LZ5BNisLQPu+O7q5XHWTFlJLyjPFN7Dz636o9UEV
'' SIG '' XAhlHSE38Cy6IgsQsRCddyKFhHxPuRuQsPWj/ov0DJpO
'' SIG '' oPXJCiHiquMBNkf9L4JqgQP1qTXclFed+0vUDoLbOI8S
'' SIG '' /uPWenSIZOFixCUuKq6dGB8OHrbCryS0DlC83hyTXEmm
'' SIG '' ebW22875cHsoAYS4KinPv6kFBeHgD3FN/a1cI4Mp68fF
'' SIG '' SsjoJ4TTfsZDC5UABbFPZXHFAgMBAAGjggFgMIIBXDAT
'' SIG '' BgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUWXGm
'' SIG '' WjNN2pgHgP+EHr6H+XIyQfIwUQYDVR0RBEowSKRGMEQx
'' SIG '' DTALBgNVBAsTBE1PUFIxMzAxBgNVBAUTKjMxNTk1KzRm
'' SIG '' YWYwYjcxLWFkMzctNGFhMy1hNjcxLTc2YmMwNTIzNDRh
'' SIG '' ZDAfBgNVHSMEGDAWgBTLEejK0rQWWAHJNy4zFha5TJoK
'' SIG '' HzBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1p
'' SIG '' Y3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWND
'' SIG '' b2RTaWdQQ0FfMDgtMzEtMjAxMC5jcmwwWgYIKwYBBQUH
'' SIG '' AQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1p
'' SIG '' Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY0NvZFNpZ1BD
'' SIG '' QV8wOC0zMS0yMDEwLmNydDANBgkqhkiG9w0BAQUFAAOC
'' SIG '' AQEAMdduKhJXM4HVncbr+TrURE0Inu5e32pbt3nPApy8
'' SIG '' dmiekKGcC8N/oozxTbqVOfsN4OGb9F0kDxuNiBU6fNut
'' SIG '' zrPJbLo5LEV9JBFUJjANDf9H6gMH5eRmXSx7nR2pEPoc
'' SIG '' sHTyT2lrnqkkhNrtlqDfc6TvahqsS2Ke8XzAFH9IzU2y
'' SIG '' RPnwPJNtQtjofOYXoJtoaAko+QKX7xEDumdSrcHps3Om
'' SIG '' 0mPNSuI+5PNO/f+h4LsCEztdIN5VP6OukEAxOHUoXgSp
'' SIG '' Rm3m9Xp5QL0fzehF1a7iXT71dcfmZmNgzNWahIeNJDD3
'' SIG '' 7zTQYx2xQmdKDku/Og7vtpU6pzjkJZIIpohmgjCCBbww
'' SIG '' ggOkoAMCAQICCmEzJhoAAAAAADEwDQYJKoZIhvcNAQEF
'' SIG '' BQAwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmS
'' SIG '' JomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWlj
'' SIG '' cm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
'' SIG '' MB4XDTEwMDgzMTIyMTkzMloXDTIwMDgzMTIyMjkzMlow
'' SIG '' eTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
'' SIG '' b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
'' SIG '' Y3Jvc29mdCBDb3Jwb3JhdGlvbjEjMCEGA1UEAxMaTWlj
'' SIG '' cm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EwggEiMA0GCSqG
'' SIG '' SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCycllcGTBkvx2a
'' SIG '' YCAgQpl2U2w+G9ZvzMvx6mv+lxYQ4N86dIMaty+gMuz/
'' SIG '' 3sJCTiPVcgDbNVcKicquIEn08GisTUuNpb15S3GbRwfa
'' SIG '' /SXfnXWIz6pzRH/XgdvzvfI2pMlcRdyvrT3gKGiXGqel
'' SIG '' cnNW8ReU5P01lHKg1nZfHndFg4U4FtBzWwW6Z1KNpbJp
'' SIG '' L9oZC/6SdCnidi9U3RQwWfjSjWL9y8lfRjFQuScT5EAw
'' SIG '' z3IpECgixzdOPaAyPZDNoTgGhVxOVoIoKgUyt0vXT2Pn
'' SIG '' 0i1i8UU956wIAPZGoZ7RW4wmU+h6qkryRs83PDietHdc
'' SIG '' pReejcsRj1Y8wawJXwPTAgMBAAGjggFeMIIBWjAPBgNV
'' SIG '' HRMBAf8EBTADAQH/MB0GA1UdDgQWBBTLEejK0rQWWAHJ
'' SIG '' Ny4zFha5TJoKHzALBgNVHQ8EBAMCAYYwEgYJKwYBBAGC
'' SIG '' NxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQU/dExTtMm
'' SIG '' ipXhmGA7qDFvpjy82C0wGQYJKwYBBAGCNxQCBAweCgBT
'' SIG '' AHUAYgBDAEEwHwYDVR0jBBgwFoAUDqyCYEBWJ5flJRP8
'' SIG '' KuEKU5VZ5KQwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDov
'' SIG '' L2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVj
'' SIG '' dHMvbWljcm9zb2Z0cm9vdGNlcnQuY3JsMFQGCCsGAQUF
'' SIG '' BwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3d3dy5t
'' SIG '' aWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNyb3NvZnRS
'' SIG '' b290Q2VydC5jcnQwDQYJKoZIhvcNAQEFBQADggIBAFk5
'' SIG '' Pn8mRq/rb0CxMrVq6w4vbqhJ9+tfde1MOy3XQ60L/svp
'' SIG '' LTGjI8x8UJiAIV2sPS9MuqKoVpzjcLu4tPh5tUly9z7q
'' SIG '' QX/K4QwXaculnCAt+gtQxFbNLeNK0rxw56gNogOlVuC4
'' SIG '' iktX8pVCnPHz7+7jhh80PLhWmvBTI4UqpIIck+KUBx3y
'' SIG '' 4k74jKHK6BOlkU7IG9KPcpUqcW2bGvgc8FPWZ8wi/1wd
'' SIG '' zaKMvSeyeWNWRKJRzfnpo1hW3ZsCRUQvX/TartSCMm78
'' SIG '' pJUT5Otp56miLL7IKxAOZY6Z2/Wi+hImCWU4lPF6H0q7
'' SIG '' 0eFW6NB4lhhcyTUWX92THUmOLb6tNEQc7hAVGgBd3TVb
'' SIG '' Ic6YxwnuhQ6MT20OE049fClInHLR82zKwexwo1eSV32U
'' SIG '' jaAbSANa98+jZwp0pTbtLS8XyOZyNxL0b7E8Z4L5UrKN
'' SIG '' MxZlHg6K3RDeZPRvzkbU0xfpecQEtNP7LN8fip6sCvsT
'' SIG '' J0Ct5PnhqX9GuwdgR2VgQE6wQuxO7bN2edgKNAltHIAx
'' SIG '' H+IOVN3lofvlRxCtZJj/UBYufL8FIXrilUEnacOTj5XJ
'' SIG '' jdibIa4NXJzwoq6GaIMMai27dmsAHZat8hZ79haDJLmI
'' SIG '' z2qoRzEvmtzjcT3XAH5iR9HOiMm4GPoOco3Boz2vAkBq
'' SIG '' /2mbluIQqBC0N1AI1sM9MIIGBzCCA++gAwIBAgIKYRZo
'' SIG '' NAAAAAAAHDANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZIm
'' SIG '' iZPyLGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWlj
'' SIG '' cm9zb2Z0MS0wKwYDVQQDEyRNaWNyb3NvZnQgUm9vdCBD
'' SIG '' ZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMDcwNDAzMTI1
'' SIG '' MzA5WhcNMjEwNDAzMTMwMzA5WjB3MQswCQYDVQQGEwJV
'' SIG '' UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
'' SIG '' UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
'' SIG '' cmF0aW9uMSEwHwYDVQQDExhNaWNyb3NvZnQgVGltZS1T
'' SIG '' dGFtcCBQQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
'' SIG '' ggEKAoIBAQCfoWyx39tIkip8ay4Z4b3i48WZUSNQrc7d
'' SIG '' GE4kD+7Rp9FMrXQwIBHrB9VUlRVJlBtCkq6YXDAm2gBr
'' SIG '' 6Hu97IkHD/cOBJjwicwfyzMkh53y9GccLPx754gd6udO
'' SIG '' o6HBI1PKjfpFzwnQXq/QsEIEovmmbJNn1yjcRlOwhtDl
'' SIG '' KEYuJ6yGT1VSDOQDLPtqkJAwbofzWTCd+n7Wl7PoIZd+
'' SIG '' +NIT8wi3U21StEWQn0gASkdmEScpZqiX5NMGgUqi+YSn
'' SIG '' EUcUCYKfhO1VeP4Bmh1QCIUAEDBG7bfeI0a7xC1Un68e
'' SIG '' eEExd8yb3zuDk6FhArUdDbH895uyAc4iS1T/+QXDwiAL
'' SIG '' AgMBAAGjggGrMIIBpzAPBgNVHRMBAf8EBTADAQH/MB0G
'' SIG '' A1UdDgQWBBQjNPjZUkZwCu1A+3b7syuwwzWzDzALBgNV
'' SIG '' HQ8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwgZgGA1Ud
'' SIG '' IwSBkDCBjYAUDqyCYEBWJ5flJRP8KuEKU5VZ5KShY6Rh
'' SIG '' MF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJ
'' SIG '' k/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jv
'' SIG '' c29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eYIQ
'' SIG '' ea0WoUqgpa1Mc1j0BxMuZTBQBgNVHR8ESTBHMEWgQ6BB
'' SIG '' hj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
'' SIG '' bC9wcm9kdWN0cy9taWNyb3NvZnRyb290Y2VydC5jcmww
'' SIG '' VAYIKwYBBQUHAQEESDBGMEQGCCsGAQUFBzAChjhodHRw
'' SIG '' Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01p
'' SIG '' Y3Jvc29mdFJvb3RDZXJ0LmNydDATBgNVHSUEDDAKBggr
'' SIG '' BgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAgEAEJeKw1wD
'' SIG '' RDbd6bStd9vOeVFNAbEudHFbbQwTq86+e4+4LtQSooxt
'' SIG '' YrhXAstOIBNQmd16QOJXu69YmhzhHQGGrLt48ovQ7DsB
'' SIG '' 7uK+jwoFyI1I4vBTFd1Pq5Lk541q1YDB5pTyBi+FA+mR
'' SIG '' KiQicPv2/OR4mS4N9wficLwYTp2OawpylbihOZxnLcVR
'' SIG '' DupiXD8WmIsgP+IHGjL5zDFKdjE9K3ILyOpwPf+FChPf
'' SIG '' wgphjvDXuBfrTot/xTUrXqO/67x9C0J71FNyIe4wyrt4
'' SIG '' ZVxbARcKFA7S2hSY9Ty5ZlizLS/n+YWGzFFW6J1wlGys
'' SIG '' OUzU9nm/qhh6YinvopspNAZ3GmLJPR5tH4LwC8csu89D
'' SIG '' s+X57H2146SodDW4TsVxIxImdgs8UoxxWkZDFLyzs7BN
'' SIG '' Z8ifQv+AeSGAnhUwZuhCEl4ayJ4iIdBD6Svpu/RIzCzU
'' SIG '' 2DKATCYqSCRfWupW76bemZ3KOm+9gSd0BhHudiG/m4LB
'' SIG '' J1S2sWo9iaF2YbRuoROmv6pH8BJv/YoybLL+31HIjCPJ
'' SIG '' Zr2dHYcSZAI9La9Zj7jkIeW1sMpjtHhUBdRBLlCslLCl
'' SIG '' eKuzoJZ1GtmShxN1Ii8yqAhuoFuMJb+g74TKIdbrHk/J
'' SIG '' mu5J4PcBZW+JC33Iacjmbuqnl84xKf8OxVtc2E0bodj6
'' SIG '' L54/LlUWa8kTo/0xggSfMIIEmwIBATCBkDB5MQswCQYD
'' SIG '' VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
'' SIG '' A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
'' SIG '' IENvcnBvcmF0aW9uMSMwIQYDVQQDExpNaWNyb3NvZnQg
'' SIG '' Q29kZSBTaWduaW5nIFBDQQITMwAAALARrwqL0Duf3QAB
'' SIG '' AAAAsDAJBgUrDgMCGgUAoIG4MBkGCSqGSIb3DQEJAzEM
'' SIG '' BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
'' SIG '' BgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRbJVvG53rD
'' SIG '' m4FDg3H6g9YbNMVv3DBYBgorBgEEAYI3AgEMMUowSKAq
'' SIG '' gCgATQBEAFQAIAAyADAAMQAzACAAVQBEAEkAIABUAG8A
'' SIG '' bwBsAGsAaQB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0
'' SIG '' LmNvbTANBgkqhkiG9w0BAQEFAASCAQBG94xvcZg1oO/H
'' SIG '' Rpjc5bsPpOWllWCU+p08vl/5k1GnoV+0eO8RG4k1Ze9Q
'' SIG '' uda5XES16uJJCgPjOC7UDO2rrq0+ZUJAiMkZKTZqyBGV
'' SIG '' BZ+T1BpKXqT1ABsW29ZBacL7u4bUFfNzCB4o7UF0XTE+
'' SIG '' jDc6PEq0+bO64/o0X1Zc1z3ybbcLgJa/F2XqkDjQUJvY
'' SIG '' 3ArronTuVA3ZaZJFqZjfRPC0/zYKlaCs1Q3MTUkrRtr9
'' SIG '' 6gu/Xmq2VUtgOwHfQo3vGsWUGsauwLQxviOI14LHjJOh
'' SIG '' UYXhqQ7EZpDlWeLNT7AA6sxJHTUVclCA0kITM9HNS5sq
'' SIG '' 6Gpor2GliIq1yc/JdGZKoYICKDCCAiQGCSqGSIb3DQEJ
'' SIG '' BjGCAhUwggIRAgEBMIGOMHcxCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1w
'' SIG '' IFBDQQITMwAAADPlJ4ajDkoqgAAAAAAAMzAJBgUrDgMC
'' SIG '' GgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
'' SIG '' BgkqhkiG9w0BCQUxDxcNMTMwNTI0MjEzMTAxWjAjBgkq
'' SIG '' hkiG9w0BCQQxFgQU0YMCwtTI7S6rYtTAA9JiX62S4vsw
'' SIG '' DQYJKoZIhvcNAQEFBQAEggEAT7CzfPUlNxGagOi9nb4D
'' SIG '' AXEoU4dZX0+QJZ6N8BdGWZf4D0ur4XhRm5NoGOt8Yjnw
'' SIG '' e1xOO46qi/9KlUYzv6xPx69/KlV1LkKWfCbhRWh0XoHa
'' SIG '' 1pHqBcRm+sqF/wwIMmUMlG1SuA0SSxI3wagfJE6hJtU9
'' SIG '' JjIljTa/hVkKo57eu9fJqdgX8vToye6/2EhkwrpJuRo0
'' SIG '' Saf4lxLP73Su7CBV91QrL2hKRr7QzDzEcb/HiMhyi5EN
'' SIG '' GfbMQD16Y3a0aOkrovr3nOSWmMj9Kd140G1ymFCUiTEs
'' SIG '' 0vxqCot8wTE5Ph3zxPQ81q4ZaEIPIixJ50g220uEEEDQ
'' SIG '' M7vS0QrXuQGM2g==
'' SIG '' End signature block
