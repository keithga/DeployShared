[cmdletbinding()]
param(
    
    [string] $ImagePath = 'f:\',
    [string] $Name, 
    [int]    $Index = 1,
    [ValidateSet( "HyperV", "HyperVGen2", "USB", "VHD", "ISO" )]
    [string] $Target = 'usb',
    [switch] $Silent
)

#region script Prep
###########################################################

$ErrorActionPreference = 'Stop'
$ExtraCommands = @()
$UserAccounts = @()

Import-module "$PSScriptRoot\..\..\Library\DeployShared" -Force

#endregion

#region Select Image
###########################################################

# TBD Get ISO Image

# Download from eval centers if necessary 

#endregion

#region Variables
###########################################################

$Host.UI.RawUI.WindowTitle = "Variables"

$MyDefaults = @(
    [PSCustomObject] @{ Tag="ComputerName"; Name="Computer Name"; Value = '*'; ToolTip = "ComputerName ( * = Random )"; },
    [PSCustomObject] @{ Tag="AdministratorPassword"; Name="Administrator Password"; Value = ( 'P@ssw0rd' ); ToolTip = "Administrator Account Password"; },

    [PSCustomObject] @{ Tag="TimeZone"; Name="Time Zone"; Value = ( [System.Timezone]::CurrentTimezone.StandardName ); ToolTip = "TimeZone"; },
    [PSCustomObject] @{ Tag="SystemLocale"; Name="SystemLocale"; Value = ( (Get-WinUserLanguageList).LanguageTag ); ToolTip = "System Locale"; },

    # [PSCustomObject] @{ Tag="NewAccount.Name"; Name="New Local User Name"; Value = ( 'Keith Garner' ); ToolTip = "New Account Name Created"; },

    [PSCustomObject] @{ Tag="IEHarden"; Name="Harden IE"; Value = ( 'false' ); ToolTip = "Harden IE for all users"; },

    [PSCustomObject] @{ Tag="EnableTS"; Name="Enable Terminal Services"; Value = ( 'true' ); ToolTip = "Enable Terminal Services and open Firewall Port"; },
    [PSCustomObject] @{ Tag="ExecutionPolicy"; Name="Set PowerShell Execution Policy"; Value = ( 'RemoteSigned' ); ToolTip = "Set-ExecutionPolicy for 64bit and 32bit"; },
    [PSCustomObject] @{ Tag="PSRemoting"; Name="Enable Powershell Remoting"; Value = ( 'true' ); ToolTip = "Enable PowerShell Remoting"; },

    [PSCustomObject] @{ Tag="AdditionalPS1"; Name="Additional PS1 Script to run"; Value = ( 'https://raw.githubusercontent.com/KuduApps/CustomPowershell/master/hello.ps1' ); ToolTip = "Additional Configuration Script to launch"; }
)

if ( get-command edit-keyvaluepair -ErrorAction SilentlyContinue )
{
    cls
    Write-Host "Common Variables"
    $MyFields = $MyDefaults | edit-KeyValuePair -HeaderWidths 0,-150,10000,0
    $MyFields | Select-Object -Property Tag,Value | Out-String | Write-verbose
}
else
{
    $MyFields = $MyDefaults
}

function Get-PropValue ( $name ) { $MyFields | where-object Tag -eq $Name | Where-object Value -ne '' | Select-object -first 1 -ExpandProperty value } 

#endregion


#region Create Unattend.xml
###########################################################

new-item -ItemType directory -force -path $env:temp\newISO | out-string | write-verbose

