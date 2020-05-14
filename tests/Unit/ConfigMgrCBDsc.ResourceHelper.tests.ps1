[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)"

Import-Module $script:subModuleFile -Force -ErrorAction 'Stop'

InModuleScope $script:subModuleName {

    $moduleResourceName = 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper'

    $moduleVersionGood = @{
        Name    = 'ConfgurationManager'
        Version = '5.1902'
    }

    $moduleVersionBad = @{
        Name    = 'ConfgurationManager'
        Version = '5.1802'
    }

    $ENV:SMS_ADMIN_UI_PATH = 'test'

    $confirmSettingsParamGood = @{
        DeviceSettingName = 'Bits'
        Setting           = 'Setting1'
    }

    $confirmSettingsParamBad = @{
        DeviceSettingName = 'Bits'
        Setting           = 'Setting3'
    }

    $confirmSettingsParamSoftwareCenter = @{
        DeviceSettingName = 'SoftwareCenter'
        Setting           = 'Setting3'
    }

    $siteCim = @{
        ServerName = 'Test.contoso.com'
        SiteCode   = 'Lab'
        SiteName   = 'Lab'
        Version    = '5.00.8790.1000'
    }

    Describe "$moduleResourceName\Import-ConfigMgrPowerShellModule" {

        Context 'When importing the module' {
            Mock -CommandName Join-Path -MockWith { 'C:\' }
            Mock -CommandName Split-Path -MockWith { 'C:\' }
            Mock -CommandName Import-Module
            Mock -CommandName Get-CimInstance -MockWith { $siteCim }
            Mock -CommandName Set-ItemProperty
            Mock -CommandName New-Item
            Mock -CommandName Set-ConfigMgrCert
            Mock -CommandName Get-ItemProperty
            Mock -CommandName Test-Path

            It 'Should call expected commands' {
                Mock -CommandName Get-Module -MockWith { $moduleVersionGood }
                Mock -CommandName Test-Path -MockWith { $false }
                Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $Path -eq 'Lab:\'  }

                Import-ConfigMgrPowerShellModule -SiteCode 'Lab'
                Assert-MockCalled Import-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled Join-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Split-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
                Assert-MockCalled New-Item -Exactly -Times 4 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 5 -Scope It
                Assert-MockCalled Set-ItemProperty -Exactly -Times 4 -Scope It
                Assert-MockCalled Set-ConfigMgrCert -Exactly -Times 1 -Scope It
            }

            It 'Should throw when module version is lower than expected' {
                Mock -CommandName Get-Module -MockWith { $moduleVersionBad }
                Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $Path -eq 'Lab:\' }

                { Import-ConfigMgrPowerShellModule -SiteCode 'Lab' } | Should -Throw
                Assert-MockCalled Import-Module -Exactly -Times 0 -Scope It
                Assert-MockCalled Join-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Split-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-ItemProperty -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-ItemProperty -Exactly -Times 0 -Scope It
                Assert-MockCalled Set-ConfigMgrCert -Exactly -Times 0 -Scope It
            }

            It 'Should throw on Module import' {
                Mock -CommandName Import-Module -MockWith { throw 'bad' }
                Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $Path -eq 'Lab:\'  }

                { Import-ConfigMgrPowerShellModule -SiteCode 'Lab' } | Should -Throw
                Assert-MockCalled Import-Module -Exactly -Times 1 -Scope It
                Assert-MockCalled Join-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Split-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-Module -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CimInstance -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
                Assert-MockCalled New-Item -Exactly -Times 4 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 5 -Scope It
                Assert-MockCalled Set-ItemProperty -Exactly -Times 4 -Scope It
                Assert-MockCalled Set-ConfigMgrCert -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe "$moduleResourceName\Confirm-ClientSetting" {

        Context 'When importing the module' {
            Mock -CommandName Get-CMClientSetting -MockWith { [PSCustomObject]@{ Keys = 'Setting1' } }
            Mock -CommandName Set-Location

            It 'Should call expected commands' {
                Confirm-ClientSetting @confirmSettingsParamGood
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 0 -Scope It
            }

            It 'Should call expected commands' {
                { Confirm-ClientSetting @confirmSettingsParamBad } | Should -Throw
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 1 -Scope It
            }

            It 'Should call expected commands' {
                { Confirm-ClientSetting @confirmSettingsParamSoftwareCenter } | Should -Throw
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe "$moduleResourceName\Convert-ClientSetting" {

        Context 'When return is as expected' {

            $convertItems = @{
                Items = @(
                    @{
                        DeviceSetting     = 'BackgroundIntelligentTransfer'
                        Setting           = 'MaxBandwidthValidFrom'
                        Result            = 'MaxBandwidthBeginHr'
                    }
                    @{
                        DeviceSetting     = 'BackgroundIntelligentTransfer'
                        Setting           = 'MaxBandwidthValidTo'
                        Result            = 'MaxBandwidthEndHr'
                    }
                    @{
                        DeviceSetting     = 'BackgroundIntelligentTransfer'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'ClientCache'
                        Setting           = 'BranchCacheEnabled'
                        Result            = 'EnableBranchCache'
                    }
                    @{
                        DeviceSetting     = 'ClientCache'
                        Setting           = 'MaxCacheSizeMB'
                        Result            = 'MaxCacheSize'
                    }
                    @{
                        DeviceSetting     = 'ClientCache'
                        Setting           = 'CanBeSuperPeer'
                        Result            = 'EnableSuperPeer'
                    }
                    @{
                        DeviceSetting     = 'ClientCache'
                        Setting           = 'HttpPort'
                        Result            = 'DownloadPort'
                    }
                    @{
                        DeviceSetting     = 'ClientCache'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'ClientPolicy'
                        Setting           = 'PolicyRequestAssignmentTimeout'
                        Result            = 'PolicyPollingMins'
                    }
                    @{
                        DeviceSetting     = 'ClientPolicy'
                        Setting           = 'PolicyEnableUserPolicyPolling'
                        Result            = 'EnableUserPolicy'
                    }
                    @{
                        DeviceSetting     = 'ClientPolicy'
                        Setting           = 'PolicyEnableUserPolicyOnInternet'
                        Result            = 'EnableUserPolicyOnInternet'
                    }
                    @{
                        DeviceSetting     = 'ClientPolicy'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'Cloud'
                        Setting           = 'AllowCloudDP'
                        Result            = 'AllowCloudDistributionPoint'
                    }
                    @{
                        DeviceSetting     = 'Cloud'
                        Setting           = 'AutoAADJoin'
                        Result            = 'AutoAzureADJoin'
                    }
                    @{
                        DeviceSetting     = 'Cloud'
                        Setting           = 'AllowCMG'
                        Result            = 'AllowCloudManagementGateway'
                    }
                    @{
                        DeviceSetting     = 'Cloud'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'ComplianceSettings'
                        Setting           = 'EvaluationSchedule'
                        Result            = 'Schedule'
                    }
                    @{
                        DeviceSetting     = 'ComplianceSettings'
                        Setting           = 'EnableUserStateManagement'
                        Result            = 'EnableUserDataAndProfile'
                    }
                    @{
                        DeviceSetting     = 'ComplianceSettings'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'ComputerAgent'
                        Setting           = 'ReminderInterval'
                        Result            = 'InitialReminderHr'
                    }
                    @{
                        DeviceSetting     = 'ComputerAgent'
                        Setting           = 'DayReminderInterval'
                        Result            = 'InterimReminderHr'
                    }
                    @{
                        DeviceSetting     = 'ComputerAgent'
                        Setting           = 'HourReminderInterval'
                        Result            = 'FinalReminderMins'
                    }
                    @{
                        DeviceSetting     = 'ComputerAgent'
                        Setting           = 'UseOnPremHAService'
                        Result            = 'UseOnPremisesHealthAttestation'
                    }
                    @{
                        DeviceSetting     = 'ComputerAgent'
                        Setting           = 'OnPremHAServiceUrl'
                        Result            = 'HealthAttestationUrl'
                    }
                    @{
                        DeviceSetting     = 'ComputerAgent'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'ComputerRestart'
                        Setting           = 'RebootLogoffNotificationCountdownDuration'
                        Result            = 'CountdownMins'
                    }
                    @{
                        DeviceSetting     = 'ComputerRestart'
                        Setting           = 'RebootLogoffNotificationFinalWindow'
                        Result            = 'FinalWindowMins'
                    }
                    @{
                        DeviceSetting     = 'ComputerRestart'
                        Setting           = 'RebootNotificationsDialog'
                        Result            = 'ReplaceToastNotificationWithDialog'
                    }
                    @{
                        DeviceSetting     = 'ComputerRestart'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'DeliveryOptimization'
                        Setting           = 'EnableWindowsDO'
                        Result            = 'Enable'
                    }
                    @{
                        DeviceSetting     = 'DeliveryOptimization'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'EndPointProtection'
                        Setting           = 'EnableEP'
                        Result            = 'Enable'
                    }
                    @{
                        DeviceSetting     = 'EndPointProtection'
                        Setting           = 'InstallSCEPClient'
                        Result            = 'InstallEndpointProtectionClient'
                    }
                    @{
                        DeviceSetting     = 'EndPointProtection'
                        Setting           = 'ForceRebootPeriod'
                        Result            = 'ForceRebootHr'
                    }
                    @{
                        DeviceSetting     = 'EndPointProtection'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'HardwareInventory'
                        Setting           = 'Max3rdPartyMIFSize'
                        Result            = 'MaxThirdPartyMifSize'
                    }
                    @{
                        DeviceSetting     = 'HardwareInventory'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'MeteredNetwork'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'MobileDevice'
                        Setting           = 'EnableDeviceEnrollment'
                        Result            = 'EnableDevice'
                    }
                    @{
                        DeviceSetting     = 'MobileDevice'
                        Setting           = 'EnableDevice'
                        Result            = 'EnableModernDevice'
                    }
                    @{
                        DeviceSetting     = 'MobileDevice'
                        Setting           = 'DeviceEnrollmentProfileID'
                        Result            = 'EnrollmentProfileName'
                    }
                    @{
                        DeviceSetting     = 'MobileDevice'
                        Setting           = 'ModernDeviceEnrollmentProfileID'
                        Result            = 'ModernEnrollmentProfileName'
                    }
                    @{
                        DeviceSetting     = 'MobileDevice'
                        Setting           = 'MDMPollInterval'
                        Result            = 'IntervalModernMins'
                    }
                    @{
                        DeviceSetting     = 'MobileDevice'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'PowerManagement'
                        Setting           = 'Enabled'
                        Result            = 'EnablePowerManagement'
                    }
                    @{
                        DeviceSetting     = 'PowerManagement'
                        Setting           = 'Port'
                        Result            = 'WakeupProxyPort'
                    }
                    @{
                        DeviceSetting     = 'PowerManagement'
                        Setting           = 'WolPort'
                        Result            = 'WakeOnLanPort'
                    }
                    @{
                        DeviceSetting     = 'PowerManagement'
                        Setting           = 'WakeupProxyFirewallFlags'
                        Result            = 'FirewallExceptionForWakeupProxy'
                    }
                    @{
                        DeviceSetting     = 'PowerManagement'
                        Setting           = 'WakeupProxyDirectAccessPrefixList'
                        Result            = 'WakeupProxyDirectAccessPrefix'
                    }
                    @{
                        DeviceSetting     = 'PowerManagement'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'FirewallExceptionProfiles'
                        Result            = 'FirewallExceptionProfile'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'AllowRemCtrlToUnattended'
                        Result            = 'AllowUnattendedComputer'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'PermissionRequired'
                        Result            = 'PromptUserForPermission'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'ClipboardAccessPermissionRequired'
                        Result            = 'PromptUserForClipboardPermission'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'AllowLocalAdminToDoRemoteControl'
                        Result            = 'GrantPermissionToLocalAdministrator'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'PermittedViewers'
                        Result            = 'PermittedViewer'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'RemCtrlTaskbarIcon'
                        Result            = 'ShowNotificationIconOnTaskbar'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'RemCtrlConnectionBar'
                        Result            = 'ShowSessionConnectionBar'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'ManageRA'
                        Result            = 'ManageUnsolicitedRemoteAssistance'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'EnforceRAandTSSettings'
                        Result            = 'ManageSolicitedRemoteAssistance'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'ManageTS'
                        Result            = 'ManageRemoteDesktopSetting'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'EnableTS'
                        Result            = 'AllowPermittedViewer'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'TSUserAuthentication'
                        Result            = 'RequireAuthentication'
                    }
                    @{
                        DeviceSetting     = 'RemoteTools'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'SC_Old_Branding'
                        Result            = 'EnableCustomize'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'brand-orgname'
                        Result            = 'CompanyName'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'brand-color'
                        Result            = 'ColorScheme'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'brand-logo'
                        Result            = 'LogoFilePath'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'unapproved-applications-hidden'
                        Result            = 'HideUnapprovedApplication'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'installed-applications-hidden'
                        Result            = 'HideInstalledApplication'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'application-catalog-link-hidden'
                        Result            = 'HideApplicationCatalogLink'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'AvailableSoftware'
                        Result            = 'EnableApplicationsTab'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'Updates'
                        Result            = 'EnableUpdatesTab'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'OSD'
                        Result            = 'EnableOperatingSystemsTab'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'InstallationStatus'
                        Result            = 'EnableStatusTab'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'Compliance'
                        Result            = 'EnableComplianceTab'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'Options'
                        Result            = 'EnableOptionsTab'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'custom-tab-name'
                        Result            = 'CustomTabName'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'custom-tab-content'
                        Result            = 'CustomTabUrl'
                    }
                    @{
                        DeviceSetting     = 'SoftwareCenter'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'SoftwareDeployment'
                        Setting           = 'EvaluationSchedule'
                        Result            = 'Schedule'
                    }
                    @{
                        DeviceSetting     = 'SoftwareDeployment'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'SoftwareMetering'
                        Setting           = 'Enabled'
                        Result            = 'Enable'
                    }
                    @{
                        DeviceSetting     = 'SoftwareMetering'
                        Setting           = 'DataCollectionSchedule'
                        Result            = 'Schedule'
                    }
                    @{
                        DeviceSetting     = 'SoftwareMetering'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'SoftwareUpdates'
                        Setting           = 'Enabled'
                        Result            = 'Enable'
                    }
                    @{
                        DeviceSetting     = 'SoftwareUpdates'
                        Setting           = 'EvaluationSchedule'
                        Result            = 'DeploymentEvaluationSchedule'
                    }
                    @{
                        DeviceSetting     = 'SoftwareUpdates'
                        Setting           = 'AssignmentBatchingTimeout'
                        Result            = 'BatchingTimeout'
                    }
                    @{
                        DeviceSetting     = 'SoftwareUpdates'
                        Setting           = 'O365Management'
                        Result            = 'Office365ManagementType'
                    }
                    @{
                        DeviceSetting     = 'SoftwareUpdates'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'StateMessaging'
                        Setting           = 'BulkSendInterval'
                        Result            = 'ReportingCycleMins'
                    }
                    @{
                        DeviceSetting     = 'StateMessaging'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'UserAndDeviceAffinity'
                        Setting           = 'ConsoleMinutes'
                        Result            = 'LogOnThresholdMins'
                    }
                    @{
                        DeviceSetting     = 'UserAndDeviceAffinity'
                        Setting           = 'IntervalDays'
                        Result            = 'UsageThresholdDays'
                    }
                    @{
                        DeviceSetting     = 'UserAndDeviceAffinity'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                    @{
                        DeviceSetting     = 'WindowsAnalytics'
                        Setting           = 'WAEnable'
                        Result            = 'Enable'
                    }
                    @{
                        DeviceSetting     = 'WindowsAnalytics'
                        Setting           = 'WACommercialID'
                        Result            = 'CommercialIdKey'
                    }
                    @{
                        DeviceSetting     = 'WindowsAnalytics'
                        Setting           = 'WATelLevel'
                        Result            = 'Win10Telemetry'
                    }
                    @{
                        DeviceSetting     = 'WindowsAnalytics'
                        Setting           = 'WAOptInDownlevel'
                        Result            = 'EnableEarlierTelemetry'
                    }
                    @{
                        DeviceSetting     = 'WindowsAnalytics'
                        Setting           = 'WAIEOptInlevel'
                        Result            = 'IEDataCollectionOption'
                    }
                    @{
                        DeviceSetting     = 'WindowsAnalytics'
                        Setting           = 'DefaultSetting'
                        Result            = 'DefaultSetting'
                    }
                )
            }

            foreach ($config in $convertItems.Items)
            {
                It "Should return as expected for $($config.DeviceSetting) $($config.Setting)" {
                    Convert-ClientSetting -DeviceSettingName $config.DeviceSetting -Setting $config.Setting | Should -Be -ExpectedValue $config.Result
                }
            }
        }
    }

    Describe "$moduleResourceName\Get-ClientSettingsSoftwareCenter" {

        $settings = @{
            SC_Old_Branding = $True
            SettingsXML = 
            '<settings>
            <settings-version>1.0</settings-version>
            <tab-visibility>
            <tab name="AvailableSoftware" visible="true" />
            <tab name="Updates" visible="true" />
            <tab name="OSD" visible="true" />
            <tab name="InstallationStatus" visible="true" />
            <tab name="Compliance" visible="true" />
            <tab name="Options" visible="true" />
            </tab-visibility>
            <software-list>
                <unapproved-applications-hidden>false</unapproved-applications-hidden>
                <installed-applications-hidden>true</installed-applications-hidden>
            </software-list>
            <brand-logo />
            <brand-orgname>Lab</brand-orgname>
            <brand-color>#FF0080</brand-color>
            <application-catalog-link-hidden>false</application-catalog-link-hidden>
            <defaults-list>
                <required-filter-default>true</required-filter-default>
                <list-view-default>true</list-view-default>
            </defaults-list>
            <custom-tab custom-tab-name="Test" custom-tab-content="http://test1/" />
            </settings>'
        }

        Context 'When return is as expected' {

            It 'Should return the correct results in for SC_Old_Branding' {
                Mock -CommandName Get-CMClientSetting -MockWith { $settings }

                Get-ClientSettingsSoftwareCenter -Name Test -Setting SC_Old_Branding | Should -Be -ExpectedValue 1
            }

            It 'Should return the correct results in Visibility Tab' {
                Mock -CommandName Get-CMClientSetting -MockWith { $settings }

                Get-ClientSettingsSoftwareCenter -Name Test -Setting AvailableSoftware | Should -Be -ExpectedValue 'true'
            }

            It 'Should return the correct results in hidden settings' {
                Mock -CommandName Get-CMClientSetting -MockWith { $settings }

                Get-ClientSettingsSoftwareCenter -Name Test -Setting unapproved-applications-hidden | Should -Be -ExpectedValue 'false'
            }

            It 'Should return the correct results in custom tab' {
                Mock -CommandName Get-CMClientSetting -MockWith { $settings }

                Get-ClientSettingsSoftwareCenter -Name Test -Setting custom-tab-name | Should -Be -ExpectedValue 'Test'
            }

            It 'Should return the correct results in additional settings' {
                Mock -CommandName Get-CMClientSetting -MockWith { $settings }

                Get-ClientSettingsSoftwareCenter -Name Test -Setting brand-orgname | Should -Be -ExpectedValue 'Lab'
            }
        }
    }

    Describe "$moduleResourceName\Convert-CidrToIP" {

        Context 'When results are as expected' {

            It 'Should return expected results Cidr 24' {
                $result = Convert-CidrToIP -IPAddress 10.1.1.1 -Cidr 24
                $result.NetworkAddress | Should -Be -ExpectedValue '10.1.1.0'
                $result.Subnetmask     | Should -Be -ExpectedValue '255.255.255.0'
                $result.Cidr           | Should -Be -ExpectedValue '24'
            }

            It 'Should return expected results Cidr 16' {
                $result = Convert-CidrToIP -IPAddress 10.1.1.1 -Cidr 16
                $result.NetworkAddress | Should -Be -ExpectedValue '10.1.0.0'
                $result.Subnetmask     | Should -Be -ExpectedValue '255.255.0.0'
                $result.Cidr           | Should -Be -ExpectedValue '16'
            }

            It 'Should return expected results Cidr 8' {
                $result = Convert-CidrToIP -IPAddress 10.1.1.1 -Cidr 8
                $result.NetworkAddress | Should -Be -ExpectedValue '10.0.0.0'
                $result.Subnetmask     | Should -Be -ExpectedValue '255.0.0.0'
                $result.Cidr           | Should -Be -ExpectedValue '8'
            }

            It 'Should thow with invalid IP Address' {
                { Convert-CidrToIP -IPAddress 10.1.1.1.1 -Cidr 8 } | Should -Throw
            }
        }
    }

    Describe "$moduleResourceName\Convert-BoundariesIPSubnets" {

        $inputObject = @(
            @{
                BoundaryID = 16777231
                BoundaryType = 3
                Value        = '10.1.1.1-10.1.1.255'
            }
            @{
                BoundaryID = 16777232
                BoundaryType = 0
                Value        = '10.1.2.0'
            }
            @{
                BoundaryID = 16777233
                BoundaryType = 1
                Value        = 'First-Site'
            }

        )

        Context 'When results are as expected' {

            It 'Should return desired output' {

                $result = ConvertTo-CimBoundaries -InputObject $inputObject
                $result          | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                $result.Count    | Should -Be -ExpectedValue 3
                $result[0].Value | Should -Be -ExpectedValue '10.1.1.1-10.1.1.255'
                $result[0].Type  | Should -Be -ExpectedValue 'IPRange'
                $result[1].Value | Should -Be -ExpectedValue '10.1.2.0'
                $result[1].Type  | Should -Be -ExpectedValue 'IPSubnet'
                $result[2].Value | Should -Be -ExpectedValue 'First-Site'
                $result[2].Type  | Should -Be -ExpectedValue 'ADSite'
            }
        }
    }

    Describe "$moduleResourceName\ConvertTo-CimBoundaries" {

        $mockBoundaryMembers = @(
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Type'  = 'IPSubnet'
                    'Value' = '10.1.1.1/24'
                } `
                -ClientOnly
            ),
            (New-CimInstance -ClassName DSC_CMBoundaryGroupsBoundaries `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Type'  = 'IPSubnet'
                    'Value' = '10.2.2.1/16'
                } `
                -ClientOnly
            ),
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Type'  = 'IPSubnet'
                    'Value' = '10.3.3.1/8'
                } `
                -ClientOnly
            ),
            (New-CimInstance -ClassName DSC_CMCollectionQueryRules `
                -Namespace root/microsoft/Windows/DesiredStateConfiguration `
                -Property @{
                    'Value' = 'First-Site'
                    'Type'  = 'ADSite'
                } `
                -ClientOnly
            )
        )

        Context 'When results are as expected' {

            It 'Should return desired output' {

                $result = Convert-BoundariesIPSubnets -InputObject $mockBoundaryMembers
                $result          | Should -BeOfType '[Microsoft.Management.Infrastructure.CimInstance]'
                $result.Count    | Should -Be -ExpectedValue 4
                $result[0].Value | Should -Be -ExpectedValue '10.1.1.0'
                $result[0].Type  | Should -Be -ExpectedValue 'IPSubnet'
                $result[1].Value | Should -Be -ExpectedValue '10.2.0.0'
                $result[1].Type  | Should -Be -ExpectedValue 'IPSubnet'
                $result[2].Value | Should -Be -ExpectedValue '10.0.0.0'
                $result[2].Type  | Should -Be -ExpectedValue 'IPSubnet'
                $result[3].Value | Should -Be -ExpectedValue 'First-Site'
                $result[3].Type  | Should -Be -ExpectedValue 'ADSite'
            }
        }
    }

    Describe "$moduleResourceName\Get-BoundaryInfo" {

        $ipSubnet = @{
            Value = '10.1.1.0'
            Type  = 'IPSubnet'
        }

        $adSite = @{
            Value = 'First-Site'
            Type  = 'ADSite'
        }

        $ipRange = @{
            Value = '10.1.2.1-10.1.2.255'
            Type  = 'IPRange'
        }

        $boundaryInfo = @(
            @{
                BoundaryID   = 16211
                BoundaryType = 0
                Value        = '10.1.1.0'
            }
            @{
                BoundaryID   = 16212
                BoundaryType = 1
                Value        = 'First-Site'
            }
            @{
                BoundaryID   = 16213
                BoundaryType = 3
                Value        = '10.1.2.1-10.1.2.255'
            }
        )

        Context 'When results are as expected' {
            Mock -CommandName Get-CMBoundary -MockWith { $boundaryInfo }

            It 'Should return desired output for IPSubnet' {

                Get-BoundaryInfo @ipSubnet | Should -Be -ExpectedValue 16211
            }

            It 'Should return desired output for ADSite' {

                Get-BoundaryInfo @adSite | Should -Be -ExpectedValue 16212
            }

            It 'Should return desired output for IPRange' {

                Get-BoundaryInfo @ipRange | Should -Be -ExpectedValue 16213
            }
        }
    }
}
