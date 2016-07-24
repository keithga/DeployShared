' // ***************************************************************************
' // 
' // Copyright (c) Microsoft Corporation.  All rights reserved.
' // 
' // Microsoft Deployment Toolkit Solution Accelerator
' //
' // File:      Deploy_SCCM_Scripts.vbs
' // 
' // Version:   6.3.8330.1000
' // 
' // Purpose:   Implements a wizard that is displayed during new computer
' //            ConfigMgr deployments.
' // 
' // Usage:     (used by Deploy_SCCM_Definition_ENU.xml)
' // 
' // ***************************************************************************

Option Explicit


'''''''''''''''''''''''''''''''''''''
'  Initialize ComputerName
'

Function InitializeComputerName

	If oUtility.ComputerName = "" Then
				
		If oEnvironment.Item("HostName") <> "" Then
			OSDComputerName.Value = oEnvironment.Item("HostName")
		Else
			OSDComputerName.Value = oENV("ComputerName")
		End If

	Else
		OSDComputerName.Value = oEnvironment.Item("OSDComputerName")
	End If

End Function


'''''''''''''''''''''''''''''''''''''
'  Validate ComputerName
'

Function ValidateComputerName

	' Check Warnings
	ParseAllWarningLabels


	If Len(OSDComputerName.value) > 15 then
		InvalidChar.style.display = "none"
		TooLong.style.display = "inline"
		ValidateComputerName = false
		ButtonNext.disabled = true
	ElseIf IsValidComputerName ( OSDComputerName.Value ) then
		ValidateComputerName = TRUE
		InvalidChar.style.display = "none"
		TooLong.style.display = "none"
	Else
		InvalidChar.style.display = "inline"
		TooLong.style.display = "none"
		ValidateComputerName = false
		ButtonNext.disabled = true
	End if

End function