write-verbose "UNattend"
UNATTEND  {

    write-verbose "Specialize"
    SETTINGS specialize  {
        COMPONENT Microsoft-Windows-Shell-Setup {
            ELEMENT TimeZone (Get-PropValue 'TimeZone')
            ELEMENT ComputerName (Get-PropValue 'ComputerName')
        }
        
        COMPONENT Microsoft-Windows-IE-ESC { 
            ELEMENT IEHardenAdmin (Get-PropValue 'IEHarden').ToString().TOLower()
            ELEMENT IEHardenUser  (Get-PropValue 'IEHarden').ToString().TOLower()
        } 
        COMPONENT Microsoft-Windows-IE-InternetExplorer {
            ELEMENT Home_Page "about:tab"
        }
        
    }

    write-verbose "OOBESystem"
    SETTINGS oobeSystem {
        COMPONENT Microsoft-Windows-Shell-Setup {
            ELEMENT OOBE {
                ELEMENT NetworkLocation "Other"
                ELEMENT ProtectYourPC "1"
                ELEMENT HideEULAPage $True.ToString().ToLower()
                ELEMENT HideOnlineAccountScreens $True.ToString().ToLower()

                ELEMENT HideWirelessSetupInOOBE $True.ToString().ToLower()
                ELEMENT HideLocalAccountScreen $True.ToString().ToLower()
                ELEMENT HideOnlineAccountScreens $True.ToString().ToLower()
            }

            ELEMENT AutoLogon {
                ELEMENT LogonCount "1"
                ELEMENT UserName "Administrator"
                ELEMENT Enabled "true"
                PASSWORD "Password" (Get-PropValue 'AdministratorPassword')
            }

            ELEMENT UserAccounts {
                PASSWORD "AdministratorPassword" (Get-PropValue 'AdministratorPassword')
                ELEMENT LocalAccounts {

                    if (Get-PropValue 'NewAccount.Name') 
                    { 
                        ELEMENT LocalAccount -TypeAdd { 
                            $USerName = (Get-PropValue 'NewAccount.Name')
                            ELEMENT Description ('Local Admin Account for ' + $UserName)
                            ELEMENT DisplayName $UserName
                            ELEMENT Group "Administrators"  # Not Localized 
                            ELEMENT Name ( $UserName.split(" ") | select-object -first 1 )
                        }
                    }

                    foreach ( $UserAccount in $UserAccounts ) 
                    {
                        ELEMENT LocalAccount -TypeAdd { 
                            # Do not define the password, will # PASSWORD "Password" $UserAccount.Password
                            ELEMENT Description $UserAccount.Description
                            ELEMENT DisplayName $UserAccount.DisplayName
                            ELEMENT Group $UserAccount.Group
                            ELEMENT Name $UserAccount.Name
                        }
                    }
                }
            }
            ELEMENT FirstLogonCommands {

                if( $MyFields | where-object Tag -eq 'EnableTS' | where-object value -eq 'true' )
                {
                    write-verbose "Add PSRemoting"
                
                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description "Enable Remote Desktop Service"
                        ELEMENT Order "1"
                        ELEMENT CommandLine 'reg.exe add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0x00000000 /f'
                        ELEMENT RequiresUserInput $true.Tostring().ToLower() 
                    }

                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description "Open firewall for Remote Desktop"
                        ELEMENT Order "2"
                        ELEMENT CommandLine 'netsh.exe advfirewall firewall set rule group="remote desktop" new enable=Yes'
                        ELEMENT RequiresUserInput $true.Tostring().ToLower() 
                    }

                }

                $NewExecutionPolicy = $MyFields | where-object Tag -eq 'ExecutionPolicy' | Select-Object -ExpandProperty Value -first 1
                if( $NewExecutionPolicy -in 'AllSigned','RemoteSigned','Unrestricted','Bypass' )
                {
                    write-verbose "Add PSRemoting"

                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description "Set powershell execution policy to remote signed (32-bit)"
                        ELEMENT Order "3"
                        ELEMENT CommandLine "reg.exe add HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell /v ExecutionPolicy /d $NewExecutionPolicy /f /reg:32"
                        ELEMENT RequiresUserInput $true.Tostring().ToLower() 
                    }

                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description "Set powershell execution policy to remote signed (64-bit)"
                        ELEMENT Order "4"
                        ELEMENT CommandLine "reg.exe add HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell /v ExecutionPolicy /d $NewExecutionPolicy /f /reg:64"
                        ELEMENT RequiresUserInput $true.Tostring().ToLower() 
                    }

                }

                if( $MyFields | where-object Tag -eq 'PSRemoting' | where-object value -eq 'true' )
                {

                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description "Enable-PSRemoting"
                        ELEMENT Order "5"
                        ELEMENT CommandLine 'powershell.exe -command "echo 'Enable-PSRemoting'; Enable-PSRemoting -force"'
                        ELEMENT RequiresUserInput $true.Tostring().ToLower() 
                    }

                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description "set trustedhosts to ALL (less secure)"
                        ELEMENT Order "6"
                        ELEMENT CommandLine 'powershell.exe -command "echo 'set trustedhosts'; Set-Item wsman:localhost\client\trustedhosts -Value * -force"'
                        ELEMENT RequiresUserInput $true.Tostring().ToLower() 
                    }

                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description "winrm quick config"
                        ELEMENT Order "7"
                        ELEMENT CommandLine "cmd.exe /c winrm.cmd quickconfig -transport:HTTP -force"
                        ELEMENT RequiresUserInput $true.Tostring().ToLower() 
                    }

                }

                $AdditionalCmd = Get-PropValue 'AdditionalPS1'
                if( $AdditionalCmd )
                {
                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description "Run Additional Commands"
                        ELEMENT Order "8"
                        ELEMENT CommandLine "powershell -executionpolicy RemoteSigned ""Start-Transcript; echo 'remote script'; iwr '$AdditionalCmd' -UseBasicParsing | iex"""
                        ELEMENT RequiresUserInput $true.Tostring().ToLower() 
                    }
                }

                $script:i = 10
                foreach ( $Command in $ExtraCommands ) {
                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description $Command.Description
                        ELEMENT Order ($script:i++).ToString()
                        ELEMENT CommandLine $Command.Path
                        ELEMENT RequiresUserInput $False.Tostring().ToLower() 
                    }
                }

                ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                    ELEMENT Description "Finished"
                    ELEMENT Order "999"
                    ELEMENT CommandLine "cmd.exe /c ""echo reboot & shutdown -r -f -t 10"""
                    ELEMENT RequiresUserInput $true.Tostring().ToLower() 
                }


            }

        }
        COMPONENT Microsoft-Windows-International-Core {
            ELEMENT InputLocale   (Get-PropValue 'SystemLocale')
            ELEMENT SystemLocale  (Get-PropValue 'SystemLocale')
            ELEMENT UILanguage    (Get-PropValue 'SystemLocale')
            ELEMENT UserLocale    (Get-PropValue 'SystemLocale')
        }
    }

    write-verbose "WindowsPE"
    SETTINGS windowsPE {

        COMPONENT Microsoft-Windows-International-Core-WinPE {
            ELEMENT SetupUILanguage {
                ELEMENT UILanguage   (Get-PropValue 'SystemLocale')
            }
            ELEMENT InputLocale   (Get-PropValue 'SystemLocale')
            ELEMENT SystemLocale  (Get-PropValue 'SystemLocale')
            ELEMENT UILanguage    (Get-PropValue 'SystemLocale')
            ELEMENT UILanguageFallback    (Get-PropValue 'SystemLocale')
            ELEMENT UserLocale    (Get-PropValue 'SystemLocale')

        }

        COMPONENT Microsoft-Windows-Setup {
            if ( $Target -eq 'ISO' ) 
            {
                ELEMENT DiskConfiguration {
                    ELEMENT Disk -TypeAdd {
                        ELEMENT CreatePartitions {
                            ELEMENT CreatePartition -TypeAdd -ForceNew {
                                ELEMENT Order "1"
                                ELEMENT Size "450"
                                ELEMENT Type "EFI"
                            } 
                            ELEMENT CreatePartition -TypeAdd -ForceNew {
                                ELEMENT Order "2"
                                ELEMENT Size "128"
                                ELEMENT Type "MSR"
                            } 
                            ELEMENT CreatePartition -TypeAdd -ForceNew {
                                ELEMENT Order "3"
                                ELEMENT Extend $true.toString().ToLower()
                                ELEMENT Type "Primary"
                            } 
                        }
                        ELEMENT DiskID "0"
                        ELEMENT WillWipeDisk $true.ToString().ToLower()
                    }
                }
                ELEMENT ImageInstall {
                    ELEMENT OSImage {
                        ELEMENT InstallFrom {
                            ELEMENT MetaData -TypeAdd {
                                ELEMENT Key "/image/index"
                                ELEMENT Value $Index.Tostring()
                            }
                        }
                        ELEMENT InstallToAvailablePartition $true.ToString().TOlower()
                        ELEMENT WillShowUI "OnError"
                    }
                }
            }
            ELEMENT UserData {
                ELEMENT AcceptEula $true.ToString().ToLower()
                if ( $isRetail )
                {
                    ELEMENT ProductKey {
                        ELEMENT Key ""
                        ELEMENT WillShowUI "OnError" 
                    }
                }
            }
        }
        
    }


}  | Save-XMLFile -path $env:temp\NewISO\AutoUnattend.xml

