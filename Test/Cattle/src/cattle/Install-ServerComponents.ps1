
[cmdletbinding()]
param
( 
    [ValidateSet("Specialize", "OOBEFirst", "OOBELogon")]
    $Mode
)

$ErrorActionPreference = 'stop'

Write-Host "#########################################`r`nMode: $Mode"

#region Per Machine Install Specialize

if ( $mode -eq 'Specialize' )
{

    # Run Elevated, first in the deployment process, limited OS support. 
    copy-item -Recurse -Path $psScriptRoot -Destination 'c:\programdata\Cattle'

}

#endregion

#region 
#####################################################################
if ( $Mode -eq 'OOBEFirst')
{

    write-verbose "Per Machine Install during OOBE"

    ################################

    if ( -not ( Test-Path 'c:\programdata\Cattle\bginfo.exe' ) )
    {
        Invoke-WebRequest -Uri 'https://live.sysinternals.com/Bginfo.exe' -UseBasicParsing -OutFile 'c:\programdata\Cattle\bginfo.exe'
    }

    set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
    set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fSingleSessionPerUser" -Value 1
    reg.exe add "hklm\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v ShutdownReasonOn /t REG_DWORD /d 0x00000000 /f

    netsh.exe advfirewall firewall set rule group="remote desktop" new enable=Yes
    netsh.exe advfirewall firewall set rule name="File and Printer Sharing (SMB-In)" dir=in profile=any new enable=yes

    Get-ExecutionPolicy -list | out-string | Write-Verbose
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue
    c:\windows\sysWOW64\WindowsPowerShell\v1.0\powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue"

    ###############################

    Get-Disk | Where-Object operationalstatus -ne Online | set-Disk -IsOffline $False

    ###############################

    Enable-PSRemoting -force
    Set-Item wsman:localhost\client\trustedhosts -Value * -force
    winrm  quickconfig -transport:HTTP -force

    ###############################

    if ( Test-Path 'c:\programdata\Cattle\install-servercomponents.ps1' )
    {
        $CattleCommand = "powershell -command ""c:\programdata\Cattle\install-servercomponents.ps1"" -WindowStyle Minimized -Mode OOBELogon || pause"
        # Reg.exe add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Cattle" /t REG_SZ /f /d "$CattleCommand"
    }

    ###############################

    write-host "`n`nchange the administrator password:"
    net user administrator *

    write-host "`n`nComma Delimited List of User Accounts: (example: JohnDoe)"
    foreach ( $UserAccount in (read-Host "User Accounts:") -split ',' )
    {
        if ( -not ( [string]::IsNullOrEmpty( $UserAccount ) ) ) 
        {
            net.exe user /add $UserAccount /FullName:"$UserAccount" /Expires:Never P@ssw0rd
            get-wmiobject -Class Win32_UserAccount -Filter "name='$UserAccount'"  | swmi -Argument @{PasswordExpires = 0}
            write-host "net.exe localgroup administrators /add $UserAccount"
            net.exe localgroup administrators /add $UserAccount
            net.exe user $USerAccount *
        }
    }

    $ComputerName = read-Host "Computer Name:"
    if ($ComputerName)
    {
        rename-computer -newname $COmputerName
        write-host "reboot requried!`n press enter to reboot!"
        read-host
        shutdown -r -f -t 0 
    }

}

#endregion

#region Per User Install (last)
#####################################################################

if ( $Mode -eq 'OOBELogon')
{

    # Run for each user, not elevated

    reg.exe ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ /v HideFileExt /t REG_DWORD /d 0 /f
    reg.exe ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ /v Start_ShowRun /t REG_DWORD /d 1 /f
    reg.exe ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ /v StartMenuAdminTools /t REG_DWORD /d 1 /f

    reg.exe ADD HKCU\Console /v QuickEdit /t REG_DWORD /d 1 /f

    for ( $i = 0; $i -lt 30 -and ( -not ( Test-Path 'c:\programdata\Cattle\bginfo.exe')); $i++) { Start-Sleep 1 }
    & 'c:\programdata\Cattle\bginfo.exe' /NOLICPROMPT /silent /timer:0 'c:\programdata\Cattle\Cattle.bgi'

}

#endregion

#####################################################################

# exit 0 - Just fine
# exit 1 - Reboot required
# exit 2 - Reboot required run again


<#

Testing:
* verify BGInfo installed 
* Verify c:\programdata\cattle created
* Verify run command created

Todo:

* Windows Update

My Preferences:

* Offline patching with latest Update
* Install components - Hyper-V ( if physical ) etc...

* SSD Detection - Change HyperV disk location to SSD
* Create Network Shares

#>

