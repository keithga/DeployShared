@if not defined debug echo off

set isofile=e:\_cache\WIN2012R2S\9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO
@powershell.exe -executionpolicy bypass -command %~dps0\demo-hypervquickstart.ps1 -SourceImageFile %isofile% -VHDFile %~dps0\Gen1\ServerParent.vhdx -ImageIndex 2 -generation 1 %*
@powershell.exe -executionpolicy bypass -command %~dps0\demo-hypervquickstart.ps1 -SourceImageFile %isofile% -VHDFile %~dps0\Gen2\ServerParent.vhdx -ImageIndex 2 -generation 2 %*

