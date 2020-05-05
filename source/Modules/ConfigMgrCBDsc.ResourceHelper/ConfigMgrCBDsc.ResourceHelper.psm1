# Localized messages
data LocalizedData
{
    # Culture="en-US"
    ConvertFrom-StringData -StringData @'
    ModuleNotFound = Please ensure that the PowerShell module for role {0} is installed.
'@
}

<#
    .SYNOPSIS
        Import Configuration Manager module commands.

    .PARAMTER SiteCode
        Specifies the site code for configuration manager.
#>
function Import-ConfigMgrPowerShellModule
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode
    )

    if ((Test-Path -Path "$($SiteCode):\") -eq $false)
    {
        $siteInfo = Get-CimInstance -ClassName SMS_Site -Namespace root\sms\site_$SiteCode
        $sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $baseRegKeyPath = "Registry::HKEY_Users\$sid\Software\Microsoft"
        $createKeys = @('ConfigMgr10','AdminUI','MRU','1')

        foreach ($key in $createKeys)
        {
            if (-not (Test-Path -Path "$baseRegKeyPath\$key"))
            {
                New-Item -Path $baseRegKeyPath -Name $key |Out-Null
                $baseRegKeyPath += "\$key"
            }
        }

        $regProperties = (Get-ItemProperty -Path $baseRegKeyPath -ErrorAction SilentlyContinue)

        $values = @{
            ServerName = $siteInfo.ServerName[0]
            SiteName   = $siteInfo.SiteName[0]
            SiteCode   = $siteInfo.SiteCode[0]
            DomainName = ($siteinfo.ServerName.SubString($siteinfo.ServerName.Indexof('.') + 1))[0]
        }

        foreach ($value in $values.GetEnumerator())
        {
            if ($($regProperties.$($value.Name)) -ne $value.Value)
            {
                Set-ItemProperty -Path $baseRegKeyPath -Name $value.Name -Value $value.Value | Out-Null
            }
        }

        Set-ConfigmgrCert

        try
        {
            Import-Module -Name (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Global
        }
        catch
        {
            throw "Failure to import SCCM Cmdlets."
        }
    }

    if ((Get-Module -Name ConfigurationManager).Version -lt '5.1902')
    {
        throw "Incorrect version of Configuration Manager Powershell to use this module"
    }
}

<#
    .SYNOPSIS
        Imports the configuration manager powershell certificate to Trusted Publisher.
#>
function Set-ConfigMgrCert
{
    param ()

    $configCert = Get-AuthenticodeSignature -FilePath (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)

    $store = Get-Item -Path Cert:\LocalMachine\TrustedPublisher
    $store.Open('ReadWrite')

    if ($store.Certificates -notcontains $configCert.SignerCertificate)
    {
        $store.Add($configCert.SignerCertificate)
    }

    $store.Close()
}

<#
    .SYNOPSIS
        Validates the Setting resides in the Device Settings category.

    .PARAMETER DeviceSettingName
        Specifies the parent setting category.

    .PARAMETER Setting
        Specifies the client setting to validate.
#>
function Confirm-ClientSetting
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $DeviceSettingName,

        [Parameter(Mandatory = $true)]
        [String]
        $Setting
    )

    $softwareUpdatesValue = @(
        'SC_Old_Branding'
        'AvailableSoftware'
        'Updates'
        'OSD'
        'InstallationStatus'
        'Compliance'
        'Options'
        'unapproved-applications-hidden'
        'installed-applications-hidden'
        'custom-tab-name'
        'custom-tab-content'
        'brand-logo'
        'brand-orgname'
        'brand-color'
        'application-catalog-link-hidden'
    )

    if ($DeviceSettingName -ne 'SoftwareCenter')
    {
        $validateSetting = Get-CMClientSetting -Setting $DeviceSettingName | Select-Object -Property Keys
        if ($validateSetting[0].keys -notcontains $Setting)
        {
            Set-Location -Path $env:windir
            throw "The setting: $Setting does not exist under $DeviceSettingName"
        }
    }
    else
    {
        if ($softwareUpdatesValue -notcontains $Setting)
        {
            Set-Location -Path $env:windir
            throw "The setting: $Setting does not exist under $DeviceSettingName"
        }
    }
}

