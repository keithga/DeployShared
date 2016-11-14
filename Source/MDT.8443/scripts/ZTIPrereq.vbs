' // ***************************************************************************
' // 
' // Copyright (c) Microsoft Corporation.  All rights reserved.
' // 
' // Microsoft Deployment Toolkit Solution Accelerator
' //
' // File:      ZTIPrereq.vbs
' // 
' // Version:   6.3.8443.1000
' // 
' // Purpose:   Check to see if the machine has the prerequisite software
' //            installed, and that it is functional.
' // 
' // Usage:     cscript ZTIPrereq.wsf
' // 
' // ***************************************************************************


'//----------------------------------------------------------------------------
'//
'//  Global constant and variable declarations
'//
'//----------------------------------------------------------------------------

Option Explicit

Dim iRetVal

'//----------------------------------------------------------------------------
'//  End declarations
'//----------------------------------------------------------------------------

'//----------------------------------------------------------------------------
'//  Main routine
'//----------------------------------------------------------------------------

iRetVal = ValidatePrereq
WScript.Quit iRetVal


'//---------------------------------------------------------------------------
'//
'//  Function:	ValidatePrereq()
'//
'//  Input:	None
'//
'//  Return:	Success - 0
'//		Failure - non-zero
'//
'//  Purpose:	Check that the needed software components are installed and
'//             functioning.
'//
'//---------------------------------------------------------------------------
Function ValidatePrereq()

	Dim oShell
	Dim oNetwork
	Dim oFSO
	Dim oEnv
	Dim oDoc

	On Error Resume Next

	' Create general-purpose WSH objects.  These should always succeed; if not,
	' WSH is seriously broken.

	Set oShell = CreateObject("WScript.Shell")
	If Err then
		ValidatePrereq = 5002   ' Report a specific return code
		EXIT FUNCTION
	End if

	Set oNetwork = CreateObject("WScript.Network")
	If Err then
		ValidatePrereq = 5003   ' Report a specific return code
		EXIT FUNCTION
	End if

	Set oFSO = CreateObject("Scripting.FileSystemObject")
	If Err then
		ValidatePrereq = 5004   ' Report a specific return code
		EXIT FUNCTION
	End if

	Set oEnv = oShell.Environment("PROCESS")
	If Err then
		ValidatePrereq = 5005   ' Report a specific return code
		EXIT FUNCTION
	End if

	' Make sure MSXML 6 is available

        Set oDoc = CreateObject("MSXML2.DOMDocument.6.0")
        If Err Then
                Set oDoc = CreateObject("MSXML2.DOMDocument")
        End If
	If Err then
		ValidatePrereq = 5006   ' Report a specific return code
		EXIT FUNCTION
	End if

	ValidatePrereq = 0

End Function