#endregion

#region Prepare Disk
###########################################################

if ( $Target -eq 'USB' )
{

    $Host.UI.RawUI.WindowTitle = "Select Target USB"

    $TargetDisk = Get-Disk | where-object bustype -eq 'usb' | Select-Object -Property DiskNumber,PartitionStyle,OperationalStatus,@{Name="Total Size"; Expression = { ($_.Size / 1gb).ToString("0.00") }},FriendlyName,SerialNumber | out-gridview -OutputMode Single

    if ( -not $TargetDisk ) 
    {
        throw "Missing Target Disk!"
    }

    if ( $TargetDisk | Get-Partition  | where-object type -in 'IFS','NTFS' )
    {
        throw "Target Disk not Fat32"

        <#

        # Initialize disk if not already initialized
        get-disk -Number $disk | where-object PartitionStyle -ne 'MBR' | initialize-disk -PartitionStyle MBR

        write-verbose "Clear-disk $Disk"
        Clear-Disk -Number $disk -RemoveData -RemoveOEM -Confirm:$Confirm

        # Initialize disk if not already initialized (again)
        get-disk -Number $disk | where-object PartitionStyle -ne 'MBR' | initialize-disk -PartitionStyle MBR

        # turn off shell hardware detection 
        $ShellHWDetection = get-Service -Name ShellHWDetection
        if ( $ShellHWDetection.Status -eq 'Running' ) { Stop-service -name ShellHWDetection }

        write-verbose "Create main partition"
        $System = New-Partition -DiskNumber $Disk -IsActive -UseMaximumSize -AssignDriveLetter -MbrType fat32 |
            Format-Volume -FileSystem FAT32 -force -NewFileSystemLabel "System"  -Confirm:$Confirm 

        # turn on shell hardware detection if turned off 
        if ( $ShellHWDetection.Status -eq 'Running' ) { Start-service -name ShellHWDetection }

        #>

    }

    $System = $TargetDisk | get-partition | get-volume | Select-Object -First 1

}

