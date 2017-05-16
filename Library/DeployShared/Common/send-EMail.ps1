
<#

This file is a work in progress

$secpasswd = ConvertTo-SecureString "XXXXXXX" -AsPlainText -Force

$SendArgs = @{
    From = 'xxxx@keithga.com'
    To = '425xxxxxxx@txt.att.net'
    SMTPServer = 'xxx.com'
    UseSSL = $True
    Port = 587
    Credential = New-Object System.Management.Automation.PSCredential ("XXXX@xxxxx.com", $secpasswd)
    Embedded = @{
        Credential = New-Object System.Management.Automation.PSCredential ("xxxx@xxxx.com", $secpasswd)
        MyPWD = $secpasswd
    }
    MyPassword = $secpasswd
}

Send-MailMessage -body "This is a test message" -Subject "Update" @SendArgs

#>