<#
    .SYNOPSIS
        Creates the assoicated settings command for setting the client settings.

    .PARAMETER DeviceSettingName
        Specifies the parent setting category.

    .PARAMETER Setting
        Specifies the client setting to validate.
#>
function Convert-ClientSetting
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $DeviceSettingName,

        [Parameter(Mandatory = $true)]
        [String]
        $Setting
    )

    if ($DeviceSettingName -eq 'BackgroundIntelligentTransfer')
    {
        $result = switch ($Setting)
        {
            'MaxBandwidthValidFrom' { 'MaxBandwidthBeginHr' }
            'MaxBandwidthValidTo'   { 'MaxBandwidthEndHr'   }
            default                 { $Setting              }
        }
    }

    if ($DeviceSettingName -eq 'ClientCache')
    {
        $result = switch ($Setting)
        {
            'BranchCacheEnabled' { 'EnableBranchCache' }
            'MaxCacheSizeMB'     { 'MaxCacheSize'      }
            'CanBeSuperPeer'     { 'EnableSuperPeer'   }
            'HttpPort'           { 'DownloadPort'      }
            default              { $Setting            }
        }
    }

    if ($DeviceSettingName -eq 'ClientPolicy')
    {
        $result = switch ($Setting)
        {
            'PolicyRequestAssignmentTimeout'   { 'PolicyPollingMins'          }
            'PolicyEnableUserPolicyPolling'    { 'EnableUserPolicy'           }
            'PolicyEnableUserPolicyOnInternet' { 'EnableUserPolicyOnInternet' }
            default                            { $Setting                     }
        }
    }

    if ($DeviceSettingName -eq 'Cloud')
    {
        $result = switch ($Setting)
        {
            'AllowCloudDP' { 'AllowCloudDistributionPoint' }
            'AutoAADJoin'  { 'AutoAzureADJoin'             }
            'AllowCMG'     { 'AllowCloudManagementGateway' }
            default        { $Setting                      }
        }
    }

    if ($DeviceSettingName -eq 'ComplianceSettings')
    {
        $result = switch ($Setting)
        {
            'EvaluationSchedule'        { 'Schedule'                 }
            'EnableUserStateManagement' { 'EnableUserDataAndProfile' }
            default                     { $Setting                   }
        }
    }

    if ($DeviceSettingName -eq 'ComputerAgent')
    {
        $result = switch ($Setting)
        {
            'ReminderInterval'     { 'InitialReminderHr'              }
            'DayReminderInterval'  { 'InterimReminderHr'              }
            'HourReminderInterval' { 'FinalReminderMins'              }
            'UseOnPremHAService'   { 'UseOnPremisesHealthAttestation' }
            'OnPremHAServiceUrl'   { 'HealthAttestationUrl'           }
            default                { $Setting                         }
        }
    }

    if ($DeviceSettingName -eq 'ComputerRestart')
    {
        $result = switch ($Setting)
        {
            'RebootLogoffNotificationCountdownDuration' { 'CountdownMins'                      }
            'RebootLogoffNotificationFinalWindow'       { 'FinalWindowMins'                    }
            'RebootNotificationsDialog'                 { 'ReplaceToastNotificationWithDialog' }
            default                                     { $Setting                             }
        }
    }

    if ($DeviceSettingName -eq 'DeliveryOptimization')
    {
        $result = switch ($Setting)
        {
            'EnableWindowsDO' { 'Enable' }
            default           { $Setting }
        }
    }

    if ($DeviceSettingName -eq 'EndPointProtection')
    {
        $result = switch ($Setting)
        {
            'EnableEP'          { 'Enable'                          }
            'InstallSCEPClient' { 'InstallEndpointProtectionClient' }
            'ForceRebootPeriod' { 'ForceRebootHr'                   }
            default             { $Setting                          }
        }
    }

    if ($DeviceSettingName -eq 'HardwareInventory')
    {
        $result = switch ($Setting)
        {
            'Max3rdPartyMIFSize' { 'MaxThirdPartyMifSize' }
            default              { $Setting               }
        }
    }

    if ($DeviceSettingName -eq 'MeteredNetwork')
    {
        $result = $Setting
    }

    if ($DeviceSettingName -eq 'MobileDevice')
    {
        $result = switch ($Setting)
        {
            'EnableDeviceEnrollment'          { 'EnableDevice'                }
            'EnableDevice'                    { 'EnableModernDevice'          }
            'DeviceEnrollmentProfileID'       { 'EnrollmentProfileName'       }
            'ModernDeviceEnrollmentProfileID' { 'ModernEnrollmentProfileName' }
            'MDMPollInterval'                 { 'IntervalModernMins'          }
            default                           { $Setting                      }
        }
    }

    if ($DeviceSettingName -eq 'PowerManagement')
    {
        $result = switch ($Setting)
        {
            'Enabled'                           { 'EnablePowerManagement'           }
            'Port'                              { 'WakeupProxyPort'                 }
            'WolPort'                           { 'WakeOnLanPort'                   }
            'WakeupProxyFirewallFlags'          { 'FirewallExceptionForWakeupProxy' }
            'WakeupProxyDirectAccessPrefixList' { 'WakeupProxyDirectAccessPrefix'   }
            default                             { $Setting                          }
        }
    }

    if ($DeviceSettingName -eq 'RemoteTools')
    {
        $result = switch ($Setting)
        {
            'FirewallExceptionProfiles'         { 'FirewallExceptionProfile'            }
            'AllowRemCtrlToUnattended'          { 'AllowUnattendedComputer'             }
            'PermissionRequired'                { 'PromptUserForPermission'             }
            'ClipboardAccessPermissionRequired' { 'PromptUserForClipboardPermission'    }
            'AllowLocalAdminToDoRemoteControl'  { 'GrantPermissionToLocalAdministrator' }
            'PermittedViewers'                  { 'PermittedViewer'                     }
            'RemCtrlTaskbarIcon'                { 'ShowNotificationIconOnTaskbar'       }
            'RemCtrlConnectionBar'              { 'ShowSessionConnectionBar'            }
            'ManageRA'                          { 'ManageUnsolicitedRemoteAssistance'   }
            'EnforceRAandTSSettings'            { 'ManageSolicitedRemoteAssistance'     }
            'ManageTS'                          { 'ManageRemoteDesktopSetting'          }
            'EnableTS'                          { 'AllowPermittedViewer'                }
            'TSUserAuthentication'              { 'RequireAuthentication'               }
            default                             { $Setting                              }
        }
    }

    if ($DeviceSettingName -eq 'SoftwareCenter')
    {
        $result = switch ($Setting)
        {
            'SC_Old_Branding'                 { 'EnableCustomize'            }
            'brand-orgname'                   { 'CompanyName'                }
            'brand-color'                     { 'ColorScheme'                }
            'brand-logo'                      { 'LogoFilePath'               }
            'unapproved-applications-hidden'  { 'HideUnapprovedApplication'  }
            'installed-applications-hidden'   { 'HideInstalledApplication'   }
            'application-catalog-link-hidden' { 'HideApplicationCatalogLink' }
            'AvailableSoftware'               { 'EnableApplicationsTab'      }
            'Updates'                         { 'EnableUpdatesTab'           }
            'OSD'                             { 'EnableOperatingSystemsTab'  }
            'InstallationStatus'              { 'EnableStatusTab'            }
            'Compliance'                      { 'EnableComplianceTab'        }
            'Options'                         { 'EnableOptionsTab'           }
            'custom-tab-name'                 { 'CustomTabName'              }
            'custom-tab-content'              { 'CustomTabUrl'               }
            default                           { $Setting                     }
        }
    }

    if ($DeviceSettingName -eq 'SoftwareDeployment')
    {
        $result = switch ($Setting)
        {
            'EvaluationSchedule' { 'Schedule' }
            default              { $Setting   }
        }
    }

    if ($DeviceSettingName -eq 'SoftwareMetering')
    {
        $result = switch ($Setting)
        {
            'Enabled'                { 'Enable'   }
            'DataCollectionSchedule' { 'Schedule' }
            default                  { $Setting   }
        }
    }

    if ($DeviceSettingName -eq 'SoftwareUpdates')
    {
        $result = switch ($Setting)
        {
            'Enabled'                   { 'Enable'                       }
            'EvaluationSchedule'        { 'DeploymentEvaluationSchedule' }
            'AssignmentBatchingTimeout' { 'BatchingTimeout'              }
            'O365Management'            { 'Office365ManagementType'      }
            default                     { $Setting                       }
        }
    }

    if ($DeviceSettingName -eq 'StateMessaging')
    {
        $result = switch ($Setting)
        {
            'BulkSendInterval' { 'ReportingCycleMins' }
            default            { $Setting             }
        }
    }

    if ($DeviceSettingName -eq 'UserAndDeviceAffinity')
    {
        $result = switch ($Setting)
        {
            'ConsoleMinutes' { 'LogOnThresholdMins' }
            'IntervalDays'   { 'UsageThresholdDays' }
            default          { $Setting             }
        }
    }

    if ($DeviceSettingName -eq 'WindowsAnalytics')
    {
        $result = switch ($Setting)
        {
            'WAEnable'         { 'Enable'                 }
            'WACommercialID'   { 'CommercialIdKey'        }
            'WATelLevel'       { 'Win10Telemetry'         }
            'WAOptInDownlevel' { 'EnableEarlierTelemetry' }
            'WAIEOptInlevel'   { 'IEDataCollectionOption' }
            default            { $Setting                 }
        }
    }

    $result
}