#endregion

#region Copy Bits
###########################################################

if ( $Target -eq 'USB' )
{

    if ( $ImagePath -and $system ) 
    {
        write-verbose "copy sources"
        copy-itemwithprogress /max:4294967295 /e $ImagePath\  "$($System.DriveLetter)`:\" | out-string |write-verbose 

        if ( -not ( test-path "$($System.DriveLetter)`:\sources\install.wim" ) ) 
        {
            write-verbose "Split WIMs $($ImagePath)\sources\install.wim   $($System.DriveLetter)`:\Sources\Install.swm "
            $LogPath = Get-NewDismArgs
            push-location "$($System.DriveLetter)`:\Sources"
            dism.exe /split-image /ImageFile:$($ImagePath)\sources\install.wim  /SWMFile:Install.swm /FileSize:4095 /logpath:$($LogPath.LogPath) | out-string | write-verbose
            pop-location
        }
    }

    copy-item $env:temp\NewISO\AutoUnattend.xml "$($System.DriveLetter)`:\AutoUnattend.xml" -Force

}

#endregion

#region Create ISO
###########################################################

if ( $Target -eq 'ISO' )
{

    new-isoimage -SourcePath $env:temp\NewISO -ISOTarget $env:temp\NewFile.iso 

}

#endregion


#region Hyper-V Management
###########################################################


#endregion

<#


Create and mount VHD file, or find USB Drive --> partition and format.
Apply WIM file to volume
* Integrate latest cumulnitiave update?

#>
