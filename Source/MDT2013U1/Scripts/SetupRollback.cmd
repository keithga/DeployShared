@echo off
for %%d in (c d e f g h i j k l m n o p q r s t u v w x y z) do if exist %%d:\MININT\Scripts\SetUpgradeStatus.wsf (
echo %DATE%-%TIME% Registering Upgrade Failure in registry >> %%d:\MININT\SMSOSD\OSDLOGS\SetupRollback.log
cscript.exe %%d:\MININT\Scripts\SetUpgradeStatus.wsf OSUpgrade:FAILURE )

for %%d in (c d e f g h i j k l m n o p q r s t u v w x y z) do if exist %%d:\MININT\Scripts\LTIBootstrap.vbs (
echo %DATE%-%TIME% Launching TSMBootstrapper to fininsh TS >> %%d:\MININT\SMSOSD\OSDLOGS\SetupRollback.log
wscript.exe %%d:\MININT\Scripts\LTIBootstrap.vbs ) 

for %%d in (c d e f g h i j k l m n o p q r s t u v w x y z) do if exist %%d:\MININT\Scripts\UpgradeSummary.wsf (
echo %DATE%-%TIME% Complete deployment wizard and show failure code >> %%d:\MININT\SMSOSD\OSDLOGS\SetupRollback.log
cscript.exe %%d:\MININT\Scripts\UpgradeSummary.wsf)
