' // ***************************************************************************
' // 
' // Copyright (c) Microsoft Corporation.  All rights reserved.
' // 
' // Microsoft Deployment Toolkit Solution Accelerator
' //
' // File:      DeployWiz_Initialization.vbs
' // 
' // Version:   6.3.8456.1000
' // 
' // Purpose:   Main Client Deployment Wizard Initialization routines
' // 
' // ***************************************************************************


Option Explicit


Function InitializeUserDataLocation

	' We muck around with the values, so we need to do some manual cleanup

	If UCase(property("UserDataLocation")) = "" or UCase(property("UserDataLocation")) = "AUTO" then
		AllowLocal.Checked = TRUE
		UDRadio1.click
		UDRadio1.value = "AUTO"

	ElseIf UCase(property("UserDataLocation")) = "NONE" then
		UDRadio3.click

	ElseIf UCase(property("UserDataLocation")) = "NETWORK" then
		AllowLocal.Checked = FALSE
		UDRadio2.click
		UDRadio2.value = "NETWORK"
		If Property("UDShare") <> ""AND Property("UDDir") <> "" Then
			DataPath.value = Property("UDShare") & "\" & Property("UDDir")
		End if

	Else
		DataPath.Value = property("UserDataLocation")
		UDRadio2.click
	End if


	If property("DeploymentType") = "REPLACE" then

		If UDRadio3.Checked then
			UDRadio2.Click
		End if
		UDRadio3.Disabled = TRUE

	End if

	If property("UDShare") = "" and property("DeploymentType") <> "REFRESH" then

		If UDRadio1.Checked then
			UDRadio2.Click
		End if
		UDRadio1.Disabled = TRUE

	End if

	ValidateUserDataLocation

End function


'''''''''''''''''''''''''''''''''''''
'  Validate UserData Location
'

Function ValidateUserDataLocation

	Dim USMTTagFile
	InvalidPath.style.display = "none"

	UDRadio2.Value = DataPath.Value
	AllowLocal.Disabled = not UDRadio1.Checked
	document.GetElementByID("DataPath").Disabled = not UDRadio2.Checked
	document.GetElementByID("DataPathBrowse").Disabled = not UDRadio2.Checked

	ValidateUserDataLocation = ParseAllWarningLabels

	If UDRadio2.Checked then
		'If local Path (USB or other drive) is specified tag the drive
		If Mid(DataPath.Value, 2,1) = ":" Then
			On Error Resume Next
			Set USMTTagFile = OFSO.CreateTextFile(Left(DataPath.Value, 2) & "\UserState.tag", true)
			If Err Then
				InvalidPath.style.display = "inline"
				ValidateUserDateLocation = False
				Exit Function
			End If
			USMTTagFile.Close
		End If
			
	End if

End Function
