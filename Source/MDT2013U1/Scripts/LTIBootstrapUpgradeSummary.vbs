' // ***************************************************************************
' // 
' // Copyright (c) Microsoft Corporation.  All rights reserved.
' // 
' // Microsoft Deployment Toolkit Solution Accelerator
' //
' // File:      LTIBootstrapUpgradeSummary.vbs
' // 
' // Version:   6.3.8298.1000
' // 
' // Purpose:   Invoke UpgradeSummary.wsf from the appropriate folder
' // 
' // Usage:     wscript LTIBootstrapUpgradeSummary.vbs
' // 
' // ***************************************************************************

'//----------------------------------------------------------------------------
'//
'//  Global constant and variable declarations
'//
'//----------------------------------------------------------------------------

Option Explicit

Dim iRetVal
Dim oShell
Dim oFSO
Dim oDrive
Dim sCmd
Dim bFound


'//----------------------------------------------------------------------------
'//  Initialization
'//----------------------------------------------------------------------------

Set oShell = CreateObject("WScript.Shell")
Set oFSO = CreateObject("Scripting.FileSystemObject")


'//----------------------------------------------------------------------------
'//  Find UpgradeSummary.wsf and run it
'//----------------------------------------------------------------------------

bFound = false
For Each oDrive in oFSO.Drives
	If oDrive.IsReady then
		If oFSO.FileExists(oDrive.DriveLetter & ":\MININT\Scripts\UpgradeSummary.wsf") then
			sCmd = "wscript.exe """ & oDrive.DriveLetter & ":\MININT\Scripts\UpgradeSummary.wsf"" "
			iRetVal = oShell.Run(sCmd, 1, true)
			bFound = true
			Exit For
		End if
	End if
Next


' Make sure we ran something.  If not, pop up an error

If not bFound then
	oShell.Popup "Unable to find UpgradeSummary.wsf needed to continue the deployment.", 0, "Script not found", 48
	iRetVal = 9981
End if


' Delete ourselves

On Error Resume Next
oFSO.DeleteFile Wscript.ScriptFullName, true
On Error Goto 0


' All done

WScript.Quit iRetVal