<#
    .SYNOPSIS
        Validates the Setting residing in the SoftwareCenter category.

    .PARAMETER Name
        Specifies the display name of the client setting package.

    .PARAMETER Setting
        Specifies the client setting to validate.
#>
function Get-ClientSettingsSoftwareCenter
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('SC_Old_Branding','AvailableSoftware','Updates','OSD','InstallationStatus','Compliance','Options','unapproved-applications-hidden',
        'installed-applications-hidden','custom-tab-name','custom-tab-content','brand-logo','brand-orgname','brand-color','application-catalog-link-hidden')]
        [String]
        $Setting
    )

    $settings = Get-CMClientSetting -Name $Name -Setting 'SoftwareCenter'

    $tabVisibility = @(
        'AvailableSoftware'
        'Updates'
        'OSD'
        'InstallationStatus'
        'Compliance'
        'Options'
    )

    $hidden = @(
        'unapproved-applications-hidden'
        'installed-applications-hidden'
    )

    $tabCustom = @(
        'custom-tab-name'
        'custom-tab-content'
    )

    $additionalSettings = @(
        'brand-logo'
        'brand-orgname'
        'brand-color'
        'application-catalog-link-hidden'
    )

    $xml = [xml]$settings.SettingsXml

    if ($Setting -eq 'SC_Old_Branding')
    {
        return $settings.SC_Old_Branding
    }
    elseif ($tabVisibility -contains $Setting)
    {
        $validateTab = $xml.settings.'tab-visibility'.tab

        foreach ($item in $validateTab)
        {
            if ($item.name -eq $Setting)
            {
                return $item.visible
            }
        }
    }
    elseif ($hidden -contains $Setting)
    {
        return $xml.settings.'software-list'.$($Setting)
    }
    elseif ($tabCustom -contains $Setting)
    {
        return $xml.settings.'custom-tab'.$($Setting)
    }
    elseif ($additionalSettings -contains $Setting)
    {
        return $xml.settings.$($Setting)
    }
}

function Convert-CidrToIP
{
    [CmdLetBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [IPAddress]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0,32)]
        [Int32]
        $Cidr
    )

    $CidrBits = ('1' * $Cidr).PadRight(32, '0')
    $octets = $CidrBits -Split '(.{8})' -ne ''
    $mask = ($octets | ForEach-Object -Process {[Convert]::ToInt32($_, 2) }) -Join '.'

    $ip = [IPAddress](([IPAddress]"$IPAddress").Address -Band ([IPAddress]"$mask").Address)

    return  @{
        NetworkAddress = $ip.IPAddressToString
        Subnetmask     = $mask
        Cidr           = $Cidr
    }
}

Export-ModuleMember -Function @(
    'Get-LocalizedData',
    'New-InvalidArgumentException',
    'Import-ConfigMgrPowerShellModule'
    'Confirm-ClientSetting'
    'Convert-ClientSetting'
    'Get-ClientSettingsSoftwareCenter'
    'Convert-CidrToIP'
)
