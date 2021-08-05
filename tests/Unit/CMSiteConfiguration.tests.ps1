param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMSiteConfiguration'

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

#Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        Describe 'ConfigMgrCBDsc - DSC_CMSiteConfiguration\Get-TargetResource' -Tag 'Get'{
            BeforeAll{
                $getInput = @{
                    SiteCode = 'Lab'
                }

                $getLanSenderReturn = @{
                    Props = @(
                        @{
                            PropertyName = 'Concurrent Sending Limit'
                            Value        = 0
                            Value1       = 6
                            Value2       = 3
                        }
                        @{
                            PropertyName = 'Number of Retries'
                            Value        = 3
                        }
                        @{
                            PropertyName = 'Retry Delay'
                            Value        = 2
                        }
                    )
                }

                $getSiteDefBlockReturn = @{
                    Props = @(
                        @{
                            PropertyName = 'Comments'
                            Value1       = 'Site Lab'
                        }
                        @{
                            PropertyName = 'Device Collection Threshold'
                            Value         = 0
                            Value1        = 100
                            Value2        = 200
                        }
                        @{
                            PropertyName = 'Retry Delay'
                            Value        = 2
                        }
                    )
                }

                $getSiteDefWarnReturn = @{
                    Props = @(
                        @{
                            PropertyName = 'Comments'
                            Value1       = 'Site Lab'
                        }
                        @{
                            PropertyName = 'Device Collection Threshold'
                            Value         = 1
                            Value1        = 100
                            Value2        = 200
                        }
                        @{
                            PropertyName = 'Retry Delay'
                            Value        = 2
                        }
                    )
                }

                $getSiteCompManager31Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 31
                        }
                        @{
                            PropertyName = 'Enforce Enhanced Hash Algorithm'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enforce Message Signing'
                            Value        = 1
                        }
                    )
                }

                $getSiteCompManager63Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 63
                        }
                        @{
                            PropertyName = 'Enforce Enhanced Hash Algorithm'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enforce Message Signing'
                            Value        = 1
                        }
                    )
                }

                $getSiteCompManager192Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 192
                        }
                        @{
                            PropertyName = 'Enforce Enhanced Hash Algorithm'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enforce Message Signing'
                            Value        = 1
                        }
                    )
                }

                $getSiteCompManager224Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 224
                        }
                        @{
                            PropertyName = 'Enforce Enhanced Hash Algorithm'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enforce Message Signing'
                            Value        = 1
                        }
                    )
                }

                $getSiteCompManager448Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 448
                        }
                        @{
                            PropertyName = 'Enforce Enhanced Hash Algorithm'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enforce Message Signing'
                            Value        = 1
                        }
                    )
                }

                $getSiteCompManager480Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 480
                        }
                        @{
                            PropertyName = 'Enforce Enhanced Hash Algorithm'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enforce Message Signing'
                            Value        = 1
                        }
                    )
                }

                $getSiteCompManager1216Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 1216
                        }
                        @{
                            PropertyName = 'Enforce Enhanced Hash Algorithm'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enforce Message Signing'
                            Value        = 1
                        }
                    )
                }

                $getSiteCompManager1248Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 1248
                        }
                        @{
                            PropertyName = 'Enforce Enhanced Hash Algorithm'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enforce Message Signing'
                            Value        = 1
                        }
                    )
                }

                $getSiteCompManager1504Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 1504
                        }
                        @{
                            PropertyName = 'Enforce Enhanced Hash Algorithm'
                            Value        = 1
                        }
                        @{
                            PropertyName = 'Enforce Message Signing'
                            Value        = 1
                        }
                    )
                }

                $getCMAlertEnabled = @(
                    @{
                        Name         = '$DatabaseFreeSpaceWarningName'
                        PropertyList = @{
                            ParameterValues = @(
                                '<Parameters><Parameter index="1" isUserParameter="0" type="int"/><Parameter index="2" isUserParameter="0" type="int">33</Parameter><Parameter index="3" isUserParameter="1" type="int">10</Parameter><Parameter index="4" isUserParameter="1" type="int">5</Parameter></Parameters>'
                                '<Parameters><Parameter index="1" isUserParameter="0" type="int"/><Parameter index="2" isUserParameter="0" type="int"/><Parameter index="3" isUserParameter="1" type="int">5</Parameter><Parameter index="4" isUserParameter="1" type="int">1</Parameter></Parameters>'
                            )
                        }
                    }
                )

                $getCMAlertDisabled = @(
                    @{
                        Name = '$DatabaseFreeSpaceWarningName'
                        PropertyList = @{
                            ParameterValues = '<Parameters><Parameter index="1" isUserParameter="0" type="int"/><Parameter index="2" isUserParameter="0" type="int">33</Parameter><Parameter index="3" isUserParameter="1" type="int">10</Parameter><Parameter index="4" isUserParameter="1" type="int">5</Parameter></Parameters>'
                        }
                    }
                )

                $getPolicyProvider = @{
                    Props = @(
                        @{
                            PropertyName = 'Use Encryption'
                            Value        = 1
                        }
                    )
                }

                Mock -CommandName Get-CMSiteComponent -MockWith { $getLanSenderReturn } -ParameterFilter {$ComponentName -match 'SMS_LAN_Sender'}
                Mock -CommandName Get-CMSiteComponent -MockWith { $getPolicyProvider } -ParameterFilter {$ComponentName -match 'SMS_POLICY_PROVIDER'}
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Site Configuration settings' {
                It 'Should return desired result when site configuration settings are HTTPS Only and blocked' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertDisabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefBlockReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager31Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOnly'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $false
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $true
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $false
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $true
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $true
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $true
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $false
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue $null
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue $null
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Block'
                }

                It 'Should return desired result when site configuration settings are HTTPS Only with CRL and warn' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager63Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOnly'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $true
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $true
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $false
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $true
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $true
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $true
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $true
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue 5
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue 1
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Warn'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP only' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager192Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOrHttp'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $false
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $false
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $false
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $true
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $true
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $true
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $true
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue 5
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue 1
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Warn'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and CRL' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager224Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOrHttp'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $true
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $false
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $false
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $true
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $true
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $true
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $true
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue 5
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue 1
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Warn'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and PKI' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager448Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOrHttp'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $false
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $true
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $false
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $true
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $true
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $true
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $true
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue 5
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue 1
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Warn'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and PKI and CRL' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager480Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOrHttp'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $true
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $true
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $false
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $true
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $true
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $true
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $true
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue 5
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue 1
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Warn'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and SCCM Cert' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager1216Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOrHttp'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $false
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $false
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $true
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $true
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $true
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $true
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $true
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue 5
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue 1
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Warn'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and SCCM Cert and CRL' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager1248Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOrHttp'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $true
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $false
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $true
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $true
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $true
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $true
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $true
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue 5
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue 1
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Warn'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and SCCM Cert and PKI and CRL' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager1504Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOrHttp'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $true
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $true
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $true
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $true
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $true
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $true
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $true
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue 5
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue 1
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Warn'
                }
            }
        }

        <#Describe 'ConfigMgrCBDsc - DSC_CMSiteConfiguration\Set-TargetResource' -Tag 'Set'{
            BeforeAll{
                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Ensure         = 'Absent'
                }

                $inputMismatch = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Mode           = 'Offline'
                    Ensure         = 'Present'
                }

                $getReturnAll = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Mode           = 'Online'
                    Ensure         = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Mode           = $null
                    Ensure         = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Add-CMServiceConnectionPoint
                Mock -CommandName Set-CMServiceConnectionPoint
                Mock -CommandName Remove-CMServiceConnectionPoint
            }

            Context 'When Set-TargetResource runs successfully' {

                It 'Should call expected commands for when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when the service connection point is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @getReturnAll
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when the service connection point exists and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {

                It 'Should call expected commands and throw if Add-CMServiceConnectionPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Add-CMServiceConnectionPoint -MockWith { throw }

                    { Set-TargetResource @getReturnAll } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Set-CMServiceConnectionPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Set-CMServiceConnectionPoint -MockWith { throw }

                    { Set-TargetResource @inputMismatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Remove-CMServiceConnectionPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Remove-CMServiceConnectionPoint -MockWith { throw }

                    { Set-TargetResource @inputAbsent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                }
            }
        }#>

        Describe 'ConfigMgrCBDsc - DSC_CMSiteConfiguration\Test-TargetResource' -Tag 'Test'{
            BeforeAll{
                $getReturnAll = @{
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
                }

                $inputMatch = @{
                    SiteCode                                 = 'Lab'
                    Comment                                  = 'Site Lab'
                    ClientComputerCommunicationType          = 'HttpsOrHttp'
                    MaximumConcurrentSendingForAllSite       = 6
                    MaximumConcurrentSendingForPerSite       = 3
                    RetryNumberForConcurrentSending          = 2
                    ConcurrentSendingDelayBeforeRetryingMins = 10
                    EnableLowFreeSpaceAlert                  = $true
                    FreeSpaceThresholdWarningGB              = 10
                    FreeSpaceThresholdCriticalGB             = 5
                    ThresholdOfSelectCollectionByDefault     = 100
                    ThresholdOfSelectCollectionMax           = 1000
                    SiteSystemCollectionBehavior             = 'Warn'
                }

                $inputNotMatch = @{
                    SiteCode                = 'Lab'
                    EnableLowFreeSpaceAlert = $false
                }

                $inputSmsCertWithHttpsOnly = @{
                    SiteCode                        = 'Lab'
                    Comment                         = 'Site Lab'
                    ClientComputerCommunicationType = 'HttpsOnly'
                    UseSmsGeneratedCert             = $true
                }

                $inputDisableAlertWithValue = @{
                    SiteCode                    = 'Lab'
                    Comment                     = 'Site Lab'
                    EnableLowFreeSpaceAlert     = $false
                    FreeSpaceThresholdWarningGB = 10
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource' {
                BeforeEach{
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                }

                It 'Should return desired result true when desired results equals current state' {

                    Test-TargetResource @inputMatch | Should -Be $true
                }

                It 'Should return desired result false when desired result does not equal current state' {

                    Test-TargetResource @inputNotMatch | Should -Be $false
                }

                It 'Should return desired result false when desired result does not equal current state with invalid parameter' {

                    Test-TargetResource @inputSmsCertWithHttpsOnly | Should -Be $false
                }

                It 'Should return desired result false when desired result does not equal current state with disabling Alerts' {

                    Test-TargetResource @inputDisableAlertWithValue | Should -Be $false
                }


            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
