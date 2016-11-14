@echo off
:: // ***************************************************************************
:: //
:: // Copyright (c) Microsoft Corporation.  All rights reserved.
:: //
:: // Microsoft Deployment Toolkit Solution Accelerator
:: //
:: // File:      SetupComplete.cmd
:: //
:: // Version:   6.3.8443.1000
:: //
:: // Purpose:   Called after a successful in-place upgrade.  This batch file
:: //            sets itself to re-run after reboots, and then calls
:: //            LTIBootstrap.vbs to run the task sequence.  If the task
:: //            sequence doesn't initiate a reboot (indicating that the
:: //            task sequence is done), the batch file will continue and
:: //            clean itself from the registry.
:: //
:: // ***************************************************************************

for %%d in (c d e f g h i j k l m n o p q r s t u v w x y z) do if exist %%d:\Windows\Setup\Scripts\setupcomplete.cmd ( 
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Windows" /v Win10UpgradeStatusCode /t REG_SZ /d "Success" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v SetupType /t REG_DWORD /d 2 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v CmdLine /t REG_SZ /d "%%d:\Windows\Setup\Scripts\setupcomplete.cmd" /f 
echo %DATE%-%TIME% Registered Setupcomplete.cmd in registry >> %%d:\MININT\SMSOSD\OSDLOGS\setupcomplete.log)

for %%d in (c d e f g h i j k l m n o p q r s t u v w x y z) do if exist %%d:\MININT\Scripts\LTIBootstrap.vbs (wscript.exe %%d:\MININT\Scripts\LTIBootstrap.vbs ) 

echo %DATE%-%TIME% Successfully upgraded windows, resetting registry >> %WINDIR%\CCM\Logs\setupcomplete.log
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v SetupType /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v CmdLine /t REG_SZ /d "" /f
for %%d in (c d e f g h i j k l m n o p q r s t u v w x y z) do if exist %%:\Windows\Setup\Scripts\setupcomplete.cmd ( 
echo %DATE%-%TIME% Exiting SetupComplete.cmd >> %%d:\MININT\SMSOSD\OSDLOGS\setupcomplete.log)