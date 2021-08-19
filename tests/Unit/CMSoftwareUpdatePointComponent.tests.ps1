[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMSoftwareUpdatePointComponent'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Import Stub function
    $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        Describe 'ConfigMgrCBDsc - DSC_CMSoftwareUpdatePointComponent\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Software Update Point Component settings' {
                BeforeEach {
                    $getSiteChild = @{
                        ReportingSiteCode = 'DAD'
                    }

                    $getSiteTop = @{
                        ReportingSiteCode = ''
                    }

                    $getSupConfigProps = @{
                        Props = @(
                            @{
                                PropertyName = 'Call WSUS Cleanup'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'ClientReportingLevel'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'DefaultWSUS'
                                Value2       = 'CA01.Contoso.com'
                            }
                            @{
                                PropertyName = 'DefaultUseParentWSUS'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'ParentWSUS'
                                Value2       = 'parentWsus.Contoso.com'
                            }
                            @{
                                PropertyName = 'SupportedTitleLanguages'
                                Value2       = 'en'
                            }
                            @{
                                PropertyName = 'SupportedUpdateLanguages'
                                Value2       = 'en'
                            }
                            @{
                                PropertyName = 'Sync Supersedence Age For Feature'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'Sync Supersedence Age For NonFeature'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'Sync Supersedence Mode For Feature'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'Sync Supersedence Mode For NonFeature'
                                Value        = 1
                            }
                        )
                    }

                    $getWsusSyncProps = @{
                        Props = @(
                            @{
                                PropertyName = 'Sync ExpressFiles'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'Sync Schedule'
                                Value1       = '0001200000100038'
                            }
                            @{
                                PropertyName = 'EnableThirdPartyUpdates'
                                Value        = 0
                            }
                            @{
                                PropertyName = 'MaxInstallTime-ServicePack'
                                Value        = 3600
                            }
                            @{
                                PropertyName = 'MaxInstallTime-Windows'
                                Value        = 3600
                            }
                        )

                    }

                    $getWsusSyncPropsNoSchedule = @{
                        Props = @(
                            @{
                                PropertyName = 'Sync ExpressFiles'
                                Value        = 0
                            }
                            @{
                                PropertyName = 'Sync Schedule'
                                Value1       = ''
                            }
                            @{
                                PropertyName = 'EnableThirdPartyUpdates'
                                Value        = 1
                            }
                            @{
                                PropertyName = 'MaxInstallTime-ServicePack'
                                Value        = 3600
                            }
                            @{
                                PropertyName = 'MaxInstallTime-Windows'
                                Value        = 3600
                            }
                        )
                    }

                    $getWsusSyncPropsNoManualCert = @{
                        Props = @(
                            @{
                                PropertyName = 'Sync ExpressFiles'
                                Value        = 0
                            }
                            @{
                                PropertyName = 'Sync Schedule'
                                Value1       = ''
                            }
                            @{
                                PropertyName = 'EnableThirdPartyUpdates'
                                Value        = 3
                            }
                            @{
                                PropertyName = 'MaxInstallTime-ServicePack'
                                Value        = 3600
                            }
                            @{
                                PropertyName = 'MaxInstallTime-Windows'
                                Value        = 3600
                            }
                        )

                    }

                    $getSchedule = @{
                        ScheduleType  = 'Days'
                        RecurInterval = 7
                    }

                    $getUpdateCats = @(
                        @{
                            CategoryTypeName              = 'Product'
                            IsSubscribed                  = $true
                            LocalizedCategoryInstanceName = 'Windows Server 2019'
                            SourceSite                    = 'Lab'
                        }
                         @{
                            CategoryTypeName              = 'UpdateClassification'
                            IsSubscribed                  = $true
                            LocalizedCategoryInstanceName = 'Updates'
                            SourceSite                    = 'Lab'
                        }
                    )

                    $getInput = @{
                        SiteCode = 'Lab'
                    }

                    $alert = @{
                        Name = 'Synchronization failure alert for software update point:'
                    }
                }

                It 'Should return desired result with a sync schedule' {
                    Mock -CommandName Get-CMSite -MockWith { $getSiteTop }
                    Mock -CommandName Get-CMSoftwareUpdatePointComponent -MockWith { $getSupConfigProps }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getWsusSyncProps }
                    Mock -CommandName Get-CMSchedule -MockWith { $getSchedule }
                    Mock -CommandName Get-CMAlert -MockWith { $alert }
                    Mock -CommandName Get-CMSoftwareUpdateCategory -MockWith { $getUpdateCats }

                    $result = Get-TargetResource @getInput
                    $result                                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                | Should -Be -ExpectedValue 'Lab'
                    $result.ContentFileOption                       | Should -Be -ExpectedValue 'ExpressForWindows10Only'
                    $result.DefaultWsusServer                       | Should -Be -ExpectedValue 'CA01.Contoso.com'
                    $result.EnableCallWsusCleanupWizard             | Should -Be -ExpectedValue $true
                    $result.EnableSyncFailureAlert                  | Should -Be -ExpectedValue $true
                    $result.EnableSynchronization                   | Should -Be -ExpectedValue $true
                    $result.ImmediatelyExpireSupersedence           | Should -Be -ExpectedValue $false
                    $result.ImmediatelyExpireSupersedenceForFeature | Should -Be -ExpectedValue $false
                    $result.LanguageUpdateFiles                     | Should -Be -ExpectedValue @('English')
                    $result.LanguageSummaryDetails                  | Should -Be -ExpectedValue @('English')
                    $result.ReportingEvent                          | Should -Be -ExpectedValue 'CreateOnlyWsusStatusReportingEvents'
                    $result.ScheduleType                            | Should -Be -ExpectedValue 'Days'
                    $result.RecurInterval                           | Should -Be -ExpectedValue 7
                    $result.Products                                | Should -Be -ExpectedValue @('Windows Server 2019')
                    $result.UpdateClassifications                   | Should -Be -ExpectedValue @('Updates')
                    $result.SynchronizeAction                       | Should -Be -ExpectedValue 'SynchronizeFromAnUpstreamDataSourceLocation'
                    $result.UpstreamSourceLocation                  | Should -Be -ExpectedValue 'http://parentWsus.Contoso.com'
                    $result.WaitMonth                               | Should -Be -ExpectedValue 1
                    $result.WaitMonthForFeature                     | Should -Be -ExpectedValue 1
                    $result.EnableThirdPartyUpdates                 | Should -Be -ExpectedValue $false
                    $result.EnableManualCertManagement              | Should -Be -ExpectedValue $null
                    $result.FeatureUpdateMaxRuntimeMins             | Should -Be -ExpectedValue 60
                    $result.NonFeatureUpdateMaxRuntimeMins          | Should -Be -ExpectedValue 60
                    $result.ChildSite                               | Should -Be -ExpectedValue $false
                    $result.AvailableCats                           | Should -Be -ExpectedValue @('Windows Server 2019','Updates')
                }

                It 'Should return desired result no sync schedule' {
                    Mock -CommandName Get-CMSite -MockWith { $getSiteTop }
                    Mock -CommandName Get-CMSoftwareUpdatePointComponent -MockWith { $getSupConfigProps }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getWsusSyncPropsNoSchedule }
                    Mock -CommandName Get-CMSchedule -MockWith { $getSchedule }
                    Mock -CommandName Get-CMAlert -MockWith { $null }
                    Mock -CommandName Get-CMSoftwareUpdateCategory -MockWith { $getUpdateCats }

                    $result = Get-TargetResource @getInput
                    $result                                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                | Should -Be -ExpectedValue 'Lab'
                    $result.ContentFileOption                       | Should -Be -ExpectedValue 'FullFilesOnly'
                    $result.DefaultWsusServer                       | Should -Be -ExpectedValue 'CA01.Contoso.com'
                    $result.EnableCallWsusCleanupWizard             | Should -Be -ExpectedValue $true
                    $result.EnableSyncFailureAlert                  | Should -Be -ExpectedValue $false
                    $result.EnableSynchronization                   | Should -Be -ExpectedValue $false
                    $result.ImmediatelyExpireSupersedence           | Should -Be -ExpectedValue $false
                    $result.ImmediatelyExpireSupersedenceForFeature | Should -Be -ExpectedValue $false
                    $result.LanguageUpdateFiles                     | Should -Be -ExpectedValue @('English')
                    $result.LanguageSummaryDetails                  | Should -Be -ExpectedValue @('English')
                    $result.ReportingEvent                          | Should -Be -ExpectedValue 'CreateOnlyWsusStatusReportingEvents'
                    $result.Products                                | Should -Be -ExpectedValue @('Windows Server 2019')
                    $result.UpdateClassifications                   | Should -Be -ExpectedValue @('Updates')
                    $result.SynchronizeAction                       | Should -Be -ExpectedValue 'SynchronizeFromAnUpstreamDataSourceLocation'
                    $result.UpstreamSourceLocation                  | Should -Be -ExpectedValue 'http://parentWsus.Contoso.com'
                    $result.WaitMonth                               | Should -Be -ExpectedValue 1
                    $result.WaitMonthForFeature                     | Should -Be -ExpectedValue 1
                    $result.EnableThirdPartyUpdates                 | Should -Be -ExpectedValue $true
                    $result.EnableManualCertManagement              | Should -Be -ExpectedValue $true
                    $result.FeatureUpdateMaxRuntimeMins             | Should -Be -ExpectedValue 60
                    $result.NonFeatureUpdateMaxRuntimeMins          | Should -Be -ExpectedValue 60
                    $result.ChildSite                               | Should -Be -ExpectedValue $false
                    $result.AvailableCats                           | Should -Be -ExpectedValue @('Windows Server 2019','Updates')
                }

                It 'Should return desired result manual cert management' {
                    Mock -CommandName Get-CMSite -MockWith { $getSiteTop }
                    Mock -CommandName Get-CMSoftwareUpdatePointComponent -MockWith { $getSupConfigProps }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getWsusSyncPropsNoManualCert }
                    Mock -CommandName Get-CMSchedule -MockWith { $getSchedule }
                    Mock -CommandName Get-CMAlert -MockWith { $null }
                    Mock -CommandName Get-CMSoftwareUpdateCategory -MockWith { $getUpdateCats }

                    $result = Get-TargetResource @getInput
                    $result                                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                | Should -Be -ExpectedValue 'Lab'
                    $result.ContentFileOption                       | Should -Be -ExpectedValue 'FullFilesOnly'
                    $result.DefaultWsusServer                       | Should -Be -ExpectedValue 'CA01.Contoso.com'
                    $result.EnableCallWsusCleanupWizard             | Should -Be -ExpectedValue $true
                    $result.EnableSyncFailureAlert                  | Should -Be -ExpectedValue $false
                    $result.EnableSynchronization                   | Should -Be -ExpectedValue $false
                    $result.ImmediatelyExpireSupersedence           | Should -Be -ExpectedValue $false
                    $result.ImmediatelyExpireSupersedenceForFeature | Should -Be -ExpectedValue $false
                    $result.LanguageUpdateFiles                     | Should -Be -ExpectedValue @('English')
                    $result.LanguageSummaryDetails                  | Should -Be -ExpectedValue @('English')
                    $result.ReportingEvent                          | Should -Be -ExpectedValue 'CreateOnlyWsusStatusReportingEvents'
                    $result.Products                                | Should -Be -ExpectedValue @('Windows Server 2019')
                    $result.UpdateClassifications                   | Should -Be -ExpectedValue @('Updates')
                    $result.SynchronizeAction                       | Should -Be -ExpectedValue 'SynchronizeFromAnUpstreamDataSourceLocation'
                    $result.UpstreamSourceLocation                  | Should -Be -ExpectedValue 'http://parentWsus.Contoso.com'
                    $result.WaitMonth                               | Should -Be -ExpectedValue 1
                    $result.WaitMonthForFeature                     | Should -Be -ExpectedValue 1
                    $result.EnableThirdPartyUpdates                 | Should -Be -ExpectedValue $true
                    $result.EnableManualCertManagement              | Should -Be -ExpectedValue $false
                    $result.FeatureUpdateMaxRuntimeMins             | Should -Be -ExpectedValue 60
                    $result.NonFeatureUpdateMaxRuntimeMins          | Should -Be -ExpectedValue 60
                    $result.ChildSite                               | Should -Be -ExpectedValue $false
                    $result.AvailableCats                           | Should -Be -ExpectedValue @('Windows Server 2019','Updates')
                }

                It 'Should return desired result child site' {
                    Mock -CommandName Get-CMSite -MockWith { $getSiteChild }
                    Mock -CommandName Get-CMSoftwareUpdatePointComponent -MockWith { $getSupConfigProps }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getWsusSyncPropsNoManualCert }
                    Mock -CommandName Get-CMSchedule -MockWith { $getSchedule }
                    Mock -CommandName Get-CMAlert -MockWith { $null }
                    Mock -CommandName Get-CMSoftwareUpdateCategory -MockWith { $getUpdateCats }

                    $result = Get-TargetResource @getInput
                    $result                                         | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                | Should -Be -ExpectedValue 'Lab'
                    $result.ContentFileOption                       | Should -Be -ExpectedValue 'FullFilesOnly'
                    $result.DefaultWsusServer                       | Should -Be -ExpectedValue 'CA01.Contoso.com'
                    $result.EnableCallWsusCleanupWizard             | Should -Be -ExpectedValue $true
                    $result.EnableSyncFailureAlert                  | Should -Be -ExpectedValue $false
                    $result.EnableSynchronization                   | Should -Be -ExpectedValue $false
                    $result.ImmediatelyExpireSupersedence           | Should -Be -ExpectedValue $false
                    $result.ImmediatelyExpireSupersedenceForFeature | Should -Be -ExpectedValue $false
                    $result.LanguageUpdateFiles                     | Should -Be -ExpectedValue @('English')
                    $result.LanguageSummaryDetails                  | Should -Be -ExpectedValue @('English')
                    $result.ReportingEvent                          | Should -Be -ExpectedValue 'CreateOnlyWsusStatusReportingEvents'
                    $result.Products                                | Should -Be -ExpectedValue @('Windows Server 2019')
                    $result.UpdateClassifications                   | Should -Be -ExpectedValue @('Updates')
                    $result.SynchronizeAction                       | Should -Be -ExpectedValue 'SynchronizeFromAnUpstreamDataSourceLocation'
                    $result.UpstreamSourceLocation                  | Should -Be -ExpectedValue 'http://parentWsus.Contoso.com'
                    $result.WaitMonth                               | Should -Be -ExpectedValue 1
                    $result.WaitMonthForFeature                     | Should -Be -ExpectedValue 1
                    $result.EnableThirdPartyUpdates                 | Should -Be -ExpectedValue $true
                    $result.EnableManualCertManagement              | Should -Be -ExpectedValue $false
                    $result.FeatureUpdateMaxRuntimeMins             | Should -Be -ExpectedValue 60
                    $result.NonFeatureUpdateMaxRuntimeMins          | Should -Be -ExpectedValue 60
                    $result.ChildSite                               | Should -Be -ExpectedValue $true
                    $result.AvailableCats                           | Should -Be -ExpectedValue @('Windows Server 2019','Updates')
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMSoftwareUpdatePointComponent\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getReturnChild = @{
                    SiteCode            = 'Lab'
                    LanguageUpdateFiles = @('English','French')
                    ReportingEvent      = 'CreateAllWsusReportingEvents'
                    ChildSite           = $true
                }

                $getReturnSchedule = @{
                    SiteCode                                = 'Lab'
                    ContentFileOption                       = 'ExpressForWindows10Only'
                    DefaultWsusServer                       = 'CA01.Contoso.com'
                    EnableCallWsusCleanupWizard             = $true
                    EnableSyncFailureAlert                  = $true
                    EnableSynchronization                   = $true
                    ImmediatelyExpireSupersedence           = $false
                    ImmediatelyExpireSupersedenceForFeature = $false
                    LanguageUpdateFiles                     = @('English','French')
                    LanguageSummaryDetails                  = @('English','French')
                    ReportingEvent                          = 'CreateAllWsusReportingEvents'
                    ScheduleType                            = 'Days'
                    RecurInterval                           = 6
                    Products                                = @('Windows Server 2019')
                    UpdateClassifications                   = @('Updates')
                    SynchronizeAction                       = 'SynchronizeFromAnUpstreamDataSourceLocation'
                    UpstreamSourceLocation                  = 'http://parentWsus.Contoso.com'
                    WaitMonth                               = 1
                    WaitMonthForFeature                     = 1
                    EnableThirdPartyUpdates                 = $false
                    EnableManualCertManagement              = $null
                    FeatureUpdateMaxRuntimeMins             = 60
                    NonFeatureUpdateMaxRuntimeMins          = 60
                    ChildSite                               = $false
                    AvailableCats                           = @('Windows Server 2019','Updates','Upgrades','Windows Server 2012')
                }

                $getReturnNoSchedule = @{
                    SiteCode                                = 'Lab'
                    ContentFileOption                       = 'ExpressForWindows10Only'
                    DefaultWsusServer                       = 'CA01.Contoso.com'
                    EnableCallWsusCleanupWizard             = $true
                    EnableSyncFailureAlert                  = $true
                    EnableSynchronization                   = $false
                    ImmediatelyExpireSupersedence           = $false
                    ImmediatelyExpireSupersedenceForFeature = $false
                    LanguageUpdateFiles                     = @('English','French')
                    LanguageSummaryDetails                  = @('English','French')
                    ReportingEvent                          = 'CreateAllWsusReportingEvents'
                    Products                                = @('Windows Server 2019')
                    UpdateClassifications                   = @('Updates')
                    SynchronizeAction                       = 'SynchronizeFromAnUpstreamDataSourceLocation'
                    UpstreamSourceLocation                  = 'http://parentWsus.Contoso.com'
                    WaitMonth                               = 1
                    WaitMonthForFeature                     = 1
                    EnableThirdPartyUpdates                 = $false
                    EnableManualCertManagement              = $null
                    FeatureUpdateMaxRuntimeMins             = 60
                    NonFeatureUpdateMaxRuntimeMins          = 60
                    ChildSite                               = $false
                    AvailableCats                           = @('Windows Server 2019','Updates','Upgrades','Windows Server 2012')
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $inputSchedule = @{
                        SiteCode                                = 'Lab'
                        ContentFileOption                       = 'FullFilesOnly'
                        DefaultWsusServer                       = 'CA01.Contoso.com'
                        EnableCallWsusCleanupWizard             = $true
                        EnableSyncFailureAlert                  = $true
                        EnableSynchronization                   = $true
                        ImmediatelyExpireSupersedence           = $false
                        ImmediatelyExpireSupersedenceForFeature = $false
                        LanguageUpdateFiles                     = @('English','German')
                        LanguageSummaryDetails                  = @('English','German')
                        ReportingEvent                          = 'DoNotCreateWsusReportingEvents'
                        ScheduleType                            = 'Days'
                        RecurInterval                           = 7
                        Products                                = @('Windows Server 2012')
                        UpdateClassifications                   = @('Upgrades')
                        SynchronizeAction                       = 'SynchronizeFromMicrosoftUpdate'
                        WaitMonth                               = 1
                        WaitMonthForFeature                     = 1
                        EnableThirdPartyUpdates                 = $true
                        FeatureUpdateMaxRuntimeMins             = 120
                        NonFeatureUpdateMaxRuntimeMins          = 120
                    }

                    $inputNoSchedule = @{
                        SiteCode              = 'Lab'
                        EnableSynchronization = $false
                    }

                    $inputChildBadParams = @{
                        SiteCode               = 'Lab'
                        LanguageUpdateFiles    = @('English','German')
                        ReportingEvent         = 'DoNotCreateWsusReportingEvents'
                        EnableSyncFailureAlert = $true
                    }

                    Mock -CommandName Set-CMSoftwareUpdatePointComponent
                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Test-CMSchedule -MockWith {$false}
                }

                It 'Should return desired result when modifying parameters' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }

                    Set-TargetResource @inputSchedule
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 1 -Scope It
                }

                It 'Should return desired result when a child site has invalid paremeters' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnChild }

                    Set-TargetResource @inputChildBadParams
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 1 -Scope It
                }

                It 'Should return desired result when setting no schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }

                    Set-TargetResource @inputNoSchedule
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach {
                    $inputBadLangs = @{
                        SiteCode            = 'Lab'
                        LanguageUpdateFiles = @('English','BadLang')
                    }

                    $inputBadCats = @{
                        SiteCode = 'Lab'
                        Products = @('BadCat')
                    }

                    $inputWaitMonthNull = @{
                        SiteCode                      = 'Lab'
                        ImmediatelyExpireSupersedence = $false
                    }

                    $inputWaitMonthNeeded = @{
                        SiteCode                      = 'Lab'
                        ImmediatelyExpireSupersedence = $true
                        WaitMonth                     = 1
                    }

                    $inputWaitFeatureNull = @{
                        SiteCode                                = 'Lab'
                        ImmediatelyExpireSupersedenceForFeature = $false
                    }

                    $inputWaitFeatureNeeded = @{
                        SiteCode                                = 'Lab'
                        ImmediatelyExpireSupersedenceForFeature = $true
                        WaitMonthForFeature                     = 1
                    }

                    $inputNullUpstream = @{
                        SiteCode          = 'Lab'
                        SynchronizeAction = 'SynchronizeFromAnUpstreamDataSourceLocation'
                    }

                    $inputCertThrow = @{
                        SiteCode                   = 'Lab'
                        EnableThirdPartyUpdates    = $false
                        EnableManualCertManagement = $true
                    }

                    $inputScheduleNoSync = @{
                        SiteCode              = 'Lab'
                        EnableSynchronization = $false
                        ScheduleType          = 'Days'
                        RecurInterval         = 6
                    }

                    $inputSyncNoSchedule = @{
                        SiteCode              = 'Lab'
                        EnableSynchronization = $true
                    }

                    $classInEx = @{
                        SiteCode                        = 'Lab'
                        UpdateClassificationsToInclude  = @('Updates','Upgrades')
                        UpdateClassificationsToExclude  = @('Upgrades')
                    }

                    $childInEx = @{
                        SiteCode                     = 'Lab'
                        LanguageUpdateFilesToInclude = @('English','German')
                        LanguageUpdateFilesToExclude = @('German')
                    }

                    $sumInEx = @{
                        SiteCode                        = 'Lab'
                        LanguageSummaryDetailsToInclude = @('English','German')
                        LanguageSummaryDetailsToExclude = @('German')
                    }

                    $prodInEx = @{
                        SiteCode          = 'Lab'
                        ProductsToInclude = @('Windows Server 2019','Windows Server 2012')
                        ProductsToExclude = @('Windows Server 2012')
                    }

                    $badlang = 'BadLang is not a valid language available in ConfigMgr, please validate your input.'
                    $badcat = 'BadCat is not a valid product or category available in ConfigMgr, please validate your input.'
                    $langSumInEx = 'LanguageSummaryDetailsToExclude and LanguageSummaryDetailsToInclude contain to same entry German, remove from one of the arrays.'
                    $langFilesInEx = 'LanguageUpdateFilesToExclude and LanguageUpdateFilesToInclude contain to same entry German, remove from one of the arrays.'
                    $productsInEx = 'ProductsToExclude and ProductsToInclude contain to same entry Windows Server 2012, remove from one of the arrays.'
                    $updateClassInEx = 'UpdateClassificationsToExclude and UpdateClassificationsToInclude contain to same entry Upgrades, remove from one of the arrays.'
                    $waitMonthNull = 'If you specify a value of $false for the ImmediatelyExpireSupersedence parameter, you muse use the WaitMonth parameter.'
                    $waitMonthNeeded = 'If you specify a value of $true for the ImmediatelyExpireSupersedence parameter, do not use the WaitMonth parameter.'
                    $waitFeatureNull = 'If you specify a value of $false for the ImmediatelyExpireSupersedenceForFeature parameter, you muse use the WaitMonthForFeature parameter.'
                    $waitFeatureNeeded = 'If you specify a value of $true for the ImmediatelyExpireSupersedenceForFeature parameter, do not use the WaitMonthForFeature parameter.'
                    $upstreamSourceNull = 'If you specify to synchronize from an upstream data source, you must use the UpstreamSourceLocation parameter.'
                    $certMgmtSpecified = 'If you specify not to enable third party updates, do not use the EnableManualCertManagement parameter.'
                    $scheduleNoSync = 'When specifying a schedule, the EnableSynchronization paramater must be true.'
                    $syncNoSchedule = 'When specifying the EnableSynchronization paramater as true, you must specify a schedule.'

                    Mock -CommandName New-CMSchedule
                    Mock -CommandName Test-CMSchedule
                }

                It 'Should return throw when a bad language input is detected' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputBadLangs } | Should -Throw -ExpectedMessage $badlang
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when a bad category input is detected' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputBadCats } | Should -Throw -ExpectedMessage $badcat
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when a child language include and exclude match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnChild }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @childInEx } | Should -Throw -ExpectedMessage $langFilesInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should throw when the WaitMonth parameter is expected and not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputWaitMonthNull } | Should -Throw -ExpectedMessage $waitMonthNull
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should throw when WaitMonth parameter is specified and not expected' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputWaitMonthNeeded } | Should -Throw -ExpectedMessage $waitMonthNeeded
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should throw when the WaitMonthForFeature parameter is expected and not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputWaitFeatureNull } | Should -Throw -ExpectedMessage $waitFeatureNull
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should throw when WaitMonthForFeature parameter is specified and not expected' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputWaitFeatureNeeded } | Should -Throw -ExpectedMessage $waitFeatureNeeded
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should throw when an upstream WSUS source is expected and not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputNullUpstream } | Should -Throw -ExpectedMessage $upstreamSourceNull
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should throw when third party updates are disabled and EnableManualCertManagement is specified ' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputCertThrow } | Should -Throw -ExpectedMessage $certMgmtSpecified
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should throw when a schedule is specified and EnableSynchronization is set to false' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputScheduleNoSync } | Should -Throw -ExpectedMessage $scheduleNoSync
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should throw when enabling synchronization without a specified schedule' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @inputSyncNoSchedule } | Should -Throw -ExpectedMessage $syncNoSchedule
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when a language file include and exclude match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @childInEx } | Should -Throw -ExpectedMessage $langFilesInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when a language summary include and exclude match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @sumInEx } | Should -Throw -ExpectedMessage $langSumInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when a product include and exclude match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @prodInEx } | Should -Throw -ExpectedMessage $productsInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }

                It 'Should return throw when a classification include and exclude match' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                    Mock -CommandName Set-CMSoftwareUpdatePointComponent

                    { Set-TargetResource @classInEx } | Should -Throw -ExpectedMessage $updateClassInEx
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Test-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSchedule -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMSoftwareUpdatePointComponent -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMSoftwareUpdatePointComponent\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getReturnChild = @{
                    SiteCode            = 'Lab'
                    LanguageUpdateFiles = @('English','French')
                    ReportingEvent      = 'CreateAllWsusReportingEvents'
                    ChildSite           = $true
                }

                $getReturnSchedule = @{
                    SiteCode                                = 'Lab'
                    ContentFileOption                       = 'ExpressForWindows10Only'
                    DefaultWsusServer                       = 'CA01.Contoso.com'
                    EnableCallWsusCleanupWizard             = $true
                    EnableSyncFailureAlert                  = $true
                    EnableSynchronization                   = $true
                    ImmediatelyExpireSupersedence           = $false
                    ImmediatelyExpireSupersedenceForFeature = $false
                    LanguageUpdateFiles                     = @('English','French')
                    LanguageSummaryDetails                  = @('English','French')
                    ReportingEvent                          = 'CreateAllWsusReportingEvents'
                    ScheduleType                            = 'Days'
                    RecurInterval                           = 6
                    Products                                = @('Windows Server 2019')
                    UpdateClassifications                   = @('Updates')
                    SynchronizeAction                       = 'SynchronizeFromAnUpstreamDataSourceLocation'
                    UpstreamSourceLocation                  = 'http://parentWsus.Contoso.com'
                    WaitMonth                               = 1
                    WaitMonthForFeature                     = 1
                    EnableThirdPartyUpdates                 = $false
                    EnableManualCertManagement              = $null
                    FeatureUpdateMaxRuntimeMins             = 60
                    NonFeatureUpdateMaxRuntimeMins          = 60
                    ChildSite                               = $false
                    AvailableCats                           = @('Windows Server 2019','Updates','Upgrades','Windows Server 2012')
                }

                $inputSchedule = @{
                    SiteCode                                = 'Lab'
                    ContentFileOption                       = 'FullFilesOnly'
                    DefaultWsusServer                       = 'CA01.Contoso.com'
                    EnableCallWsusCleanupWizard             = $true
                    EnableSyncFailureAlert                  = $true
                    EnableSynchronization                   = $true
                    ImmediatelyExpireSupersedence           = $false
                    ImmediatelyExpireSupersedenceForFeature = $false
                    LanguageUpdateFiles                     = @('English','German')
                    LanguageSummaryDetails                  = @('English','German')
                    ReportingEvent                          = 'DoNotCreateWsusReportingEvents'
                    ScheduleType                            = 'Days'
                    RecurInterval                           = 6
                    Products                                = @('Windows Server 2012')
                    SynchronizeAction                       = 'SynchronizeFromMicrosoftUpdate'
                    WaitMonth                               = 1
                    WaitMonthForFeature                     = 1
                    EnableThirdPartyUpdates                 = $true
                    FeatureUpdateMaxRuntimeMins             = 120
                    NonFeatureUpdateMaxRuntimeMins          = 120
                }

                $getReturnNoSchedule = @{
                    SiteCode                                = 'Lab'
                    ContentFileOption                       = 'ExpressForWindows10Only'
                    DefaultWsusServer                       = 'CA01.Contoso.com'
                    EnableCallWsusCleanupWizard             = $true
                    EnableSyncFailureAlert                  = $true
                    EnableSynchronization                   = $false
                    ImmediatelyExpireSupersedence           = $false
                    ImmediatelyExpireSupersedenceForFeature = $false
                    LanguageUpdateFiles                     = @('English','French')
                    LanguageSummaryDetails                  = @('English','French')
                    ReportingEvent                          = 'CreateAllWsusReportingEvents'
                    Products                                = @('Windows Server 2019')
                    UpdateClassifications                   = @('Updates')
                    SynchronizeAction                       = 'SynchronizeFromAnUpstreamDataSourceLocation'
                    UpstreamSourceLocation                  = 'http://parentWsus.Contoso.com'
                    WaitMonth                               = 1
                    WaitMonthForFeature                     = 1
                    EnableThirdPartyUpdates                 = $false
                    EnableManualCertManagement              = $null
                    FeatureUpdateMaxRuntimeMins             = 60
                    NonFeatureUpdateMaxRuntimeMins          = 60
                    ChildSite                               = $false
                    AvailableCats                           = @('Windows Server 2019','Updates','Upgrades','Windows Server 2012')
                }

                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource when get returns top level site with schedule' {
                BeforeEach {
                    $inputMatch = @{
                        SiteCode                                = 'Lab'
                        ContentFileOption                       = 'ExpressForWindows10Only'
                        DefaultWsusServer                       = 'CA01.Contoso.com'
                        EnableCallWsusCleanupWizard             = $true
                        EnableSyncFailureAlert                  = $true
                        EnableSynchronization                   = $true
                        ImmediatelyExpireSupersedence           = $false
                        ImmediatelyExpireSupersedenceForFeature = $false
                        LanguageUpdateFiles                     = @('English','French')
                        LanguageSummaryDetails                  = @('English','French')
                        ReportingEvent                          = 'CreateAllWsusReportingEvents'
                        ScheduleType                            = 'Days'
                        RecurInterval                           = 6
                        Products                                = @('Windows Server 2019')
                        UpdateClassifications                   = @('Updates')
                        SynchronizeAction                       = 'SynchronizeFromAnUpstreamDataSourceLocation'
                        UpstreamSourceLocation                  = 'http://parentWsus.Contoso.com'
                        WaitMonth                               = 1
                        WaitMonthForFeature                     = 1
                        EnableThirdPartyUpdates                 = $false
                        FeatureUpdateMaxRuntimeMins             = 60
                        NonFeatureUpdateMaxRuntimeMins          = 60
                    }

                    $inputBadLangs = @{
                        SiteCode            = 'Lab'
                        LanguageUpdateFiles = @('English','BadLang')
                    }

                    $inputBadCats = @{
                        SiteCode = 'Lab'
                        Products = @('BadCat')
                    }

                    $inputWarnSet1 = @{
                        SiteCode                                = 'Lab'
                        ImmediatelyExpireSupersedence           = $false
                        ImmediatelyExpireSupersedenceForFeature = $false
                        SynchronizeAction                       = 'SynchronizeFromAnUpstreamDataSourceLocation'
                        EnableThirdPartyUpdates                 = $false
                        EnableManualCertManagement              = $true
                        EnableSynchronization                   = $false
                        ScheduleType                            = 'Days'
                        RecurInterval                           = 6
                    }

                    $inputWarnSet2 = @{
                        SiteCode                                = 'Lab'
                        ImmediatelyExpireSupersedence           = $true
                        WaitMonth                               = 1
                        ImmediatelyExpireSupersedenceForFeature = $true
                        WaitMonthForFeature                     = 1
                        EnableSynchronization                   = $true
                    }

                    $inputInEx = @{
                        SiteCode                        = 'Lab'
                        LanguageSummaryDetailsToInclude = @('English','German')
                        LanguageSummaryDetailsToExclude = @('German')
                        LanguageUpdateFilesToInclude    = @('English','German')
                        LanguageUpdateFilesToExclude    = @('German')
                        ProductsToInclude               = @('Windows Server 2019','Windows Server 2012')
                        ProductsToExclude               = @('Windows Server 2012')
                        UpdateClassificationsToInclude  = @('Updates','Upgrades')
                        UpdateClassificationsToExclude  = @('Upgrades')
                    }

                    $inputIgnore = @{
                        SiteCode                        = 'Lab'
                        LanguageSummaryDetails          = @('German')
                        LanguageSummaryDetailsToInclude = @('English')
                        LanguageSummaryDetailsToExclude = @('German')
                        LanguageUpdateFiles             = @('German')
                        LanguageUpdateFilesToInclude    = @('English')
                        LanguageUpdateFilesToExclude    = @('German')
                        Products                        = @('Windows Server 2012')
                        ProductsToInclude               = @('Windows Server 2019')
                        ProductsToExclude               = @('Windows Server 2012')
                        UpdateClassifications           = @('Upgrades')
                        UpdateClassificationsToInclude  = @('Updates')
                        UpdateClassificationsToExclude  = @('Upgrades')
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnSchedule }
                }

                It 'Should return desired result true settings match' {
                    Test-TargetResource @inputMatch | Should -Be $true
                }

                It 'Should return desired result false settings mismatch' {
                    Test-TargetResource @inputSchedule | Should -Be $false
                }

                It 'Should return desired result false when bad languages are input' {
                    Test-TargetResource @inputBadLangs | Should -Be $false
                }

                It 'Should return desired result false when bad categories are input' {
                    Test-TargetResource @inputBadCats | Should -Be $false
                }

                It 'Should return desired result false when parameters hit warn set 1' {
                    Test-TargetResource @inputWarnSet1 | Should -Be $false
                }

                It 'Should return desired result false when parameters hit warn set 2' {
                    Test-TargetResource @inputWarnSet2 | Should -Be $false
                }

                It 'Should return desired result false when an include is in the exclude' {
                    Test-TargetResource @inputInEx | Should -Be $false
                }

                It 'Should return desired result false, include/exclude ignored' {
                    Test-TargetResource @inputIgnore | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource when get returns top level site with no schedule' {
                BeforeEach {
                    $inputNoSchedule = @{
                        SiteCode              = 'Lab'
                        EnableSynchronization = $false
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnNoSchedule }
                }

                It 'Should return desired result false when synchronization needs enabled' {
                    Test-TargetResource @inputSchedule | Should -Be $false
                }

                It 'Should return desired result true no schedule' {
                    Test-TargetResource @inputNoSchedule | Should -Be $true
                }
            }

            Context 'When running Test-TargetResource when get returns child site' {
                BeforeEach {
                    $inputChild = @{
                        SiteCode            = 'Lab'
                        LanguageUpdateFiles = @('English','German')
                        ReportingEvent      = 'DoNotCreateWsusReportingEvents'
                    }

                    $inputChildBadParams = @{
                        SiteCode               = 'Lab'
                        LanguageUpdateFiles    = @('English','German')
                        ReportingEvent         = 'DoNotCreateWsusReportingEvents'
                        EnableSyncFailureAlert = $true
                    }

                    $childMatch = @{
                        SiteCode            = 'Lab'
                        LanguageUpdateFiles = @('English','French')
                        ReportingEvent      = 'CreateAllWsusReportingEvents'
                    }

                    $childInEx = @{
                        SiteCode                     = 'Lab'
                        LanguageUpdateFilesToInclude = @('English','German')
                        LanguageUpdateFilesToExclude = @('German')
                    }

                    $childIgnore = @{
                        SiteCode                     = 'Lab'
                        LanguageUpdateFiles          = @('English','German')
                        LanguageUpdateFilesToInclude = @('English')
                        LanguageUpdateFilesToExclude = @('German')
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getReturnChild }
                }

                It 'Should return desired result true when child site input matches' {
                    Test-TargetResource @childMatch | Should -Be $true
                }

                It 'Should return desired result false when inputting bad child parameters' {
                    Test-TargetResource @inputChildBadParams | Should -Be $false
                }

                It 'Should return desired result false when child input is mismatched' {
                    Test-TargetResource @inputChild | Should -Be $false
                }

                It 'Should return desired result false when an include is in the exclude' {
                    Test-TargetResource @childInEx | Should -Be $false
                }

                It 'Should return desired result false, include/exclude ignored' {
                    Test-TargetResource @childIgnore | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
