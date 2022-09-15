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

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -Replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)"

Import-Module $script:subModuleFile -Force -ErrorAction 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue

InModuleScope $script:subModuleName {
    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\Set-ConfigMgrCBDscReverse' -Tag 'Reverse' {
        BeforeAll {
            $getDscResourceReturn = @(
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMAccounts'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'Account'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AccountPassword'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{Absent, Present}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMAdministrativeUser'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'AdminName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Collections'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'CollectionsToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'CollectionsToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Roles'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RolesToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RolesToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Scopes'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScopesToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScopesToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{Absent, Present}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMAssetIntelligencePoint'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'IsSingleInstance'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'CertificateFile'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enable'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableSynchronization'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RemoveCertificate'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{Absent, Present}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMBoundaryGroups'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'BoundaryGroup'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Boundaries'
                            PropertyType = '[DSC_CMBoundaryGroupsBoundaries[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'BoundaryAction'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopes'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopesToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopesToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteSystems'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteSystemsToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteSystemsToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientPushSettings'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Accounts'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AccountsToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AccountsToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableAutomaticClientPushInstallation'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableSystemTypeConfigurationManager'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableSystemTypeServer'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableSystemTypeWorkstation'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'InstallationProperty'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'InstallClientToDomainController'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettings'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Type'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Description'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopes'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopesToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopesToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsBits'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableBitsMaxBandwidth'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaxBandwidthBeginHr'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaxBandwidthEndHr'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaxTransferRateOnSchedule'
                            PropertyType = 'UInt32'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableDownloadOffSchedule'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaxTransferRateOffSchedule'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsClientCache'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ConfigureBranchCache'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableBranchCache'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaxBranchCacheSizePercent'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ConfigureCacheSize'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaxCacheSize'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaxCacheSizePercent'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableSuperPeer'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'BroadcastPort'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DownloadPort'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsClientPolicy'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PolicyPollingMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableUserPolicy'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableUserPolicyOnInternet'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableUserPolicyOnTS'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsCloudService'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowCloudDistributionPoint'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AutoAzureADJoin'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowCloudManagementGateway'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsCompliance'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enable'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableUserDataAndProfile'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
			            @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsComputerAgent'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'InitialReminderHr'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'InterimReminderHr'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'FinalReminderMins'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'BrandingTitle'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseNewSoftwareCenter'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableHealthAttestation'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
			            @{
                            Name         = 'UseOnPremisesHealthAttestation'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'InstallRestriction'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SuspendBitLocker'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableThirdPartyOrchestration'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PowerShellExecutionPolicy'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DisplayNewProgramNotification'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsDelivery'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enable'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsHardware'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enable'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaxRandomDelayMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
			            @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'CollectMifFile'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaxThirdPartyMifSize'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsMetered'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MeteredNetworkUsage'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsPower'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enable'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowUserToOptOutFromPowerPlan'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'NetworkWakeUpOption'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableWakeUpProxy'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WakeupProxyPort'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WakeOnLanPort'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'FirewallExceptionForWakeupProxy'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WakeupProxyDirectAccessPrefix'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsRemoteTools'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'FirewallExceptionProfile'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowClientChange'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowUnattendedComputer'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PromptUserForPermission'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PromptUserForClipboardPermission'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'GrantPermissionToLocalAdministrator'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AccessLevel'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PermittedViewer'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ShowNotificationIconOnTaskbar'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ShowSessionConnectionBar'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AudibleSignal'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ManageUnsolicitedRemoteAssistance'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ManageSolicitedRemoteAssistance'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RemoteAssistanceAccessLevel'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ManageRemoteDesktopSetting'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowPermittedViewer'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RequireAuthentication'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsSoftwareCenter'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableCustomize'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'CompanyName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ColorScheme'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'HideApplicationCatalogLink'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'HideInstalledApplication'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'HideUnapprovedApplication'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableApplicationsTab'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableUpdatesTab'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableOperatingSystemsTab'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableStatusTab'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableComplianceTab'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableOptionsTab'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsSoftwareDeployment'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
			            @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsSoftwareInventory'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enable'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ReportOption'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
			            @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsSoftwareMetering'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enable'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
			            @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsSoftwareUpdate'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enable'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScanMonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScanRecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScanScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScanStart'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
			            @{
                            Name         = 'ScanDayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScanDayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EvalMonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EvalRecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EvalScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EvalStart'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
			            @{
                            Name         = 'EvalDayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EvalDayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnforceMandatory'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TimeUnit'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'BatchingTimeOut'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableDeltaDownload'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DeltaDownloadPort'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Office365ManagementType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableThirdPartyUpdates'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsStateMessaging'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ReportingCycleMins'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientSettingsUserDeviceAffinity'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientSettingName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'LogOnThresholdMins'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UsageThresholdDays'
                            PropertyType = '[uint32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AutoApproveAffinity'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowUserAffinity'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMClientStatusSettings'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'IsSingleInstance'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientPolicyDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'HardwareInventoryDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'HeartbeatDiscoveryDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'HistoryCleanupDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SoftwareInventoryDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'StatusMessageDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMCollectionMembershipEvaluationComponent'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EvaluationMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMCollections'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'CollectionName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'CollectionType'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Comment'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DirectMembership'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ExcludeMembership'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'IncludeMembership'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'LimitingCollectionName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'QueryRules'
                            PropertyType = '[DSC_CMCollectionQueryRules[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RefreshType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{Absent, Present}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMDistributionGroup'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'DistributionGroup'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DistributionPoints'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DistributionPointsToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DistributionPointsToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopes'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopesToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopesToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{Absent, Present}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMDistributionPoint'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Description'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MinimumFreeSpaceMB'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PrimaryContentLibraryLocation'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecondaryContentLibraryLocation'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PrimaryPackageShareLocation'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecondaryPackageShareLocation'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'CertificateExpirationTimeUtc'
                            PropertyType = '[datetime]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientCommunicationType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'BoundaryGroups'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'BoundaryGroupStatus'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowPreStaging'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableAnonymous'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableBranchCache'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableLedbat'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMDistributionPointGroupMembers'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DistributionPoint'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DistributionGroups'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DistributionGroupsToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DistributionGroupsToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMEmailNotificationComponent'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enabled'
                            PropertyType = '[boolean]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SmtpServerFqdn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SendFrom'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Port'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UserName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseSsl'
                            PropertyType = '[boolean]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TypeOfAuthentication'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMFallbackStatusPoint'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'StateMessageCount'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ThrottleSec'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMForestDiscovery'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enabled'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableActiveDirectorySiteBoundaryCreation'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableSubnetBoundaryCreation'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleCount'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleInterval'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMGroupDiscovery'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enabled'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DeltaDiscoveryMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DiscoverDistributionGroupMembership'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableDeltaDiscovery'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableFilteringExpiredLogon'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableFilteringExpiredPassword'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'GroupDiscoveryScope'
                            PropertyType = '[DSC_CMGroupDiscoveryScope[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'GroupDiscoveryScopeToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'GroupDiscoveryScopeToInclude'
                            PropertyType = '[DSC_CMGroupDiscoveryScope[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TimeSinceLastLogonDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TimeSinceLastPasswordUpdateDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMHeartbeatDiscovery'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enabled'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleCount'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleInterval'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMManagementPoint'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientConnectionType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DatabaseName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableCloudGateway'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableSsl'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'GenerateAlert'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SqlServerFqdn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SqlServerInstanceName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseComputerAccount'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Username'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseSiteDatabase'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMNetworkDiscovery'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enabled'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMPullDistributionPoint'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnablePullDP'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SourceDistributionPoint'
                            PropertyType = '[DSC_CMPullDistributionPointSourceDP[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMPxeDistributionPoint'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowPxeResponse'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableNonWdsPxe'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnablePxe'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableUnknownComputerSupport'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PxePassword'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PxeServerResponseDelaySec'
                            PropertyType = '[UInt16]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UserDeviceAffinity'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMReportingServicePoint'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DatabaseName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DatabaseServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'FolderName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ReportServerInstance'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Username'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMSecurityScopes'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SecurityScopeName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Description'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMServiceConnectionPoint'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Mode'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMSiteConfiguration'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Comment'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientComputerCommunicationType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{HttpsOnly,HttpsOrHttp}'
                        }
                        @{
                            Name         = 'ClientCheckCertificateRevocationListForSiteSystem'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UsePkiClientCertificate'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseSmsGeneratedCert'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RequireSigning'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RequireSha256'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseEncryption'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaximumConcurrentSendingForAllSite'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaximumConcurrentSendingForPerSite'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RetryNumberForConcurrentSending'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ConcurrentSendingDelayBeforeRetryingMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableLowFreeSpaceAlert'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'FreeSpaceThresholdWarningGB'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'FreeSpaceThresholdCriticalGB'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ThresholdOfSelectCollectionByDefault'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ThresholdOfSelectCollectionMax'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteSystemCollectionBehavior'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{Warn,Block}'
                        }
                        @{
                            Name         = 'EnableWakeOnLan'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WakeOnLanTransmissionMethodType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{Unicast,SubnetDirectedBroadcasts}'
                        }
                        @{
                            Name         = 'RetryNumberOfSendingWakeupPacketTransmission'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SendingWakeupPacketTransmissionDelayMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaximumNumberOfSendingWakeupPacketBeforePausing'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SendingWakeupPacketBeforePausingWaitSec'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ThreadNumberOfSendingWakeupPacket'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SendingWakeupPacketTransmissionOffsetMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientCertificateCustomStoreName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TakeActionForMultipleCertificateMatchCriteria'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{FailSelectionAndSendErrorMessage,SelectCertificateWithLongestValidityPeriod}'
                        }
                        @{
                            Name         = 'ClientCertificateSelectionCriteriaType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{ClientAuthentication,CertificateSubjectContainsString,CertificateSubjectOrSanIncludesAttributes}'
                        }
                        @{
                            Name         = 'ClientCertificateSelectionCriteriaValue'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMSiteMaintenance'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TaskName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enabled'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'BackupLocation'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'BeginTime'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DaysOfWeek'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DeleteOlderThanDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'LatestBeginTime'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RunInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMSiteSystemServer'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteSystemServer'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AccountName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableProxy'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'FdmOperation'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ProxyAccessAccount'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ProxyServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ProxyServerPort'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PublicFqdn'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseSiteServerAccount'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMSoftwareDistributionComponent'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AccessAccounts'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AccessAccountsToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AccessAccountsToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientComputerAccount'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DelayBeforeRetryingMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaximumPackageCount'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MaximumThreadCountPerPackage'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MulticastDelayBeforeRetryingMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MulticastRetryCount'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RetryCount'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMSoftwareUpdatePoint'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'SiteServerName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AnonymousWsusAccess'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientConnectionType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableCloudGateway'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseProxy'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseProxyForAutoDeploymentRule'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WsusAccessAccount'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WsusIisPort'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WsusIisSslPort'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WsusSsl'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMSoftwareUpdatePointComponent'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'LanguageSummaryDetails'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'LanguageSummaryDetailsToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'LanguageSummaryDetailsToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'LanguageUpdateFiles'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'LanguageUpdateFilesToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'LanguageUpdateFilesToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Products'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ProductsToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ProductsToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UpdateClassifications'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UpdateClassificationsToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UpdateClassificationsToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ContentFileOption'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{FullFilesOnly, ExpressForWindows10Only}'
                        }
                        @{
                            Name         = 'DefaultWsusServer'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableCallWsusCleanupWizard'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableSyncFailureAlert'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableSynchronization'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ImmediatelyExpireSupersedence'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ImmediatelyExpireSupersedenceForFeature'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ReportingEvent'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{CreateAllWsusReportingEvents, CreateOnlyWsusStatusReportingEvents, DoNotCreateWsusReportingEvents}'
                        }
                        @{
                            Name         = 'SynchronizeAction,'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{SynchronizeFromMicrosoftUpdate, SynchronizeFromAnUpstreamDataSourceLocation, DoNotSynchronizeFromMicrosoftUpdateOrUpstreamDataSource}'
                        }
                        @{
                            Name         = 'UpstreamSourceLocation'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WaitMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'WaitMonthForFeature'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{MonthlyByDay, MonthlyByWeek, Weekly, Days}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{First, Second, Third, Fourth, Last}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday}'
                        }
                        @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableManualCertManagement'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableThirdPartyUpdates'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'FeatureUpdateMaxRuntimeMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'NonFeatureUpdateMaxRuntimeMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMStatusReportingComponent'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientLogChecked'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientLogFailureChecked'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientLogType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientReportChecked'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientReportFailureChecked'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ClientReportType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ServerLogChecked'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ServerLogFailureChecked'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ServerLogType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ServerReportChecked'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ServerReportFailureChecked'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ServerReportType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMSystemDiscovery'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enabled'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ADContainers'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ADContainersToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ADContainersToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DeltaDiscoveryMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableDeltaDiscovery'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableFilteringExpiredLogon'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableFilteringExpiredPassword'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleCount'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleInterval'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TimeSinceLastLogonDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TimeSinceLastPasswordUpdateDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMUserDiscovery'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Enabled'
                            PropertyType = '[bool]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ADContainers'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ADContainersToExclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ADContainersToInclude'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DeltaDiscoveryMins'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableDeltaDiscovery'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleCount'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleInterval'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMMaintenanceWindows'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties    = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'CollectionName'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Name'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Ensure'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'HourDuration'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MinuteDuration'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfMonth'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DayOfWeek'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'MonthlyWeekOrder'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'RecurInterval'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ScheduleType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'Start'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'IsEnabled'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ServiceWindowsType'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
                @{
                    ImplementedAs = 'PowerShell'
                    Name          = 'CMHierarchySetting'
                    ModuleName    = 'ConfigMgrCBDsc'
                    Version       = '1.0.1'
                    Properties = @(
                        @{
                            Name         = 'SiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $true
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AllowPrestage'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ApprovalMethod'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AutoResolveClientConflict'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableAutoClientUpgrade'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnableExclusionCollection'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnablePreProduction'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'EnablePrereleaseFeature'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ExcludeServer'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PreferBoundaryGroupManagementPoint'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'UseFallbackSite'
                            PropertyType = '[bool]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'AutoUpgradeDays'
                            PropertyType = '[UInt32]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'ExclusionCollectionName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'FallbackSiteCode'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TargetCollectionName'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'TelemetryLevel'
                            PropertyType = '[string]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'DependsOn'
                            PropertyType = '[string[]]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                        @{
                            Name         = 'PsDscRunAsCredential'
                            PropertyType = '[PSCredential]'
                            IsMandatory  = $false
                            Values       = '{}'
                        }
                    )
                }
            )

            $invokeCMAccounts = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                Account              = 'contoso\user1'
                AccountPassword      = $null
                CurrentAccounts      = 'contoso\user1','contoso\user2'
                Ensure               = 'Present'
                SiteCode             = 'LAB'
                PSComputerName       = 'localhost'
            }

            $cmAccounts = @(
                @{
                    SiteCode = 'LAB'
                    UserName = 'contoso\user1'
                }
            )

            $invokeCMAdministrativeUser = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                AdminName            = 'contoso\administrator'
                Collections          = @('All Systems','All Users and User Groups')
                CollectionsToExclude = $null
                CollectionsToInclude = $null
                Ensure               = 'Present'
                Roles                = @('Full Administrator')
                RolesToExclude       = $null
                RolesToInclude       = $null
                Scopes               = @('All')
                ScopesToExclude      = $null
                ScopesToInclude      = $null
                SiteCode             = 'LAB'
                PSComputerName       = 'localhost'
            }

            $cmAdministrativeUsers = @(
                @{
                    LogonName = 'contoso\Admin'
                }
            )

            $cmAssetIntellReturn = @{
                NetworkOSPath = '\\CA01.contoso.com'
                RoleName      = 'AI Update Service Point'
            }

            $invokeCMAssetIntelligencePoint = @{
                ConfigurationName     = $null
                DependsOn             = $null
                ModuleName            = 'ConfigMgrCBDsc'
                ModuleVersion         = 1.0.1
                PsDscRunAsCredential  = $null
                ResourceId            = $null
                SourceInfo            = $null
                CertificateFile       = ''
                DayOfMonth            = $null
                DayOfWeek             = $null
                Enable                = $true
                EnableSynchronization = $true
                Ensure                = 'Present'
                IsSingleInstance      = 'Yes'
                MonthlyWeekOrder      = $null
                RecurInterval         = 7
                RemoveCertificate     = $null
                ScheduleType          = 'Days'
                SiteCode              = 'LAB'
                SiteServerName        = 'CA01.contoso.com'
                Start                 = '2/1/1970 00:00'
                PSComputerName        = 'localhost'
            }

            $assetIntell = @{
                SiteCode = 'Lab'
                Include  = 'AssetIntelligencePoint'
            }

            $invokeCMAssetIntelligencePointNoneSchedule = @{
                ConfigurationName     = $null
                DependsOn             = $null
                ModuleName            = 'ConfigMgrCBDsc'
                ModuleVersion         = 1.0.1
                PsDscRunAsCredential  = $null
                ResourceId            = $null
                SourceInfo            = $null
                CertificateFile       = ''
                DayOfMonth            = $null
                DayOfWeek             = $null
                Enable                = $true
                EnableSynchronization = $true
                Ensure                = 'Present'
                IsSingleInstance      = 'Yes'
                MonthlyWeekOrder      = $null
                RecurInterval         = $null
                RemoveCertificate     = $null
                ScheduleType          = 'None'
                SiteCode              = 'LAB'
                SiteServerName        = 'CA01.contoso.com'
                Start                 = $null
                PSComputerName        = 'localhost'
            }

            $invokeClientPushSetting = @{
                ConfigurationName                     = $null
                DependsOn                             = $null
                ModuleName                            = 'ConfigMgrCBDsc'
                ModuleVersion                         = 1.0.1
                PsDscRunAsCredential                  = $null
                ResourceId                            = $null
                SourceInfo                            = $null
                Accounts                              =  @('contoso\User1','contoso\User2','contoso\User3')
                AccountsToExclude                     = $null
                AccountsToInclude                     = $null
                EnableAutomaticClientPushInstallation = $false
                EnableSystemTypeConfigurationManager  = $true
                EnableSystemTypeServer                = $true
                EnableSystemTypeWorkstation           = $true
                InstallationProperty                  = 'SMSSITECODE=LAB'
                InstallClientToDomainController       = $false
                SiteCode                              = 'LAB'
                PSComputerName                        = 'localhost'
            }

            $invokeClientStatusSetting = @{
                ConfigurationName      = $null
                DependsOn              = $null
                ModuleName             = 'ConfigMgrCBDsc'
                ModuleVersion          = 1.0.1
                PsDscRunAsCredential   = $null
                ResourceId             = $null
                SourceInfo             = $null
                ClientPolicyDays       = 8
                HardwareInventoryDays  = 7
                HeartbeatDiscoveryDays = 7
                HistoryCleanupDays     = 31
                IsSingleInstance       = 'Yes'
                SiteCode               = 'LAB'
                SoftwareInventoryDays  = 7
                StatusMessageDays      = 7
                PSComputerName         = 'localhost'
            }

            $invokeCollEval = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                EvalulationMins      = 10
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $deviceCollectionsReturn = @{
                Name                = 'TestCollection'
                CollectionType      = 2
                ServiceWindowsCount = 1
                CollectionID        = '123456'
            }

            $userCollectionsReturn = @{
                Name           = 'UserCollection'
                CollectionType = 1
            }

            $invokeDeviceCollections = @{
                ConfigurationName      = $null
                DependsOn              = $null
                ModuleName             = 'ConfigMgrCBDsc'
                ModuleVersion          = 1.0.1
                PsDscRunAsCredential   = $null
                ResourceId             = $null
                SourceInfo             = $null
                CollectionName         = 'TestCollection'
                CollectionType         = 'Device'
                Comment                = $null
                DayOfMonth             = $null
                DayOfWeek              = 'Tuesday'
                DirectMembership       = $null
                DirectMembershipId     = $null
                Ensure                 = 'Present'
                ExcludeMembership      = $null
                IncludeMembership      = $null
                LimitingCollectionName = 'All Systems'
                MonthlyWeekOrder       = 'Second'
                QueryRules             = $null
                RecurInterval          = 1
                RefreshType            = 'Both'
                ScheduleType           = 'MonthlyByWeek'
                SiteCode               = 'LAB'
                Start                  = '11/17/2020 14:26'
                PSComputerName         = 'localhost'
            }

            $invokeUserCollections = @{
                ConfigurationName      = $null
                DependsOn              = $null
                ModuleName             = 'ConfigMgrCBDsc'
                ModuleVersion          = 1.0.1
                PsDscRunAsCredential   = $null
                ResourceId             = $null
                SourceInfo             = $null
                CollectionName         = 'UserCollection'
                CollectionType         = 'User'
                Comment                = $null
                DayOfMonth             = 10
                DayOfWeek              = $null
                DirectMembership       = $null
                DirectMembershipId     = $null
                Ensure                 = 'Present'
                ExcludeMembership      = $null
                IncludeMembership      = $null
                LimitingCollectionName = 'All Systems'
                MonthlyWeekOrder       = $null
                QueryRules             = @(
                    @{
                        QueryExpression = 'Select * from sms_r_user'
                        RuleName        = 'All Users'
                        PSComputerName  = 'localhost'
                    }
                )
                RecurInterval          = 1
                RefreshType            = 'Both'
                ScheduleType           = 'MonthlyByDay'
                SiteCode               = 'LAB'
                Start                  = '11/17/2020 14:26'
                PSComputerName         = 'localhost'
            }

            $distributionGroupReturn = @{
                Name = 'TestGroup'
            }

            $invokeCMDistributionGroup = @{
                ConfigurationName           = $null
                DependsOn                   = $null
                ModuleName                  = 'ConfigMgrCBDsc'
                ModuleVersion               = 1.0.1
                PsDscRunAsCredential        = $null
                ResourceId                  = $null
                SourceInfo                  = $null
                DistributionGroup           = 'TestGroup'
                DistributionPoints          = @('dp01.contoso.com','dp02.contoso.com')
                DistributionPointsToExclude = $null
                DistributionPointsToInclude = $null
                Ensure                      = 'Present'
                SecurityScopes              = @('Default')
                SecurityScopesToExclude     = $null
                SecurityScopesToInclude     = $null
                SiteCode                    = 'LAB'
                PSComputerName              = 'localhost'
            }

            $getDistroPointReturn = @{
                SiteCode      = 'Lab'
                NetworkOSPath = '\\DP01.contoso.com'
            }

            $invokeCMDistributionPoint = @{
                ConfigurationName               = $null
                DependsOn                       = $null
                ModuleName                      = 'ConfigMgrCBDsc'
                ModuleVersion                   = 1.0.1
                PsDscRunAsCredential            = $null
                ResourceId                      = $null
                SourceInfo                      = $null
                AllowPreStaging                 = $false
                BoundaryGroups                  = @('Test-boundary-group2','Test-boundary-group1')
                BoundaryGroupStatus             = $null
                CertificateExpirationTimeUtc    = '2/3/2022 3:37:48 PM'
                ClientCommunicationType         = 'HTTP'
                Description                     = 'test value'
                EnableAnonymous                 = $true
                EnableBranchCache               = $false
                EnableLedbat                    = $false
                Ensure                          = 'Present'
                MinimumFreeSpaceMB              = 100
                PrimaryContentLibraryLocation   = 'F'
                PrimaryPackageShareLocation     = 'F'
                SecondaryContentLibraryLocation = 'C'
                SecondaryPackageShareLocation   = 'C'
                SiteCode                        = 'Lab'
                SiteServerName                  = 'DP01.contoso.com'
                PSComputerName                  = 'localhost'
            }

            $invokeCMDistributionGroupMembers = @{
                ConfigurationName           = $null
                DependsOn                   = $null
                ModuleName                  = 'ConfigMgrCBDsc'
                ModuleVersion               = 1.0.1
                PsDscRunAsCredential        = $null
                ResourceId                  = $null
                SourceInfo                  = $null
                DistributionGroups          = @('TestGroup1','TestGroup2')
                DistributionGroupsToExclude = $null
                DistributionGroupsToInclude = $null
                DistributionPoint           = 'DP01.contoso.com'
                DPStatus                    = 'Present'
                SiteCode                    = 'Lab'
                PSComputerName              = 'localhost'
            }

            $invokeEmailComponent = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                Enabled              = $true
                TypeOfAuthentication = 'Other'
                UserName             = 'contoso\emailUser'
                SmtpServerFqdn       = 'Smtp01.contoso.com'
                SendFrom             = 'sender@contoso.com'
                Port                 = 446
                UseSsl               = $true
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $getFallBackStatusReturn = @(
                @{
                    SiteCode      = 'Lab'
                    NetworkOSPath = '\\MP01.contoso.com'
                }
            )

            $invokeFallbackPoints = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                Ensure               = 'Present'
                SiteCode             = 'Lab'
                SiteServerName       = 'MP01.contoso.com'
                StateMessageCount    = 10000
                ThrottleSec          = 3600
                PSComputerName       = 'localhost'
            }

            $getForestDiscoveryEnabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'ACTIVE'
                    }
                )
            }

            $getForestDiscoveryDisabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'INACTIVE'
                    }
                )
            }

            $forestDiscovery = @{
                SiteCode = 'Lab'
                Include  = 'ForestDiscovery'
            }

            $invokeForestDiscoveryEnabled = @{
                ConfigurationName                         = $null
                DependsOn                                 = $null
                ModuleName                                = 'ConfigMgrCBDsc'
                ModuleVersion                             = 1.0.1
                PsDscRunAsCredential                      = $null
                ResourceId                                = $null
                SourceInfo                                = $null
                EnableActiveDirectorySiteBoundaryCreation = $false
                Enabled                                   = $true
                EnableSubnetBoundaryCreation              = $false
                ScheduleCount                             = 1
                ScheduleInterval                          = 'Days'
                SiteCode                                  = 'Lab'
                PSComputerName                            = 'localhost'
            }

            $invokeForestDiscoveryDisabled = @{
                ConfigurationName                         = $null
                DependsOn                                 = $null
                ModuleName                                = 'ConfigMgrCBDsc'
                ModuleVersion                             = 1.0.1
                PsDscRunAsCredential                      = $null
                ResourceId                                = $null
                SourceInfo                                = $null
                EnableActiveDirectorySiteBoundaryCreation = $false
                Enabled                                   = $false
                EnableSubnetBoundaryCreation              = $false
                ScheduleCount                             = $null
                ScheduleInterval                          = $null
                SiteCode                                  = 'Lab'
                PSComputerName                            = 'localhost'
            }

            $getGroupDiscoveryEnabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'ACTIVE'
                    }
                )
            }

            $getGroupDiscoveryDisabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'INACTIVE'
                    }
                )
            }

            $groupDiscovery = @{
                SiteCode = 'Lab'
                Include  = 'GroupDiscovery'
            }

            $invokeGroupDiscoveryEnabled = @{
                ConfigurationName                   = $null
                DependsOn                           = $null
                ModuleName                          = 'ConfigMgrCBDsc'
                ModuleVersion                       = 1.0.1
                PsDscRunAsCredential                = $null
                ResourceId                          = $null
                SourceInfo                          = $null
                DayOfMonth                          = $null
                DayOfWeek                           = $null
                DeltaDiscoveryMins                  = 50
                DiscoverDistributionGroupMembership = $true
                Enabled                             = $true
                EnableDeltaDiscovery                = $true
                EnableFilteringExpiredLogon         = $true
                EnableFilteringExpiredPassword      = $true
                GroupDiscoveryScope                 = @(
                    @{
                        Name           = 'Test1'
                        LdapLocation   = 'OU=Test1,DC=contoso,DC=com'
                        Recurse        = $true
                        PSComputerName = 'localhost'
                    }
                )
                GroupDiscoveryScopeToExclude        = $null
                GroupDiscoveryScopeToInclude        = $null
                MonthlyWeekOrder                    = $null
                RecurInterval                       = $null
                ScheduleType                        = 'None'
                SiteCode                            = 'Lab'
                Start                               = '2/1/1970 00:00'
                TimeSinceLastLogonDays              = 20
                TimeSinceLastPasswordUpdateDays     = 40
                PSComputerName                      = 'localhost'
            }

            $invokeGroupDiscoveryDisabled = @{
                ConfigurationName                   = $null
                DependsOn                           = $null
                ModuleName                          = 'ConfigMgrCBDsc'
                ModuleVersion                       = 1.0.1
                PsDscRunAsCredential                = $null
                ResourceId                          = $null
                SourceInfo                          = $null
                DayOfMonth                          = $null
                DayOfWeek                           = $null
                DeltaDiscoveryMins                  = $null
                DiscoverDistributionGroupMembership = $null
                Enabled                             = $false
                EnableDeltaDiscovery                = $null
                EnableFilteringExpiredLogon         = $null
                EnableFilteringExpiredPassword      = $null
                GroupDiscoveryScope                 = $null
                GroupDiscoveryScopeToExclude        = $null
                GroupDiscoveryScopeToInclude        = $null
                MonthlyWeekOrder                    = $null
                RecurInterval                       = $null
                ScheduleType                        = $null
                SiteCode                            = $null
                Start                               = $null
                TimeSinceLastLogonDays              = $null
                TimeSinceLastPasswordUpdateDays     = $null
                PSComputerName                      = 'localhost'
            }

            $getHeartbeatDiscoveryEnabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'ACTIVE'
                    }
                )
            }

            $getHeartbeatDiscoveryDisabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'INACTIVE'
                    }
                )
            }

            $heartbeatDiscovery = @{
                SiteCode = 'Lab'
                Include  = 'HeartbeatDiscovery'
                Exclude  = 'ClientStatusSettings'
            }

            $invokeHeartbeatDiscoveryEnabled = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                Enabled              = $true
                ScheduleCount        = $null
                ScheduleInterval     = 'None'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeHeartbeatDiscoveryDisabled = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                Enabled              = $false
                ScheduleCount        = $null
                ScheduleInterval     = $null
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $getManagementPointSiteDatabase = @{
                SiteCode      = 'Lab'
                NetworkOSPath = '\\MP01.contoso.com'
                Props         = @(
                    @{
                        PropertyName = 'UseSiteDatabase'
                        Value        = $true
                    }
                    @{
                        PropertyName = 'UserName'
                        Value2       = $null
                    }
                )
            }

            $getManagementPointNonSiteDatabase = @{
                SiteCode      = 'Lab'
                NetworkOSPath = '\\MP01.contoso.com'
                Props         = @(
                    @{
                        PropertyName = 'UseSiteDatabase'
                        Value        = $false
                    }
                    @{
                        PropertyName = 'UserName'
                        Value2       = 'contoso\connect'
                    }
                )
            }

            $managementPoint = @{
                SiteCode = 'Lab'
                Include  = 'ManagementPoint'
            }

            $invokeManagementPointUseSiteDatabase = @{
                ConfigurationName     = $null
                DependsOn             = $null
                ModuleName            = 'ConfigMgrCBDsc'
                ModuleVersion         = 1.0.1
                PsDscRunAsCredential  = $null
                ResourceId            = $null
                SourceInfo            = $null
                ClientConnectionType  = 'Intranet'
                DatabaseName          = $null
                EnableCloudGateway    = $false
                EnableSsl             = $false
                Ensure                = 'Present'
                GenerateAlert         = $false
                SiteCode              = 'Lab'
                SiteServerName        = 'MP01.contoso.com'
                SqlServerFqdn         = $null
                SqlServerInstanceName = $null
                UseComputerAccount    = $true
                Username              = $null
                UseSiteDatabase       = $true
                PSComputerName        = 'localhost'
            }

            $invokeManagementPointUseNonSiteDatabase = @{
                ConfigurationName     = $null
                DependsOn             = $null
                ModuleName            = 'ConfigMgrCBDsc'
                ModuleVersion         = 1.0.1
                PsDscRunAsCredential  = $null
                ResourceId            = $null
                SourceInfo            = $null
                ClientConnectionType  = 'Intranet'
                DatabaseName          = $null
                EnableCloudGateway    = $false
                EnableSsl             = $false
                Ensure                = 'Present'
                GenerateAlert         = $false
                SiteCode              = 'Lab'
                SiteServerName        = 'MP01.contoso.com'
                SqlServerFqdn         = 'MP01.contoso.com'
                SqlServerInstanceName = 'CM_Lab'
                UseComputerAccount    = $false
                Username              = 'contoso\connect'
                UseSiteDatabase       = $true
                PSComputerName        = 'localhost'
            }

            $getNetworkDiscoveryEnabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'ACTIVE'
                    }
                )
            }

            $invokeNetworkDiscovery = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                Enabled              = $false
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $getCMDistributionPointInfo = @{
                SiteCode   = 'Lab'
                ServerName = 'DP03.contoso.com'
                IsPullDP   = $true
                IsPXE      = $true
            }

            $getCMDistributionPointPxePW = @{
                SiteCode    = 'Lab'
                ServerName  = 'DP03.contoso.com'
                IsPullDP    = $true
                IsPXE       = $true
                PxePassword = 'somepw'
            }

            $pullDP = @{
                SiteCode = 'Lab'
                Include  = 'PullDistributionPoint'
            }

            $invokepullDP = @{
                ConfigurationName       = $null
                DependsOn               = $null
                ModuleName              = 'ConfigMgrCBDsc'
                ModuleVersion           = 1.0.1
                PsDscRunAsCredential    = $null
                ResourceId              = $null
                SourceInfo              = $null
                SiteServerName          = 'DP03.contoso.com'
                SourceDistributionPoint = @(
                    @{
                        DPRank         = 1
                        SourceDP       = 'DP01.contoso.com'
                        PSComputerName = 'localhost'
                    }
                    @{
                        DPRank         = 2
                        SourceDP       = 'DP02.contoso.com'
                        PSComputerName = 'localhost'
                    }
                )
                SiteCode                = 'Lab'
                PSComputerName          = 'localhost'
            }

            $pxeDP = @{
                SiteCode = 'Lab'
                Include  = 'PxeDistributionPoint'
            }

            $invokePxeDP = @{
                ConfigurationName            = $null
                DependsOn                    = $null
                ModuleName                   = 'ConfigMgrCBDsc'
                ModuleVersion                = 1.0.1
                PsDscRunAsCredential         = $null
                ResourceId                   = $null
                SourceInfo                   = $null
                SiteServerName               = 'DP03.contoso.com'
                AllowPxeResponse             = $true
                DPStatus                     = 'Present'
                EnableNonWdsPxe              = $false
                EnablePxe                    = $true
                EnableUnknownComputerSupport = $false
                IsMulticast                  = $true
                PxePassword                  = 'MSFT_Credential'
                PxeServerResponseDelaySec    = 0
                SiteCode                     = 'Lab'
                PSComputerName               = 'localhost'
            }

            $getReportingServicesReturn = @{
                SiteCode      = 'Lab'
                NetworkOSPath = '\\RP01.contoso.com'
            }

            $invokeReportingServices = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                SiteServerName       = 'RP01.contoso.com'
                DatabaseName         = 'CM_Lab'
                DatabaseServerName   = 'CA01.contoso.com'
                FolderName           = 'CM_Lab'
                ReportServerInstance = 'InstCMLab'
                Username             = 'contoso\reportingUser'
                Ensure               = 'Present'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $getSecurityScopesReturn = @(
                @{
                    SiteCode     = 'Lab'
                    CategoryName = 'Scope1'
                }
            )

            $invokeSecurityScopes = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                SecurityScopeName    = 'Scope1'
                Description          = 'Scope 1'
                Ensure               = 'Present'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $getServiceConnectionPoint = @{
                SiteCode      = 'Lab'
                NetworkOSPath = 'CA01.contoso.com'
            }

            $invokeServiceConnectionPoint = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                SiteServerName       = 'CA01.contoso.com'
                Mode                 = 'Online'
                Ensure               = 'Present'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $siteMaintenance = @{
                SiteCode = 'Lab'
                Include  = 'SiteMaintenance'
            }

            $getCMDefinitionCas = @{
                SiteCode = 'Lab'
                SiteType = 1
            }

            $getCMDefinitionPrimary = @{
                SiteCode = 'Lab'
                SiteType = 2
            }

            $invokeSiteMaintenanceBackup = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                BackupLocation       = 'E:\cmsitebackups'
                BeginTime            = '1500'
                DaysOfWeek           = @('Sunday')
                DeleteOlderThanDays  = 0
                Enabled              = $true
                LatestBeginTime      = '2000'
                RunInterval          = $null
                SiteType             = 2
                TaskName             = 'Backup SMS Site Server'
                TaskType             = 1
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeSiteMaintenanceDelete = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                BackupLocation       = $null
                BeginTime            = '0200'
                DaysOfWeek           = @('Sunday')
                DeleteOlderThanDays  = 90
                Enabled              = $true
                LatestBeginTime      = '0700'
                RunInterval          = $null
                SiteType             = 2
                TaskName             = 'Delete Aged Collected Files'
                TaskType             = 3
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeSiteMaintenanceSummary = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                BackupLocation       = ''
                BeginTime            = '0200'
                DaysOfWeek           = @('Sunday')
                DeleteOlderThanDays  = 0
                Enabled              = $true
                LatestBeginTime      = '0700'
                RunInterval          = $null
                SiteType             = 2
                TaskName             = 'Summarize Installed Software Data'
                TaskType             = 3
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeSiteMaintenanceAppCat = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                BackupLocation       = $null
                BeginTime            = $null
                DaysOfWeek           = $null
                DeleteOlderThanDays  = $null
                Enabled              = $true
                LatestBeginTime      = $null
                RunInterval          = 5
                SiteType             = 2
                TaskName             = 'Update Application Catalog Tables'
                TaskType             = $null
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeSiteMaintenanceDisabled = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                BackupLocation       = $null
                BeginTime            = $null
                DaysOfWeek           = $null
                DeleteOlderThanDays  = $null
                Enabled              = $false
                LatestBeginTime      = $null
                RunInterval          = $null
                SiteType             = 2
                TaskName             = 'Delete Aged Enrolled Devices'
                TaskType             = 3
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $siteSystem = @{
                SiteCode = 'Lab'
                Include  = 'SiteSystemServer'
            }

            $getCMSiteSystemsProxy = @{
                SiteCode      = 'Lab'
                NetworkOSPath = '\\DP01.contoso.com'
                Props         = @(
                    @{
                        PropertyName = 'UseMachineAccount'
                        Value        = 1
                    }
                    @{
                        PropertyName = 'UseProxy'
                        Value        = 1
                    }
                    @{
                        PropertyName = 'AnonymousProxyAccess'
                        Value        = 1
                    }
                )
            }

            $getCMSiteSystemsMachineAccount = @{
                SiteCode      = 'Lab'
                NetworkOSPath = '\\DP01.contoso.com'
                Props         = @(
                    @{
                        PropertyName = 'UseMachineAccount'
                        Value        = 0
                    }
                    @{
                        PropertyName = 'UseProxy'
                        Value        = 0
                    }
                    @{
                        PropertyName = 'AnonymousProxyAccess'
                        Value        = $null
                    }
                )
            }

            $invokeSiteSystemProxy = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                AccountName          = 'contoso\connect'
                EnableProxy          = $true
                Ensure               = 'Present'
                FdmOperation         = $false
                ProxyAccessAccount   = $null
                ProxyServerName      = 'proxy.contoso.com'
                ProxyServerPort      = 80
                PublicFqdn           = $null
                RoleCount            = 11
                SiteSystemServer     = 'DP01.contoso.com'
                UseSiteServerAccount = $false
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeSiteSystemNonProxy = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                AccountName          = $null
                EnableProxy          = $false
                Ensure               = 'Present'
                FdmOperation         = $false
                ProxyAccessAccount   = $null
                ProxyServerName      = $null
                ProxyServerPort      = $null
                PublicFqdn           = $null
                RoleCount            = 11
                SiteSystemServer     = 'DP01.contoso.com'
                UseSiteServerAccount = $true
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeSoftwareDistro = @{
                ConfigurationName                = $null
                DependsOn                        = $null
                ModuleName                       = 'ConfigMgrCBDsc'
                ModuleVersion                    = 1.0.1
                PsDscRunAsCredential             = $null
                ResourceId                       = $null
                SourceInfo                       = $null
                AccessAccounts                   = @('contoso\billy', 'contoso\test', 'contoso\test1')
                AccessAccountsToExclude          = $null
                AccessAccountsToInclude          = $null
                ClientComputerAccount            = $false
                DelayBeforeRetryingMins          = 30
                MaximumPackageCount              = 4
                MaximumThreadCountPerPackage     = 5
                MulticastDelayBeforeRetryingMins = 1
                MulticastRetryCount              = 3
                RetryCount                       = 100
                SiteCode                         = 'Lab'
                PSComputerName                   = 'localhost'
            }

            $getSoftwareUpdatePoint = @{
                SiteCode      = 'Lab'
                NetworkOSPath = 'SP01.contoso.com'
                Props         = @(
                    @{
                        PropertyName = 'WSUSAccessAccount'
                        Value2       = $null
                    }
                )
            }

            $invokeSoftwareUpdate = @{
                ConfigurationName             = $null
                DependsOn                     = $null
                ModuleName                    = 'ConfigMgrCBDsc'
                ModuleVersion                 = 1.0.1
                PsDscRunAsCredential          = $null
                ResourceId                    = $null
                SourceInfo                    = $null
                AnonymousWsusAccess           = $true
                ClientConnectionType          = 'Intranet'
                EnableCloudGateway            = $false
                Ensure                        = 'Present'
                SiteServerName                = 'SP01.contoso.com'
                UseProxy                      = $false
                UseProxyForAutoDeploymentRule = $false
                WsusAccessAccount             = $null
                WsusIisPort                   = 8530
                WsusIisSslPort                = 8531
                WsusSsl                       = $false
                SiteCode                      = 'Lab'
                PSComputerName                = 'localhost'
            }

            $supComponent = @{
                SiteCode = 'Lab'
                Include  = 'SoftwareUpdatePointComponent'
            }

            $invokeSoftwareUpdatePointComponent = @{
                ConfigurationName                       = $null
                DependsOn                               = $null
                ModuleName                              = 'ConfigMgrCBDsc'
                ModuleVersion                           = 1.0.1
                PsDscRunAsCredential                    = $null
                ResourceId                              = $null
                SourceInfo                              = $null
                SiteCode                                = 'Lab'
                EnableSynchronization                   = $true
                SynchronizeAction                       = 'SynchronizeFromMicrosoftUpdate'
                ScheduleType                            = 'Days'
                RecurInterval                           = 7
                LanguageSummaryDetailsToInclude         = @('English','French')
                LanguageUpdateFilesToInclude            = @('English','French')
                ProductsToInclude                       = @('Windows Server 2012 R2','Windows 10')
                UpdateClassificationsToInclude          = @('Critical Updates','Updates')
                ContentFileOption                       = 'FullFilesOnly'
                DefaultWsusServer                       = 'CA01.contoso.com'
                EnableCallWsusCleanupWizard             = $true
                EnableSyncFailureAlert                  = $true
                ImmediatelyExpireSupersedence           = $false
                ImmediatelyExpireSupersedenceForFeature = $false
                ReportingEvent                          = 'DoNotCreateWsusReportingEvents'
                WaitMonth                               = 1
                WaitMonthForFeature                     = 1
                EnableThirdPartyUpdates                 = $true
                EnableManualCertManagement              = $false
                FeatureUpdateMaxRuntimeMins             = 300
                NonFeatureUpdateMaxRuntimeMins          = 300
                PSComputerName                          = 'localhost'
            }

            $getCMSite = @{
                ReportingSiteCode = 'CAS'
            }

            $invokeReportingComponent = @{
                ConfigurationName          = $null
                DependsOn                  = $null
                ModuleName                 = 'ConfigMgrCBDsc'
                ModuleVersion              = 1.0.1
                PsDscRunAsCredential       = $null
                ResourceId                 = $null
                SourceInfo                 = $null
                ClientLogChecked           = $false
                ClientLogFailureChecked    = $false
                ClientLogType              = 'NONE'
                ClientReportChecked        = $true
                ClientReportFailureChecked = $false
                ClientReportType           = 'AllMilestones'
                ServerLogChecked           = $true
                ServerLogFailureChecked    = $true
                ServerLogType              = 'AllMilestones'
                ServerReportChecked        = $true
                ServerReportFailureChecked = $true
                ServerReportType           = 'AllMilestones'
                SiteCode                   = 'Lab'
                PSComputerName             = 'localhost'
            }

            $systemDiscovery = @{
                SiteCode = 'Lab'
                Include  = 'SystemDiscovery'
            }

            $getSystemDiscoveryEnabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'ACTIVE'
                    }
                )
            }

            $getSystemDiscoveryDisabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'INACTIVE'
                    }
                )
            }

            $invokeSystemDiscoveryEnabled = @{
                ConfigurationName               = $null
                DependsOn                       = $null
                ModuleName                      = 'ConfigMgrCBDsc'
                ModuleVersion                   = 1.0.1
                PsDscRunAsCredential            = $null
                ResourceId                      = $null
                SourceInfo                      = $null
                ADContainers                    = @('LDAP://OU=DC,DC=contoso,DC=com')
                ADContainersToExclude           = $null
                ADContainersToInclude           = $null
                DeltaDiscoveryMins              = 30
                Enabled                         = $true
                EnableDeltaDiscovery            = $true
                ScheduleCount                   = 12
                ScheduleInterval                = 'Hours'
                EnableFilteringExpiredLogon     = $false
                EnableFilteringExpiredPassword  = $false
                TimeSinceLastLogonDays          = 50
                TimeSinceLastPasswordUpdateDays = 50
                SiteCode                        = 'Lab'
                PSComputerName                  = 'localhost'
            }

            $invokeSystemDiscoveryDisabled = @{
                ConfigurationName               = $null
                DependsOn                       = $null
                ModuleName                      = 'ConfigMgrCBDsc'
                ModuleVersion                   = 1.0.1
                PsDscRunAsCredential            = $null
                ResourceId                      = $null
                SourceInfo                      = $null
                ADContainers                    = $null
                ADContainersToExclude           = $null
                ADContainersToInclude           = $null
                DeltaDiscoveryMins              = $null
                Enabled                         = $false
                EnableDeltaDiscovery            = $false
                ScheduleCount                   = $null
                ScheduleInterval                = $null
                EnableFilteringExpiredLogon     = $null
                EnableFilteringExpiredPassword  = $null
                TimeSinceLastLogonDays          = $null
                TimeSinceLastPasswordUpdateDays = $null
                SiteCode                        = 'Lab'
                PSComputerName                  = 'localhost'
            }

            $userDiscovery = @{
                SiteCode = 'Lab'
                Include  = 'UserDiscovery'
            }

            $getUserDiscoveryEnabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'ACTIVE'
                    }
                )
            }

            $getUserDiscoveryDisabled = @{
                SiteCode = 'Lab'
                Props    = @(
                    @{
                        PropertyName = 'Settings'
                        Value1       = 'INACTIVE'
                    }
                )
            }

            $invokeUserDiscoveryEnabled = @{
                ConfigurationName     = $null
                DependsOn             = $null
                ModuleName            = 'ConfigMgrCBDsc'
                ModuleVersion         = 1.0.1
                PsDscRunAsCredential  = $null
                ResourceId            = $null
                SourceInfo            = $null
                ADContainers          = @('LDAP://OU=DC,DC=contoso,DC=com')
                ADContainersToExclude = $null
                ADContainersToInclude = $null
                DeltaDiscoveryMins    = 30
                Enabled               = $true
                EnableDeltaDiscovery  = $true
                ScheduleCount         = 40
                ScheduleInterval      = 'Minutes'
                SiteCode              = 'Lab'
                PSComputerName        = 'localhost'
            }

            $invokeUserDiscoveryDisabled = @{
                ConfigurationName     = $null
                DependsOn             = $null
                ModuleName            = 'ConfigMgrCBDsc'
                ModuleVersion         = 1.0.1
                PsDscRunAsCredential  = $null
                ResourceId            = $null
                SourceInfo            = $null
                ADContainers          = $null
                ADContainersToExclude = $null
                ADContainersToInclude = $null
                DeltaDiscoveryMins    = $null
                Enabled               = $false
                EnableDeltaDiscovery  = $false
                ScheduleCount         = $null
                ScheduleInterval      = $null
                SiteCode              = 'Lab'
                PSComputerName        = 'localhost'
            }

            $testAll = @{
                SiteCode         = 'Lab'
                Include          = 'All'
                Exclude          = @('PullDistributionPoint','PxeDistributionPoint','SiteMaintenance',
                                    'BoundaryGroups','MaintenanceWindow')
                DataFile         = 'TestDrive:\tmp.psd1'
                ConfigOutputPath = 'TestDrive:\temp.ps1'
                MofOutPutPath    = 'TestDrive:\'
            }

            $maintenanceWindow = @{
                SiteCode = 'Lab'
                Include  = 'MaintenanceWindow'
            }

            $getCMMaintenanceWindow = @{
                IsEnabled         = $true
                IsGMT             = $false
                Name              = 'WeeklyMW'
                RecurrenceType    = 2
                ServiceWindowType = 5
            }

            $invokeCMMaintenanceWindows = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                CollectionName       = 'TestCollection'
                CollectionStatus     = 'Present'
                DayOfMonth           = $null
                DayOfWeek            = 'Tuesday'
                Description          = 'Occurs every 1 weeks on Tuesday effective 2/1/2021 12:00 AM'
                Ensure               = 'Present'
                HourDuration         = 1
                IsEnabled            = $true
                MinuteDuration       = $null
                MonthlyWeekOrder     = $null
                Name                 = 'Test'
                RecurInterval        = 1
                ScheduleType         = 'Weekly'
                ServiceWindowsType   = 'Any'
                SiteCode             = 'Lab'
                Start                = '2/1/2021 00:00'
                PSComputerName       = 'localhost'
            }

            $boundaryGroup = @{
                SiteCode = 'Lab'
                Include  = 'BoundaryGroups'
            }

            $getCMBoundaryGroup = @{
                Name = 'TestBoundary'
            }

            $invokeCMBoundaryGroup = @{
                ConfigurationName       = $null
                DependsOn               = $null
                ModuleName              = 'ConfigMgrCBDsc'
                ModuleVersion           = 1.0.1
                PsDscRunAsCredential    = $null
                ResourceId              = $null
                SourceInfo              = $null
                BoundaryGroup           = 'TestBoundary'
                Ensure                  = 'Present'
                SecurityScopes          = @('Default')
                SecurityScopesToExclude = $null
                SecurityScopesToInclude = $null
                SiteCode                = 'Lab'
                PSComputerName          = 'localhost'
            }

            $configFileOnly = @{
                SiteCode         = 'Lab'
                Include          = 'ConfigFileOnly'
                DataFile         = 'TestDrive:\tmp.psd1'
                ConfigOutputPath = 'TestDrive:\temp.ps1'
                MofOutPutPath    = 'TestDrive:\'
            }

            $getCMClientSettingsDefault = @(
                @{
                    Name = 'Default Client Agent Settings'
                    Type = 0
                }
            )

            $getCMClientSettingsDevice = @(
                @{
                    Name = 'ClientTest'
                    Type = 1
                }
            )

            $getCMClientSettingsUser = @(
                @{
                    Name = 'TestUser'
                    Type = 2
                }
            )

            $clientSettingsDevice = @{
                SiteCode = 'Lab'
                Include  = 'ClientSettings'
            }

            $invokeCMClientSettings = @{
                ConfigurationName       = $null
                DependsOn               = $null
                ModuleName              = 'ConfigMgrCBDsc'
                ModuleVersion           = 1.0.1
                PsDscRunAsCredential    = $null
                ResourceId              = $null
                SourceInfo              = $null
                ClientSettingName       = 'ClientTest'
                Description             = 'Test Client Policy'
                Ensure                  = 'Present'
                SecurityScopes          = @('Scope1','Scope2')
                SecurityScopesToInclude = $null
                SecurityScopesToExclude = $null
                Type                    = 'Device'
                SiteCode                = 'Lab'
                PSComputerName          = 'localhost'
            }

            $invokeCMClientSettingsBits = @{
                ConfigurationName          = $null
                DependsOn                  = $null
                ModuleName                 = 'ConfigMgrCBDsc'
                ModuleVersion              = 1.0.1
                PsDscRunAsCredential       = $null
                ResourceId                 = $null
                SourceInfo                 = $null
                ClientSettingName          = 'Default Client Agent Settings'
                EnableBitsMaxBandwidth     = $true
                MaxBandwidthBeginHr        = 1
                MaxBandwidthEndHr          = 23
                MaxTransferRateOnSchedule  = 100
                EnableDownloadOffSchedule  = $true
                MaxTransferRateOffSchedule = 1000
                ClientSettingStatus        = 'Present'
                ClientType                 = 'Default'
                SiteCode                   = 'Lab'
                PSComputerName             = 'localhost'
            }

            $invokeCMClientSettingsClientCache = @{
                ConfigurationName         = $null
                DependsOn                 = $null
                ModuleName                = 'ConfigMgrCBDsc'
                ModuleVersion             = 1.0.1
                PsDscRunAsCredential      = $null
                ResourceId                = $null
                SourceInfo                = $null
                ClientSettingName         = 'Default Client Agent Settings'
                ConfigureBranchCache      = $true
                EnableBranchCache         = $true
                MaxBranchCacheSizePercent = 20
                ConfigureCacheSize        = $true
                MaxCacheSize              = 1048576
                MaxCacheSizePercent       = 80
                EnableSuperPeer           = $true
                BroadcastPort             = 8006
                DownloadPort              = 8003
                ClientSettingStatus       = 'Present'
                ClientType                = 'Default'
                SiteCode                  = 'Lab'
                PSComputerName            = 'localhost'
            }

            $invokeCMClientSettingsClientPolicy = @{
                ConfigurationName          = $null
                DependsOn                  = $null
                ModuleName                 = 'ConfigMgrCBDsc'
                ModuleVersion              = 1.0.1
                PsDscRunAsCredential       = $null
                ResourceId                 = $null
                SourceInfo                 = $null
                ClientSettingName          = 'Default Client Agent Settings'
                PolicyPollingMins          = 60
                EnableUserPolicy           = $true
                EnableUserPolicyOnInternet = $false
                EnableUserPolicyOnTS       = $true
                ClientSettingStatus        = 'Present'
                ClientType                 = 'Default'
                SiteCode                   = 'Lab'
                PSComputerName             = 'localhost'
            }

            $invokeCMClientSettingsCloudService = @{
                ConfigurationName           = $null
                DependsOn                   = $null
                ModuleName                  = 'ConfigMgrCBDsc'
                ModuleVersion               = 1.0.1
                PsDscRunAsCredential        = $null
                ResourceId                  = $null
                SourceInfo                  = $null
                ClientSettingName           = 'Default Client Agent Settings'
                AllowCloudDistributionPoint = $true
                AutoAzureADJoin             = $true
                AllowCloudManagementGateway = $true
                ClientSettingStatus         = 'Present'
                ClientType                  = 'Default'
                SiteCode                    = 'Lab'
                PSComputerName              = 'localhost'
            }

            $clientSettingsCloudUser = @{
                SiteCode = 'Lab'
                Include  = 'ClientSettingsCloudService'
            }

            $invokeCMClientSettingsCloudServiceUser = @{
                ConfigurationName           = $null
                DependsOn                   = $null
                ModuleName                  = 'ConfigMgrCBDsc'
                ModuleVersion               = 1.0.1
                PsDscRunAsCredential        = $null
                ResourceId                  = $null
                SourceInfo                  = $null
                ClientSettingName           = 'TestUser'
                AllowCloudDistributionPoint = $true
                AutoAzureADJoin             = $null
                AllowCloudManagementGateway = $null
                ClientSettingStatus         = 'Present'
                ClientType                  = 'User'
                SiteCode                    = 'Lab'
                PSComputerName              = 'localhost'
            }

            $invokeCMClientSettingsCompliance = @{
                ConfigurationName        = $null
                DependsOn                = $null
                ModuleName               = 'ConfigMgrCBDsc'
                ModuleVersion            = 1.0.1
                PsDscRunAsCredential     = $null
                ResourceId               = $null
                SourceInfo               = $null
                ClientSettingName        = 'Default Client Agent Settings'
                Enable                   = $true
                EnableUserDataAndProfile = $true
                Start                    = '9/21/2021 16:54'
                ScheduleType             = 'MonthlyByDay'
                DayOfWeek                = $null
                MonthlyWeekOrder         = $null
                DayofMonth               = 0
                RecurInterval            = 1
                ClientSettingStatus      = 'Present'
                ClientType               = 'Default'
                SiteCode                 = 'Lab'
                PSComputerName           = 'localhost'
            }

            $invokeCMClientSettingsComputerAgent = @{
                ConfigurationName              = $null
                DependsOn                      = $null
                ModuleName                     = 'ConfigMgrCBDsc'
                ModuleVersion                  = 1.0.1
                PsDscRunAsCredential           = $null
                ResourceId                     = $null
                SourceInfo                     = $null
                ClientSettingName              = 'Default Client Agent Settings'
                InitialReminderHr              = 5
                InterimReminderHr              = 1
                FinalReminderMins              = 20
                BrandingTitle                  = 'Test Client'
                UseNewSoftwareCenter           = $true
                EnableHealthAttestation        = $true
                UseOnPremisesHealthAttestation = $true
                InstallRestriction             = 'OnlyAdministrators'
                SuspendBitLocker               = 'Never'
                EnableThirdPartyOrchestration  = 'Yes'
                PowerShellExecutionPolicy      = 'Bypass'
                DisplayNewProgramNotification  = $true
                ClientSettingStatus            = 'Present'
                ClientType                     = 'Default'
                SiteCode                       = 'Lab'
                PSComputerName                 = 'localhost'
            }

            $invokeCMClientSettingsDelivery = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                ClientSettingName    = 'Default Client Agent Settings'
                Enable               = $true
                ClientSettingStatus  = 'Present'
                ClientType           = 'Default'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeCMClientSettingsHardwareDefault = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                ClientSettingName    = 'Default Client Agent Settings'
                Enable               = $true
                MaxRandomDelayMins   = 30
                Start                = '9/21/2021 16:54'
                ScheduleType         = 'MonthlyByDay'
                DayOfWeek            = $null
                MonthlyWeekOrder     = $null
                DayofMonth           = 0
                RecurInterval        = 1
                CollectMifFile       = 'None'
                MaxThirdPartyMifSize = 5119
                ClientSettingStatus  = 'Present'
                ClientType           = 'Default'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $clientSettingsHardwareDevice = @{
                SiteCode = 'Lab'
                Include  = 'ClientSettingsHardware'
            }

            $invokeCMClientSettingsHardwareDevice = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                ClientSettingName    = 'ClientTest'
                Enable               = $true
                MaxRandomDelayMins   = 30
                Start                = '9/21/2021 16:54'
                ScheduleType         = 'MonthlyByDay'
                DayOfWeek            = $null
                MonthlyWeekOrder     = $null
                DayofMonth           = 0
                RecurInterval        = 1
                ClientSettingStatus  = 'Present'
                ClientType           = 'Device'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeCMClientSettingsMetered = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                ClientSettingName    = 'Default Client Agent Settings'
                MeteredNetworkUsage  = 'Allow'
                ClientSettingStatus  = 'Present'
                ClientType           = 'Default'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeCMClientSettingsPower = @{
                ConfigurationName               = $null
                DependsOn                       = $null
                ModuleName                      = 'ConfigMgrCBDsc'
                ModuleVersion                   = 1.0.1
                PsDscRunAsCredential            = $null
                ResourceId                      = $null
                SourceInfo                      = $null
                ClientSettingName               = 'Default Client Agent Settings'
                Enable                          = $true
                AllowUserToOptOutFromPowerPlan  = $false
                NetworkWakeUpOption             = 'Enabled'
                EnableWakeUpProxy               = $true
                WakeupProxyPort                 = 51
                WakeOnLanPort                   = 50
                FirewallExceptionForWakeupProxy = 'None'
                WakeupProxyDirectAccessPrefix   = $null
                ClientSettingStatus             = 'Present'
                ClientType                      = 'Default'
                SiteCode                        = 'Lab'
                PSComputerName                  = 'localhost'
            }

            $getCMClientSettingRemoteTools = @{
                FirewallExceptionProfiles = 12
            }

            $invokeCMClientSettingsRemoteTools = @{
                ConfigurationName                   = $null
                DependsOn                           = $null
                ModuleName                          = 'ConfigMgrCBDsc'
                ModuleVersion                       = 1.0.1
                PsDscRunAsCredential                = $null
                ResourceId                          = $null
                SourceInfo                          = $null
                ClientSettingName                   = 'Default Client Agent Settings'
                FirewallExceptionProfile            = 'Domain'
                AllowClientChange                   = $true
                AllowUnattendedComputer             = $true
                PromptUserForPermission             = $true
                PromptUserForClipboardPermission    = $true
                GrantPermissionToLocalAdministrator = $true
                AccessLevel                         = 'FullControl'
                PermittedViewer                     = @('Group1','Group2')
                ShowNotificationIconOnTaskbar       = $true
                ShowSessionConnectionBar            = $true
                AudibleSignal                       = 'PlayNoSound'
                ManageUnsolicitedRemoteAssistance   = $true
                ManageSolicitedRemoteAssistance     = $true
                RemoteAssistanceAccessLevel         = 'FullControl'
                ManageRemoteDesktopSetting          = $true
                AllowPermittedViewer                = $true
                RequireAuthentication               = $true
                ClientSettingStatus                 = 'Present'
                ClientType                          = 'Default'
                RemoteToolsStatus                   = 'Enabled'
                SiteCode                            = 'Lab'
                PSComputerName                      = 'localhost'
            }

            $getCMClientSettingSoftwareCenter = @{
                SC_UserPortal = 0
            }

            $invokeCMClientSettingsSoftwareCenter = @{
                ConfigurationName          = $null
                DependsOn                  = $null
                ModuleName                 = 'ConfigMgrCBDsc'
                ModuleVersion              = 1.0.1
                PsDscRunAsCredential       = $null
                ResourceId                 = $null
                SourceInfo                 = $null
                ClientSettingName          = 'Default Client Agent Settings'
                EnableCustomize            = $true
                CompanyName                = 'Test Company'
                ColorScheme                = '#CB4154'
                HideApplicationCatalogLink = $true
                HideInstalledApplication   = $true
                HideUnapprovedApplication  = $true
                EnableApplicationsTab      = $true
                EnableUpdatesTab           = $true
                EnableOperatingSystemsTab  = $true
                EnableStatusTab            = $true
                EnableComplianceTab        = $true
                EnableOptionsTab           = $true
                ClientSettingStatus        = 'Present'
                ClientType                 = 'Default'
                PortalType                 = 'Software Center'
                SiteCode                   = 'Lab'
                PSComputerName             = 'localhost'
            }

            $invokeCMClientSettingsSoftwareDeployment = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                ClientSettingName    = 'Default Client Agent Settings'
                Start                = '9/21/2021 16:54'
                ScheduleType         = 'MonthlyByDay'
                DayOfWeek            = $null
                MonthlyWeekOrder     = $null
                DayofMonth           = 0
                RecurInterval        = 1
                ClientSettingStatus  = 'Present'
                ClientType           = 'Default'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeCMClientSettingsSoftwareInventory = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                ClientSettingName    = 'Default Client Agent Settings'
                Enable               = $true
                ReportOption         = 'ProductOnly'
                Start                = '9/21/2021 16:54'
                ScheduleType         = 'MonthlyByDay'
                DayOfWeek            = $null
                MonthlyWeekOrder     = $null
                DayofMonth           = 0
                RecurInterval        = 1
                ClientSettingStatus  = 'Present'
                ClientType           = 'Default'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeCMClientSettingsSoftwareMetering = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                ClientSettingName    = 'Default Client Agent Settings'
                Enable               = $true
                Start                = '9/21/2021 16:54'
                ScheduleType         = 'MonthlyByDay'
                DayOfWeek            = $null
                MonthlyWeekOrder     = $null
                DayofMonth           = 0
                RecurInterval        = 1
                ClientSettingStatus  = 'Present'
                ClientType           = 'Default'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeCMClientSettingsSoftwareUpdate = @{
                ConfigurationName       = $null
                DependsOn               = $null
                ModuleName              = 'ConfigMgrCBDsc'
                ModuleVersion           = 1.0.1
                PsDscRunAsCredential    = $null
                ResourceId              = $null
                SourceInfo              = $null
                ClientSettingName       = 'Default Client Agent Settings'
                Enable                  = $true
                ScanStart               = '9/21/2021 16:54'
                ScanScheduleType        = 'MonthlyByDay'
                ScanDayOfWeek           = $null
                ScanMonthlyWeekOrder    = $null
                ScanDayofMonth          = 0
                ScanRecurInterval       = 1
                EvalStart               = '9/21/2021 16:54'
                EvalScheduleType        = 'Hours'
                EvalDayOfWeek           = $null
                EvalMonthlyWeekOrder    = $null
                EvalDayofMonth          = $null
                EvalRecurInterval       = 1
                EnforceMandatory        = $true
                TimeUnit                = 'Days'
                BatchingTimeOut         = 2
                EnableDeltaDownload     = $true
                DeltaDownloadPort       = 8005
                Office365ManagementType = 'Yes'
                EnableThirdPartyUpdates = $true
                ClientSettingStatus     = 'Present'
                ClientType              = 'Default'
                SiteCode                = 'Lab'
                PSComputerName          = 'localhost'
            }

            $invokeCMClientSettingsStateMessaging = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                ClientSettingName    = 'Default Client Agent Settings'
                ReportingCycleMins   = 100
                ClientSettingStatus  = 'Present'
                ClientType           = 'Default'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $invokeCMClientSettingsUserDeviceAffinity = @{
                ConfigurationName    = $null
                DependsOn            = $null
                ModuleName           = 'ConfigMgrCBDsc'
                ModuleVersion        = 1.0.1
                PsDscRunAsCredential = $null
                ResourceId           = $null
                SourceInfo           = $null
                ClientSettingName    = 'Default Client Agent Settings'
                LogOnThresholdMins   = 100
                UsageThresholdDays   = 10
                AutoApproveAffinity  = $true
                AllowUserAffinity    = $true
                ClientSettingStatus  = 'Present'
                ClientType           = 'Default'
                SiteCode             = 'Lab'
                PSComputerName       = 'localhost'
            }

            $siteConfig = @{
                SiteCode = 'Lab'
                Include  = 'SiteConfiguration'
            }

            $invokeSiteConfigurationPri = @{
                ConfigurationName                                 = $null
                DependsOn                                         = $null
                ModuleName                                        = 'ConfigMgrCBDsc'
                ModuleVersion                                     = 1.0.1
                PsDscRunAsCredential                              = $null
                ResourceId                                        = $null
                SourceInfo                                        = $null
                SiteCode                                          = 'Lab'
                Comment                                           = 'Site Lab'
                ClientComputerCommunicationType                   = 'HttpsOrHttp'
                ClientCheckCertificateRevocationListForSiteSystem = $true
                UsePkiClientCertificate                           = $false
                UseSmsGeneratedCert                               = $true
                RequireSigning                                    = $true
                RequireSha256                                     = $false
                UseEncryption                                     = $false
                MaximumConcurrentSendingForAllSite                = 6
                MaximumConcurrentSendingForPerSite                = 3
                RetryNumberForConcurrentSending                   = 2
                ConcurrentSendingDelayBeforeRetryingMins          = 10
                EnableLowFreeSpaceAlert                           = $true
                FreeSpaceThresholdWarningGB                       = 10
                FreeSpaceThresholdCriticalGB                      = 5
                ThresholdOfSelectCollectionByDefault              = 100
                ThresholdOfSelectCollectionMax                    = 1000
                SiteSystemCollectionBehavior                      = 'Warn'
                SiteType                                          = 'Primary'
                EnableWakeOnLan                                   = $true
                WakeOnLanTransmissionMethodType                   = 'Unicast'
                RetryNumberOfSendingWakeupPacketTransmission      = 1
                SendingWakeupPacketTransmissionDelayMins          = 10000
                MaximumNumberOfSendingWakeupPacketBeforePausing   = 10
                SendingWakeupPacketBeforePausingWaitSec           = 3
                ThreadNumberOfSendingWakeupPacket                 = 10
                SendingWakeupPacketTransmissionOffsetMins         = 10
                ClientCertificateCustomStoreName                  = 'SMSStore'
                TakeActionForMultipleCertificateMatchCriteria     = 'SelectCertificateWithLongestValidityPeriod'
                ClientCertificateSelectionCriteriaType            = 'ClientAuthentication'
                ClientCertificateSelectionCriteriaValue           = 'Personal'
                PSComputerName                                    = 'localhost'
            }

            $invokeSiteConfigurationCas = @{
                ConfigurationName                        = $null
                DependsOn                                = $null
                ModuleName                               = 'ConfigMgrCBDsc'
                ModuleVersion                            = 1.0.1
                PsDscRunAsCredential                     = $null
                ResourceId                               = $null
                SourceInfo                               = $null
                SiteCode                                 = 'Lab'
                Comment                                  = 'Lab Site CAS'
                MaximumConcurrentSendingForAllSite       = 5
                MaximumConcurrentSendingForPerSite       = 3
                RetryNumberForConcurrentSending          = 10
                ConcurrentSendingDelayBeforeRetryingMins = 5
                ThresholdOfSelectCollectionByDefault     = 100
                ThresholdOfSelectCollectionMax           = 0
                SiteSystemCollectionBehavior             = 'Block'
                PSComputerName                           = 'localhost'
            }

            $invokeHierarchySetting = @{
                ConfigurationName                  = $null
                DependsOn                          = $null
                ModuleName                         = 'ConfigMgrCBDsc'
                ModuleVersion                      = 1.0.1
                PsDscRunAsCredential               = $null
                ResourceId                         = $null
                SourceInfo                         = $null
                AllowPrestage                      = $true
                ApprovalMethod                     = 'AutomaticallyApproveComputersInTrustedDomains'
                AutoResolveClientConflict          = $true
                EnableAutoClientUpgrade            = $true
                EnableExclusionCollection          = $true
                EnablePreProduction                = $true
                EnablePrereleaseFeature            = $true
                ExcludeServer                      = $true
                PreferBoundaryGroupManagementPoint = $true
                UseFallbackSite                    = $true
                AutoUpgradeDays                    = 10
                ExclusionCollectionName            = 'Exclusions'
                FallbackSiteCode                   = 'FB1'
                TargetCollectionName               = 'Preprod'
                TelemetryLevel                     = 'Enhanced'
                SiteCode                           = 'LAB'
                PSComputerName                     = 'localhost'
            }
        }

        Context 'When running the Set-ConfigMgrCBDscReverse' {
            BeforeEach {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }
                Mock -CommandName Get-CMAdministrativeUser -MockWith { $cmAdministrativeUsers }
                Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint -MockWith { $cmAssetIntellReturn }
                Mock -CommandName Get-CMClientSetting
                Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionsReturn } -ParameterFilter {$CollectionType -match 'Device'}
                Mock -CommandName Get-CMCollection -MockWith { $userCollectionsReturn } -ParameterFilter {$CollectionType -match 'User' }
                Mock -CommandName Get-CMDistributionPointGroup -MockWith { $distributionGroupReturn }
                Mock -CommandName Get-CMDistributionPoint -MockWith { $getDistroPointReturn }
                Mock -CommandName Get-CMFallbackStatusPoint -MockWith { $getFallBackStatusReturn }
                Mock -CommandName Get-CMDiscoveryMethod
                Mock -CommandName Get-CMManagementPoint
                Mock -CommandName Get-CMDistributionPointInfo
                Mock -CommandName Get-CMReportingServicePoint
                Mock -CommandName Get-CMSecurityScope
                Mock -CommandName Get-CMServiceConnectionPoint
                Mock -CommandName Get-CMSiteDefinition
                Mock -CommandName Get-CMSite
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName Get-CMSoftwareUpdatePoint
                Mock -CommandName Get-CMMaintenanceWindow
                Mock -CommandName Get-CMBoundaryGroup
                Mock -CommandName Remove-Item
                Mock -CommandName Add-Content
                Mock -CommandName Test-Path -MockWith { $true }
                Mock -CommandName New-Configuration
            }

            It 'Should call expected commands when specifying all with some excluded resources' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMAccounts } -ParameterFilter { $Name -eq 'CMAccounts' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMAdministrativeUser } -ParameterFilter { $Name -eq 'CMAdministrativeUser' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMAssetIntelligencePoint } -ParameterFilter { $Name -eq 'CMAssetIntelligencePoint' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeClientPushSetting } -ParameterFilter { $Name -eq 'CMClientPushSettings' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeClientStatusSetting } -ParameterFilter { $Name -eq 'CMClientStatusSettings' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCollEval } -ParameterFilter { $Name -eq 'CMCollectionMembershipEvaluationComponent' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeDeviceCollections } -ParameterFilter { $CollectionName -eq 'TestCollection' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeUserCollections } -ParameterFilter { $CollectionName -eq 'UserCollection' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMDistributionGroup } -ParameterFilter { $Name -eq 'CMDistributionGroup' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMDistributionPoint } -ParameterFilter { $Name -eq 'CMDistributionPoint' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMDistributionGroupMembers } -ParameterFilter { $Name -eq 'CMDistributionPointGroupMembers' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeEmailComponent } -ParameterFilter { $Name -eq 'CMEmailNotificationComponent' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeFallbackPoints } -ParameterFilter { $Name -eq 'CMFallbackStatusPoint' }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getForestDiscoveryEnabled } -ParameterFilter { $Name -eq 'ActiveDirectoryForestDiscovery' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeForestDiscoveryEnabled } -ParameterFilter { $Name -eq 'CMForestDiscovery' }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getGroupDiscoveryEnabled } -ParameterFilter { $Name -eq 'ActiveDirectoryGroupDiscovery' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeGroupDiscoveryEnabled } -ParameterFilter { $Name -eq 'CMGroupDiscovery' }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getHeartbeatDiscoveryEnabled } -ParameterFilter { $Name -eq 'HeartbeatDiscovery' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeHeartbeatDiscoveryEnabled } -ParameterFilter { $Name -eq 'CMHeartbeatDiscovery' }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getNetworkDiscoveryEnabled } -ParameterFilter { $Name -eq 'NetworkDiscovery' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeNetworkDiscovery } -ParameterFilter { $Name -eq 'CMNetworkDiscovery' }
                Mock -CommandName Get-CMManagementPoint -MockWith { $getManagementPointNonSiteDatabase }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeManagementPointUseNonSiteDatabase } -ParameterFilter { $Name -eq 'CMManagementPoint' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeReportingServices } -ParameterFilter { $Name -eq 'CMReportingServicePoint' }
                Mock -CommandName Get-CMReportingServicePoint -MockWith { $getReportingServicesReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSecurityScopes } -ParameterFilter { $Name -eq 'CMSecurityScopes' }
                Mock -CommandName Get-CMSecurityScope -MockWith { $getSecurityScopesReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeServiceConnectionPoint } -ParameterFilter { $Name -eq 'CMServiceConnectionPoint' }
                Mock -CommandName Get-CMServiceConnectionPoint -MockWith { $getServiceConnectionPoint }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSiteSystemNonProxy } -ParameterFilter { $Name -eq 'CMSiteSystemServer' }
                Mock -CommandName Get-CMSiteSystemServer -MockWith { $getCMSiteSystemsMachineAccount }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSoftwareDistro } -ParameterFilter { $Name -eq 'CMSoftwareDistributionComponent' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSoftwareUpdate } -ParameterFilter { $Name -eq 'CMSoftwareUpdatePoint' }
                Mock -CommandName Get-CMSoftwareUpdatePoint -MockWith { $getSoftwareUpdatePoint }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSoftwareUpdatePointComponent } -ParameterFilter { $Name -eq 'CMSoftwareUpdatePointComponent' }
                Mock -CommandName Get-CMSite -MockWith { $null }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeReportingComponent } -ParameterFilter { $Name -eq 'CMStatusReportingComponent' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSystemDiscoveryEnabled } -ParameterFilter { $Name -eq 'CMSystemDiscovery' }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getSystemDiscoveryEnabled } -ParameterFilter { $Name -eq 'ActiveDirectorySystemDiscovery' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeUserDiscoveryEnabled } -ParameterFilter { $Name -eq 'CMUserDiscovery' }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getUserDiscoveryEnabled } -ParameterFilter { $Name -eq 'ActiveDirectoryUserDiscovery' }
                Mock -CommandName Get-CMClientSetting -MockWith { $getCMClientSettingsDefault }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsBits } -ParameterFilter { $Name -eq 'CMClientSettingsBits' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsClientCache } -ParameterFilter { $Name -eq 'CMClientSettingsClientCache' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsClientPolicy } -ParameterFilter { $Name -eq 'CMClientSettingsClientPolicy' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsCloudService } -ParameterFilter { $Name -eq 'CMClientSettingsCloudService' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsCompliance } -ParameterFilter { $Name -eq 'CMClientSettingsCompliance' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsComputerAgent } -ParameterFilter { $Name -eq 'CMClientSettingsComputerAgent' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsDelivery } -ParameterFilter { $Name -eq 'CMClientSettingsDelivery' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsHardwareDefault } -ParameterFilter { $Name -eq 'CMClientSettingsHardware' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsMetered } -ParameterFilter { $Name -eq 'CMClientSettingsMetered' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsPower } -ParameterFilter { $Name -eq 'CMClientSettingsPower' }
                Mock -CommandName Get-CMClientSetting -MockWith { $getCMClientSettingRemoteTools } -ParameterFilter { $Setting -eq 'RemoteTools' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsRemoteTools } -ParameterFilter { $Name -eq 'CMClientSettingsRemoteTools' }
                Mock -CommandName Get-CMClientSetting -MockWith { $getCMClientSettingSoftwareCenter } -ParameterFilter { $Setting -eq 'SoftwareCenter' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsSoftwareCenter } -ParameterFilter { $Name -eq 'CMClientSettingsSoftwareCenter' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsSoftwareDeployment } -ParameterFilter { $Name -eq 'CMClientSettingsSoftwareDeployment' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsSoftwareInventory } -ParameterFilter { $Name -eq 'CMClientSettingsSoftwareInventory' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsSoftwareMetering } -ParameterFilter { $Name -eq 'CMClientSettingsSoftwareMetering' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsUpdate } -ParameterFilter { $Name -eq 'CMClientSettingsSoftwareUpdate' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsStateMessaging } -ParameterFilter { $Name -eq 'CMClientSettingsStateMessaging' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsUserDeviceAffinity } -ParameterFilter { $Name -eq 'CMClientSettingsUserDeviceAffinity' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSiteConfigurationCas } -ParameterFilter { $Name -eq 'CMSiteConfiguration' }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeHierarchySetting } -ParameterFilter { $Name -eq 'CMHierarchySetting' }

                $result = Set-ConfigMgrCBDscReverse @testAll
                $result | Should -BeOfType System.String
                Assert-MockCalled Get-CMAccount -Exactly -Times 1 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 48 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 19 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 6 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSite -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 1 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 1 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 1 -Scope It
            }

            It 'Should return expected results and call expected commands for Forest Discovery Disabled' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeForestDiscoveryDisabled }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getForestDiscoveryDisabled } -ParameterFilter { $Name -eq 'ActiveDirectoryForestDiscovery' }

                $result = Set-ConfigMgrCBDscReverse @forestDiscovery
                $result | Should -BeOfType System.String
                $result | Should -Match 'CMForestDiscovery'
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Heartbeat Discovery Disabled' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeHeartbeatDiscoveryDisabled } -ParameterFilter { $Name -eq 'CMHeartbeatDiscovery' }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getHeartbeatDiscoveryDisabled } -ParameterFilter { $Name -eq 'HeartbeatDiscovery' }

                $result = Set-ConfigMgrCBDscReverse @heartbeatDiscovery
                $result | Should -BeOfType System.String
                $result | Should -Match "CMHeartbeatDiscovery"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Group Discovery Disabled' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeGroupDiscoveryDisabled } -ParameterFilter { $Name -eq 'CMGroupDiscovery' }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getGroupDiscoveryDisabled } -ParameterFilter { $Name -eq 'ActiveDirectoryGroupDiscovery' }

                $result = Set-ConfigMgrCBDscReverse @groupDiscovery
                $result | Should -BeOfType System.String
                $result | Should -Match "CMGroupDiscovery"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Management Point site database' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeManagementPointUseSiteDatabase }
                Mock -CommandName Get-CMManagementPoint -MockWith { $getManagementPointSiteDatabase }

                $result = Set-ConfigMgrCBDscReverse @managementPoint
                $result | Should -BeOfType System.String
                $result | Should -Match "CMManagementPoint"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Pull Distribution Point' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokePullDP }
                Mock -CommandName Get-CMDistributionPointInfo -MockWith { $getCMDistributionPointInfo }

                $result = Set-ConfigMgrCBDscReverse @pullDP
                $result | Should -BeOfType System.String
                $result | Should -Match "CMPullDistributionPoint"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for PXE Distribution Point' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokePxeDP }
                Mock -CommandName Get-CMDistributionPointInfo -MockWith { $getCMDistributionPointInfo }

                $result = Set-ConfigMgrCBDscReverse @pxeDP
                $result | Should -BeOfType System.String
                $result | Should -Match "CMPxeDistributionPoint"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for PXE Distribution Point with password' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokePxeDP }
                Mock -CommandName Get-CMDistributionPointInfo -MockWith { $getCMDistributionPointPxePW }

                $result = Set-ConfigMgrCBDscReverse @pxeDP
                $result | Should -BeOfType System.String
                $result | Should -Match "CMPxeDistributionPoint"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Site Maintenance CAS' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSiteMaintenanceBackup }
                Mock -CommandName Get-CMSiteDefinition -MockWith { $getCMDefinitionCas }

                $result = Set-ConfigMgrCBDscReverse @siteMaintenance
                $result | Should -BeOfType System.String
                $result | Should -Match "CMSiteMaintenance"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 19 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Site Maintenance Primary' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSiteMaintenanceAppCat }
                Mock -CommandName Get-CMSiteDefinition -MockWith { $getCMDefinitionPrimary }

                $result = Set-ConfigMgrCBDscReverse @siteMaintenance
                $result | Should -BeOfType System.String
                $result | Should -Match "CMSiteMaintenance"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 43 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Site Maintenance Primary delete task' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSiteMaintenanceDelete }
                Mock -CommandName Get-CMSiteDefinition -MockWith { $getCMDefinitionPrimary }

                $result = Set-ConfigMgrCBDscReverse @siteMaintenance
                $result | Should -BeOfType System.String
                $result | Should -Match "CMSiteMaintenance"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 43 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Site Maintenance Primary summerize task' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSiteMaintenanceSummary }
                Mock -CommandName Get-CMSiteDefinition -MockWith { $getCMDefinitionPrimary }

                $result = Set-ConfigMgrCBDscReverse @siteMaintenance
                $result | Should -BeOfType System.String
                $result | Should -Match "CMSiteMaintenance"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 43 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Site Maintenance Primary disabled Task' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSiteMaintenanceDisabled }
                Mock -CommandName Get-CMSiteDefinition -MockWith { $getCMDefinitionPrimary }

                $result = Set-ConfigMgrCBDscReverse @siteMaintenance
                $result | Should -BeOfType System.String
                $result | Should -Match "CMSiteMaintenance"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 43 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Site Configuration Primary' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSiteConfigurationPri }
                Mock -CommandName Get-CMSiteDefinition -MockWith { $getCMDefinitionPrimary }

                $result = Set-ConfigMgrCBDscReverse @siteConfig
                $result | Should -BeOfType System.String
                $result | Should -Match "CMSiteConfiguration"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Site System Server' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSiteSystemProxy }
                Mock -CommandName Get-CMSiteSystemServer -MockWith { $getCMSiteSystemsProxy }

                $result = Set-ConfigMgrCBDscReverse @siteSystem
                $result | Should -BeOfType System.String
                $result | Should -Match "CMSiteSystemServer"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for System Discovery disabled' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSystemDiscoveryDisabled }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getSystemDiscoveryDisabled } -ParameterFilter { $Name -eq 'ActiveDirectorySystemDiscovery' }

                $result = Set-ConfigMgrCBDscReverse @systemDiscovery
                $result | Should -BeOfType System.String
                $result | Should -Match "CMSystemDiscovery"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for User Discovery disabled' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeUserDiscoveryDisabled }
                Mock -CommandName Get-CMDiscoveryMethod -MockWith { $getUserDiscoveryDisabled } -ParameterFilter { $Name -eq 'ActiveDirectoryUserDiscovery' }

                $result = Set-ConfigMgrCBDscReverse @userDiscovery
                $result | Should -BeOfType System.String
                $result | Should -Match "CMUserDiscovery"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for Software Update Point Component Child Site' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeSoftwareUpdatePointComponent } -ParameterFilter { $Name -eq 'CMSoftwareUpdatePointComponent'}
                Mock -CommandName Get-CMSite -MockWith { $getCMSite }

                $result = Set-ConfigMgrCBDscReverse @supComponent
                $result | Should -BeOfType System.String
                $result | Should -Match "SoftwareUpdatePointComponent"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSite -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for CMMaintenanceWindows' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMMaintenanceWindows } -ParameterFilter { $Name -eq 'CMMaintenanceWindows'}
                Mock -CommandName Get-CMCollection -MockWith { $deviceCollectionsReturn } -ParameterFilter { $CollectionType -match 'Device' }
                Mock -CommandName Get-CMMaintenanceWindow -MockWith { $getCMMaintenanceWindow }

                $result = Set-ConfigMgrCBDscReverse @maintenanceWindow
                $result | Should -BeOfType System.String
                $result | Should -Match "CMMaintenanceWindows"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for BoundaryGroups' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMBoundaryGroup } -ParameterFilter { $Name -eq 'CMBoundaryGroups'}
                Mock -CommandName Get-CMBoundaryGroup -MockWith { $getCMBoundaryGroup }

                $result = Set-ConfigMgrCBDscReverse @boundaryGroup
                $result | Should -BeOfType System.String
                $result | Should -Match "CMBoundaryGroups"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 1 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for CMClientSettings' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettings } -ParameterFilter { $Name -eq 'CMClientSettings'}
                Mock -CommandName Get-CMClientSetting -MockWith { $getCMClientSettingsDevice }

                $result = Set-ConfigMgrCBDscReverse @clientSettingsDevice
                $result | Should -BeOfType System.String
                $result | Should -Match "CMClientSettings"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for CMClientSettingsCloud User' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsCloudServiceUser } -ParameterFilter { $Name -eq 'CMClientSettingsCloudService'}
                Mock -CommandName Get-CMClientSetting -MockWith { $getCMClientSettingsUser }

                $result = Set-ConfigMgrCBDscReverse @clientSettingsCloudUser
                $result | Should -BeOfType System.String
                $result | Should -Match "CMClientSettingsCloudService"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for CMClientSettingsHardware device' {
                Mock -CommandName Get-DscResource -MockWith { $getDscResourceReturn }
                Mock -CommandName Invoke-DscResource -MockWith { $invokeCMClientSettingsHardwareDevice } -ParameterFilter { $Name -eq 'CMClientSettingsHardware'}
                Mock -CommandName Get-CMClientSetting -MockWith { $getCMClientSettingsDevice }

                $result = Set-ConfigMgrCBDscReverse @clientSettingsHardwareDevice
                $result | Should -BeOfType System.String
                $result | Should -Match "CMClientSettingsHardware"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMClientSetting -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return expected results and call expected commands for ConfigFileOnly' {
                Mock -CommandName Get-DscResource
                Mock -CommandName Invoke-DscResource

                $result = Set-ConfigMgrCBDscReverse @configFileOnly
                $result | Should -BeOfType System.String
                $result | Should -Match "Completed"
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Set-ConfigMgrCBDscReverse throws' {
            BeforeEach {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMAccount
                Mock -CommandName Get-CMAdministrativeUser
                Mock -CommandName Get-CMAssetIntelligenceSynchronizationPoint
                Mock -CommandName Get-CMCollection
                Mock -CommandName Get-CMCollection
                Mock -CommandName Get-CMDistributionPointGroup
                Mock -CommandName Get-CMDistributionPoint
                Mock -CommandName Get-CMFallbackStatusPoint
                Mock -CommandName Get-CMDiscoveryMethod
                Mock -CommandName Get-CMManagementPoint
                Mock -CommandName Get-CMDistributionPointInfo
                Mock -CommandName Get-CMReportingServicePoint
                Mock -CommandName Get-CMSecurityScope
                Mock -CommandName Get-CMServiceConnectionPoint
                Mock -CommandName Get-CMSiteDefinition
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName Get-CMSoftwareUpdatePoint
                Mock -CommandName Get-CMMaintenanceWindow
                Mock -CommandName Get-CMBoundaryGroup
                Mock -CommandName Get-CMSite
                Mock -CommandName Remove-Item
                Mock -CommandName Add-Content
                Mock -CommandName Test-Path
                Mock -CommandName New-Configuration

                $config = @{
                    SiteCode         = 'Lab'
                    Include          = 'ConfigFileOnly'
                    ConfigOutputPath = 'TestDrive:\Temp\config.ps1'
                    DataFile         = 'TestDrive:\Temp\DataFile.psd1'
                }

                $missingParamError = 'When specifying ConfigOutputPath or MofOutputPath, you must specify ConfigOutputPath, MofOutputPath and DataFile.'

                $badDataFile = @{
                    SiteCode = 'Lab'
                    DataFile = 'TestDrive:\temp\DataFile'
                }

                $dataFileError = 'Datafile must end with .psd1.'

                $badConfigFile = @{
                    SiteCode         = 'Lab'
                    ConfigOutputPath = 'TestDrive:\Temp\config'
                }

                $configFileError = 'ConfigOutputPath must end with .ps1.'
            }

            It 'Should return call expected commands and throw when missing MofFileOutput' {
                Mock -CommandName Get-DscResource
                Mock -CommandName Invoke-DscResource

                { Set-ConfigMgrCBDscReverse @config } | Should -Throw -ExpectedMessage $missingParamError
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return call expected commands and throw when datafile does not end with .psd1' {
                Mock -CommandName Get-DscResource
                Mock -CommandName Invoke-DscResource

                { Set-ConfigMgrCBDscReverse @badDataFile } | Should -Throw -ExpectedMessage $dataFileError
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }

            It 'Should return call expected commands and throw when ConfigFile does not end with .ps1' {
                Mock -CommandName Get-DscResource
                Mock -CommandName Invoke-DscResource

                { Set-ConfigMgrCBDscReverse @badConfigFile } | Should -Throw -ExpectedMessage $configFileError
                Assert-MockCalled Get-CMAccount -Exactly -Times 0 -Scope It
                Assert-MockCalled Invoke-DscResource -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAdministrativeUser -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMAssetIntelligenceSynchronizationPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMCollection -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDiscoveryMethod -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMManagementPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMDistributionPointInfo -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMReportingServicePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSecurityScope -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteDefinition -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMSoftwareUpdatePoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMMaintenanceWindow -Exactly -Times 0 -Scope It
                Assert-MockCalled Get-CMBoundaryGroup -Exactly -Times 0 -Scope It
                Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 0 -Scope It
                Assert-MockCalled New-Configuration -Exactly -Times 0 -Scope It
            }
        }
    }

    Describe 'ConfigMgrCBDsc - ConfigMgrCBDsc.ResourceHelper\New-Configuration' -Tag 'Configuration' {

        Context 'When running the New-Configuration' {
            BeforeEach {
                Mock -CommandName Remove-Item
                Mock -CommandName Add-Content

                $config = @{
                    ConfigOutputPath = 'TestDrive:\Temp\config.ps1'
                    DataFile         = 'TestDrive:\Temp\DataFile.psd1'
                    MofOutPutPath    = 'TestDrive:\Temp'
                }
            }

            It 'Should return call expected commands for creating the configuration file' {
                Mock -CommandName Test-Path -MockWith { $false }

                New-Configuration @config
                Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 1 -Scope It
            }

            It 'Should return call expected commands for creating the configuration file when file exists' {
                Mock -CommandName Test-Path -MockWith { $true }

                New-Configuration @config
                Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled Remove-Item -Exactly -Times 1 -Scope It
                Assert-MockCalled Add-Content -Exactly -Times 1 -Scope It
            }
        }
    }
}
