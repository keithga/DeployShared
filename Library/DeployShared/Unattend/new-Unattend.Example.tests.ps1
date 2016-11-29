<#

Pester tests for unattend.xml files

#>

. $PSScriptRoot\New-Unattend.ps1

UNATTEND  {
    SETTINGS specialize  {
        COMPONENT Microsoft-Windows-Shell-Setup {
            ELEMENT TimeZone [System.Timezone]::CurrentTimezone.StandardName
            ELEMENT RegisteredOrganization (Get-ItemPropertyValue -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name RegisteredOrganization)
            ELELENT RegisteredOwner (Get-ItemPropertyValue -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name RegisteredOwner)
            ELEMENT ComputerName "*"
        }
        if ( $False ) {
            COMPONENT Microsoft-Windows-UnattendedJoin {
                ELEMENT Identification {
                    ELEMENT Credentials {
                        ELEMENT Domain "contoso.com"
                        ELEMENT Password "P@ssw0rd"
                        ELEMENT Username "MyUserName"
                    }       
                    ELEMENT JoinDomain "Contoso.com"
                }
            }
        }
    }

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
            ELEMENT UserAccounts {
                PASSWORD "AdministratorPassword" "P@ssw0rd"
                ELEMENT LocalAccounts {
                    foreach ( $UserAccount in $UserAccounts ) 
                    {
                        ELEMENT LocalAccount -TypeAdd { 
                            PASSWORD "Password" $UserAccount.Password
                            ELEMENT Description $UserAccount.Description
                            ELEMENT DisplayName $UserAccount.DisplayName
                            ELEMENT Group $UserAccount.Group
                            ELEMENT Name $UserAccount.Name
                        }
                    }
                }
                ELEMENT DomainAccounts {
                    foreach ( $DomainAccount in $DomainAccounts ) {
                        ELEMENT Domain ""
                    }
                }
            }
            ELEMENT FirstLogonCommands {
                $Order = 1
                foreach ( $Command in $FirstLogonCommands ) {
                    ELEMENT SynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description $Command.Description
                        ELEMENT Order $Order++
                        ELEMENT CommandLine $Command.Path
                        # ELEMENT RequiresUserInput $False.Tostring().ToLower() 
                    }
                }
            }
            ELEMENT LogonCommands {
                $Order = 1
                foreach ( $Command in $AsynchronousCommand ) {
                    ELEMENT AsynchronousCommand -TypeAdd -ForceNew {
                        ELEMENT Description $Command.Description
                        ELEMENT Order $Order++
                        ELEMENT Path $Command.Path
                    }
                }
            }
        }
        COMPONENT Microsoft-Windows-International-Core {
            # Get values from host
            ELEMENT InputLocale   (Get-WinUserLanguageList).InputMethodTips
            ELEMENT SystemLocale  (Get-WinUserLanguageList).LanguageTag
            ELEMENT UILanguage    (Get-WinUserLanguageList).LanguageTag
            ELEMENT UserLocale    (Get-WinUserLanguageList).LanguageTag
        }
    }

    SETTINGS Specialize { COMPONENT Microsoft-Windows-IE-ESC { ELEMENT IEHardenAdmin "false" } }
    SETTINGS Specialize { COMPONENT Microsoft-Windows-IE-ESC { ELEMENT IEHardenUser  "false" } }

}  

@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
       <component name="Microsoft-Windows-IE-ESC" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <IEHardenAdmin>false</IEHardenAdmin>
         <IEHardenUser>false</IEHardenUser>
       </component>
       <component name="Microsoft-Windows-IE-InternetExplorer" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <Home_Page>about:tab</Home_Page>
       </component>
    </settings>

</unattend>
"@
