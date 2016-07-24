
:: // ***************************************************************************
:: //
:: // Copyright (c) Microsoft Corporation.  All rights reserved.
:: //
:: // Microsoft Deployment Toolkit Extensions http://MDTEx.codeplex.com
:: //
:: // File:      ZTICScript.cmd
:: //
:: // Purpose:   This is a wrapper around CScript.exe, used to capture errors
:: //
:: // Usage:     [cmd.exe /c] ZTICscript.cmd <Script>.wsf [/debug:true]
:: //
:: // ***************************************************************************

@if not defined debug echo off

:GetScriptLocation
	set ScriptDirectory=%~dp1
	if not exist "%~f1" if exist "%~dp0\%~nx1" (
		set ScriptDirectory=%~dp0
	)

:RunCommand
	CScript.exe //nologo "%ScriptDirectory%%~nx1" %2 %3 %4 %5 %6 %7 %8  /DebugCapture 2> "%temp%\%~n1.log"
	
	set CscriptError=%ErrorLevel%
	if "%CscriptError%"=="0" goto :Finished
	
:CheckFileSize
	for %%i in ( "%temp%\%~n1.log" ) do ( if "%%~zi"=="0" goto :Finished )
	
:ErrorHandling
	:: Copy the contents of the file: "%temp%\%~n1.log" into the MDT Logging System.
	CScript.exe //nologo "%~dp0\ZTICScript_Log.wsf" /ScriptName:"%~n1" /LogFile:"%temp%\%~n1.log" /ErrorLevel:%CscriptError%

:Finished
	exit %CscriptError%
