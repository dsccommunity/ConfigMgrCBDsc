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
        Describe 'ConfigMgrCBDsc - DSC_CMSiteConfiguration\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
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
                    SiteType = 2
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
                    SiteType = 2
                    Props    = @(
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

                $getSiteDefCas = @{
                    SiteType = 4
                    Props    = @(
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

                $getSiteCompManager0Return = @{
                    Props = @(
                        @{
                            PropertyName = 'IISSSLState'
                            Value        = 0
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
                        @{
                            PropertyName = 'Certificate Store'
                            Value1       = 'SMSStore'
                        }
                        @{
                            PropertyName = 'Select First Certificate'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Certificate Selection Criteria'
                            Value1       = ''
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
                        @{
                            PropertyName = 'Certificate Store'
                            Value1       = 'SMSStore'
                        }
                        @{
                            PropertyName = 'Select First Certificate'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Certificate Selection Criteria'
                            Value1       = 'SubjectStr:Test'
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
                        @{
                            PropertyName = 'Certificate Store'
                            Value1       = 'SMSStore'
                        }
                        @{
                            PropertyName = 'Select First Certificate'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Certificate Selection Criteria'
                            Value1       = 'SubjectAttr:Test'
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
                        @{
                            PropertyName = 'Certificate Store'
                            Value1       = 'SMSStore'
                        }
                        @{
                            PropertyName = 'Select First Certificate'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Certificate Selection Criteria'
                            Value1       = 'SubjectAttr:Test'
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
                        @{
                            PropertyName = 'Certificate Store'
                            Value1       = 'SMSStore'
                        }
                        @{
                            PropertyName = 'Select First Certificate'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Certificate Selection Criteria'
                            Value1       = 'SubjectAttr:Test'
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
                        @{
                            PropertyName = 'Certificate Store'
                            Value1       = 'SMSStore'
                        }
                        @{
                            PropertyName = 'Select First Certificate'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Certificate Selection Criteria'
                            Value1       = 'SubjectAttr:Test'
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
                        @{
                            PropertyName = 'Certificate Store'
                            Value1       = 'SMSStore'
                        }
                        @{
                            PropertyName = 'Select First Certificate'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Certificate Selection Criteria'
                            Value1       = 'SubjectAttr:Test'
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
                        @{
                            PropertyName = 'Certificate Store'
                            Value1       = 'SMSStore'
                        }
                        @{
                            PropertyName = 'Select First Certificate'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Certificate Selection Criteria'
                            Value1       = 'SubjectAttr:Test'
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
                        @{
                            PropertyName = 'Certificate Store'
                            Value1       = ''
                        }
                        @{
                            PropertyName = 'Select First Certificate'
                            Value        = 0
                        }
                        @{
                            PropertyName = 'Certificate Selection Criteria'
                            Value1       = 'SubjectAttr:Test'
                        }
                    )
                }

                $getCMAlertEnabled = @(
                    @{
                        Name         = '$DatabaseFreeSpaceWarningName'
                        PropertyList = @{
                            ParameterValues = @(
                                '<Parameters><Parameter index="1" isUserParameter="0" type="int"/><Parameter index="2" isUserParameter="0" type="int"/><Parameter index="3" isUserParameter="1" type="int">5</Parameter><Parameter index="4" isUserParameter="1" type="int">1</Parameter></Parameters>'
                            )
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

                $wolDisabled = @{
                    Flag  = 1
                }

                $wolUnicast = @{
                    Flag  = 6
                    Props = @(
                        @{
                            PropertyName = 'SendRetryMax'
                            Value        = 3
                        }
                        @{
                            PropertyName = 'SendRetryInterval'
                            Value        = 60
                        }
                        @{
                            PropertyName = 'SendThrottleMax'
                            Value        = 10000
                        }
                        @{
                            PropertyName = 'SendThrottleInterval'
                            Value        = 10
                        }
                        @{
                            PropertyName = 'MaxThreads'
                            Value        = 3
                        }
                        @{
                            PropertyName = 'SendMode'
                            Value        = 1
                        }
                    )
                }

                $wolBroadcast = @{
                    Flag  = 6
                    Props = @(
                        @{
                            PropertyName = 'SendRetryMax'
                            Value        = 3
                        }
                        @{
                            PropertyName = 'SendRetryInterval'
                            Value        = 60
                        }
                        @{
                            PropertyName = 'SendThrottleMax'
                            Value        = 10000
                        }
                        @{
                            PropertyName = 'SendThrottleInterval'
                            Value        = 10
                        }
                        @{
                            PropertyName = 'MaxThreads'
                            Value        = 3
                        }
                        @{
                            PropertyName = 'SendMode'
                            Value        = 2
                        }
                    )
                }

                $wolComponent = @{
                    Props = @(
                        @{
                            PropertyName = 'ScheduleOffset'
                            Value        = 600
                        }
                    )
                }

                Mock -CommandName Get-CMSiteComponent -MockWith { $getLanSenderReturn } -ParameterFilter {$ComponentName -match 'SMS_LAN_Sender'}
                Mock -CommandName Get-CMSiteComponent -MockWith { $getPolicyProvider } -ParameterFilter {$ComponentName -match 'SMS_POLICY_PROVIDER'}
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Site Configuration settings' {

                It 'Should return desired result when site configuration settings are HTTPS\HTTP only for CAS' {
                    Mock -CommandName Get-CMAlert
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefCas }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager0Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager'}

                    $result = Get-TargetResource @getInput
                    $result                                                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                                          | Should -Be -ExpectedValue 'Lab'
                    $result.Comment                                           | Should -Be -ExpectedValue 'Site Lab'
                    $result.ClientComputerCommunicationType                   | Should -Be -ExpectedValue 'HttpsOrHttp'
                    $result.ClientCheckCertificateRevocationListForSiteSystem | Should -Be -ExpectedValue $null
                    $result.UsePkiClientCertificate                           | Should -Be -ExpectedValue $null
                    $result.UseSmsGeneratedCert                               | Should -Be -ExpectedValue $false
                    $result.RequireSigning                                    | Should -Be -ExpectedValue $null
                    $result.RequireSha256                                     | Should -Be -ExpectedValue $null
                    $result.UseEncryption                                     | Should -Be -ExpectedValue $null
                    $result.MaximumConcurrentSendingForAllSite                | Should -Be -ExpectedValue 6
                    $result.MaximumConcurrentSendingForPerSite                | Should -Be -ExpectedValue 3
                    $result.RetryNumberForConcurrentSending                   | Should -Be -ExpectedValue 3
                    $result.ConcurrentSendingDelayBeforeRetryingMins          | Should -Be -ExpectedValue 2
                    $result.EnableLowFreeSpaceAlert                           | Should -Be -ExpectedValue $null
                    $result.FreeSpaceThresholdWarningGB                       | Should -Be -ExpectedValue $null
                    $result.FreeSpaceThresholdCriticalGB                      | Should -Be -ExpectedValue $null
                    $result.ThresholdOfSelectCollectionByDefault              | Should -Be -ExpectedValue 100
                    $result.ThresholdOfSelectCollectionMax                    | Should -Be -ExpectedValue 200
                    $result.SiteSystemCollectionBehavior                      | Should -Be -ExpectedValue 'Warn'
                    $result.SiteType                                          | Should -Be -ExpectedValue 'CAS'
                }

                It 'Should return desired result when site configuration settings are HTTPS Only and blocked Primary' {
                    Mock -CommandName Get-CMAlert -MockWith { $null }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefBlockReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager31Return } -ParameterFilter {$ComponentName -match 'SMS_Site_Component_Manager' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolDisabled } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $null } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_MANAGER' }

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
                    $result.SiteType                                          | Should -Be -ExpectedValue 'Primary'
                    $result.EnableWakeOnLan                                   | Should -Be -ExpectedValue $false
                    $result.WakeOnLanTransmissionMethodType                   | Should -Be -ExpectedValue $null
                    $result.RetryNumberOfSendingWakeupPacketTransmission      | Should -Be -ExpectedValue $null
                    $result.SendingWakeupPacketTransmissionDelayMins          | Should -Be -ExpectedValue $null
                    $result.MaximumNumberOfSendingWakeupPacketBeforePausing   | Should -Be -ExpectedValue $null
                    $result.SendingWakeupPacketBeforePausingWaitSec           | Should -Be -ExpectedValue $null
                    $result.ThreadNumberOfSendingWakeupPacket                 | Should -Be -ExpectedValue $null
                    $result.SendingWakeupPacketTransmissionOffsetMins         | Should -Be -ExpectedValue 0
                    $result.ClientCertificateCustomStoreName                  | Should -Be -ExpectedValue 'SMSStore'
                    $result.TakeActionForMultipleCertificateMatchCriteria     | Should -Be -ExpectedValue 'FailSelectionAndSendErrorMessage'
                    $result.ClientCertificateSelectionCriteriaType            | Should -Be -ExpectedValue 'ClientAuthentication'
                    $result.ClientCertificateSelectionCriteriaValue           | Should -Be -ExpectedValue ''
                }

                It 'Should return desired result when site configuration settings are HTTPS Only with CRL and warn' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager63Return } -ParameterFilter { $ComponentName -match 'SMS_Site_Component_Manager' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolBroadcast } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolComponent } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_MANAGER' }

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
                    $result.SiteType                                          | Should -Be -ExpectedValue 'Primary'
                    $result.EnableWakeOnLan                                   | Should -Be -ExpectedValue $true
                    $result.WakeOnLanTransmissionMethodType                   | Should -Be -ExpectedValue 'SubnetDirectedBroadcasts'
                    $result.RetryNumberOfSendingWakeupPacketTransmission      | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionDelayMins          | Should -Be -ExpectedValue 1
                    $result.MaximumNumberOfSendingWakeupPacketBeforePausing   | Should -Be -ExpectedValue 10000
                    $result.SendingWakeupPacketBeforePausingWaitSec           | Should -Be -ExpectedValue 10
                    $result.ThreadNumberOfSendingWakeupPacket                 | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionOffsetMins         | Should -Be -ExpectedValue 10
                    $result.ClientCertificateCustomStoreName                  | Should -Be -ExpectedValue 'SMSStore'
                    $result.TakeActionForMultipleCertificateMatchCriteria     | Should -Be -ExpectedValue 'FailSelectionAndSendErrorMessage'
                    $result.ClientCertificateSelectionCriteriaType            | Should -Be -ExpectedValue 'CertificateSubjectContainsString'
                    $result.ClientCertificateSelectionCriteriaValue           | Should -Be -ExpectedValue 'Test'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP only' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager192Return } -ParameterFilter { $ComponentName -match 'SMS_Site_Component_Manager' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolUnicast } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolComponent } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_MANAGER' }

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
                    $result.SiteType                                          | Should -Be -ExpectedValue 'Primary'
                    $result.EnableWakeOnLan                                   | Should -Be -ExpectedValue $true
                    $result.WakeOnLanTransmissionMethodType                   | Should -Be -ExpectedValue 'Unicast'
                    $result.RetryNumberOfSendingWakeupPacketTransmission      | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionDelayMins          | Should -Be -ExpectedValue 1
                    $result.MaximumNumberOfSendingWakeupPacketBeforePausing   | Should -Be -ExpectedValue 10000
                    $result.SendingWakeupPacketBeforePausingWaitSec           | Should -Be -ExpectedValue 10
                    $result.ThreadNumberOfSendingWakeupPacket                 | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionOffsetMins         | Should -Be -ExpectedValue 10
                    $result.ClientCertificateCustomStoreName                  | Should -Be -ExpectedValue 'SMSStore'
                    $result.TakeActionForMultipleCertificateMatchCriteria     | Should -Be -ExpectedValue 'FailSelectionAndSendErrorMessage'
                    $result.ClientCertificateSelectionCriteriaType            | Should -Be -ExpectedValue 'CertificateSubjectOrSanIncludesAtrributes'
                    $result.ClientCertificateSelectionCriteriaValue           | Should -Be -ExpectedValue 'Test'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and CRL' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager224Return } -ParameterFilter { $ComponentName -match 'SMS_Site_Component_Manager' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolUnicast } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolComponent } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_MANAGER' }

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
                    $result.SiteType                                          | Should -Be -ExpectedValue 'Primary'
                    $result.EnableWakeOnLan                                   | Should -Be -ExpectedValue $true
                    $result.WakeOnLanTransmissionMethodType                   | Should -Be -ExpectedValue 'Unicast'
                    $result.RetryNumberOfSendingWakeupPacketTransmission      | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionDelayMins          | Should -Be -ExpectedValue 1
                    $result.MaximumNumberOfSendingWakeupPacketBeforePausing   | Should -Be -ExpectedValue 10000
                    $result.SendingWakeupPacketBeforePausingWaitSec           | Should -Be -ExpectedValue 10
                    $result.ThreadNumberOfSendingWakeupPacket                 | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionOffsetMins         | Should -Be -ExpectedValue 10
                    $result.ClientCertificateCustomStoreName                  | Should -Be -ExpectedValue 'SMSStore'
                    $result.TakeActionForMultipleCertificateMatchCriteria     | Should -Be -ExpectedValue 'FailSelectionAndSendErrorMessage'
                    $result.ClientCertificateSelectionCriteriaType            | Should -Be -ExpectedValue 'CertificateSubjectOrSanIncludesAtrributes'
                    $result.ClientCertificateSelectionCriteriaValue           | Should -Be -ExpectedValue 'Test'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and PKI' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager448Return } -ParameterFilter { $ComponentName -match 'SMS_Site_Component_Manager' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolUnicast } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolComponent } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_MANAGER' }

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
                    $result.SiteType                                          | Should -Be -ExpectedValue 'Primary'
                    $result.EnableWakeOnLan                                   | Should -Be -ExpectedValue $true
                    $result.WakeOnLanTransmissionMethodType                   | Should -Be -ExpectedValue 'Unicast'
                    $result.RetryNumberOfSendingWakeupPacketTransmission      | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionDelayMins          | Should -Be -ExpectedValue 1
                    $result.MaximumNumberOfSendingWakeupPacketBeforePausing   | Should -Be -ExpectedValue 10000
                    $result.SendingWakeupPacketBeforePausingWaitSec           | Should -Be -ExpectedValue 10
                    $result.ThreadNumberOfSendingWakeupPacket                 | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionOffsetMins         | Should -Be -ExpectedValue 10
                    $result.ClientCertificateCustomStoreName                  | Should -Be -ExpectedValue 'SMSStore'
                    $result.TakeActionForMultipleCertificateMatchCriteria     | Should -Be -ExpectedValue 'FailSelectionAndSendErrorMessage'
                    $result.ClientCertificateSelectionCriteriaType            | Should -Be -ExpectedValue 'CertificateSubjectOrSanIncludesAtrributes'
                    $result.ClientCertificateSelectionCriteriaValue           | Should -Be -ExpectedValue 'Test'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and PKI and CRL' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager480Return } -ParameterFilter { $ComponentName -match 'SMS_Site_Component_Manager' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolUnicast } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolComponent } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_MANAGER' }

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
                    $result.SiteType                                          | Should -Be -ExpectedValue 'Primary'
                    $result.EnableWakeOnLan                                   | Should -Be -ExpectedValue $true
                    $result.WakeOnLanTransmissionMethodType                   | Should -Be -ExpectedValue 'Unicast'
                    $result.RetryNumberOfSendingWakeupPacketTransmission      | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionDelayMins          | Should -Be -ExpectedValue 1
                    $result.MaximumNumberOfSendingWakeupPacketBeforePausing   | Should -Be -ExpectedValue 10000
                    $result.SendingWakeupPacketBeforePausingWaitSec           | Should -Be -ExpectedValue 10
                    $result.ThreadNumberOfSendingWakeupPacket                 | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionOffsetMins         | Should -Be -ExpectedValue 10
                    $result.ClientCertificateCustomStoreName                  | Should -Be -ExpectedValue 'SMSStore'
                    $result.TakeActionForMultipleCertificateMatchCriteria     | Should -Be -ExpectedValue 'FailSelectionAndSendErrorMessage'
                    $result.ClientCertificateSelectionCriteriaType            | Should -Be -ExpectedValue 'CertificateSubjectOrSanIncludesAtrributes'
                    $result.ClientCertificateSelectionCriteriaValue           | Should -Be -ExpectedValue 'Test'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and SCCM Cert' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager1216Return } -ParameterFilter { $ComponentName -match 'SMS_Site_Component_Manager' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolUnicast } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolComponent } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_MANAGER' }

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
                    $result.SiteType                                          | Should -Be -ExpectedValue 'Primary'
                    $result.EnableWakeOnLan                                   | Should -Be -ExpectedValue $true
                    $result.WakeOnLanTransmissionMethodType                   | Should -Be -ExpectedValue 'Unicast'
                    $result.RetryNumberOfSendingWakeupPacketTransmission      | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionDelayMins          | Should -Be -ExpectedValue 1
                    $result.MaximumNumberOfSendingWakeupPacketBeforePausing   | Should -Be -ExpectedValue 10000
                    $result.SendingWakeupPacketBeforePausingWaitSec           | Should -Be -ExpectedValue 10
                    $result.ThreadNumberOfSendingWakeupPacket                 | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionOffsetMins         | Should -Be -ExpectedValue 10
                    $result.ClientCertificateCustomStoreName                  | Should -Be -ExpectedValue 'SMSStore'
                    $result.TakeActionForMultipleCertificateMatchCriteria     | Should -Be -ExpectedValue 'FailSelectionAndSendErrorMessage'
                    $result.ClientCertificateSelectionCriteriaType            | Should -Be -ExpectedValue 'CertificateSubjectOrSanIncludesAtrributes'
                    $result.ClientCertificateSelectionCriteriaValue           | Should -Be -ExpectedValue 'Test'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and SCCM Cert and CRL' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager1248Return } -ParameterFilter { $ComponentName -match 'SMS_Site_Component_Manager' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolUnicast } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolComponent } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_MANAGER' }

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
                    $result.SiteType                                          | Should -Be -ExpectedValue 'Primary'
                    $result.EnableWakeOnLan                                   | Should -Be -ExpectedValue $true
                    $result.WakeOnLanTransmissionMethodType                   | Should -Be -ExpectedValue 'Unicast'
                    $result.RetryNumberOfSendingWakeupPacketTransmission      | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionDelayMins          | Should -Be -ExpectedValue 1
                    $result.MaximumNumberOfSendingWakeupPacketBeforePausing   | Should -Be -ExpectedValue 10000
                    $result.SendingWakeupPacketBeforePausingWaitSec           | Should -Be -ExpectedValue 10
                    $result.ThreadNumberOfSendingWakeupPacket                 | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionOffsetMins         | Should -Be -ExpectedValue 10
                    $result.ClientCertificateCustomStoreName                  | Should -Be -ExpectedValue 'SMSStore'
                    $result.TakeActionForMultipleCertificateMatchCriteria     | Should -Be -ExpectedValue 'FailSelectionAndSendErrorMessage'
                    $result.ClientCertificateSelectionCriteriaType            | Should -Be -ExpectedValue 'CertificateSubjectOrSanIncludesAtrributes'
                    $result.ClientCertificateSelectionCriteriaValue           | Should -Be -ExpectedValue 'Test'
                }

                It 'Should return desired result when site configuration settings are HTTPS\HTTP and SCCM Cert and PKI and CRL' {
                    Mock -CommandName Get-CMAlert -MockWith { $getCMAlertEnabled }
                    Mock -CommandName Get-CMSiteDefinition -MockWith { $getSiteDefWarnReturn }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $getSiteCompManager1504Return } -ParameterFilter { $ComponentName -match 'SMS_Site_Component_Manager' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolUnicast } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_COMMUNICATION_MANAGER' }
                    Mock -CommandName Get-CMSiteComponent -MockWith { $wolComponent } -ParameterFilter { $ComponentName -match 'SMS_WAKEONLAN_MANAGER' }

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
                    $result.SiteType                                          | Should -Be -ExpectedValue 'Primary'
                    $result.EnableWakeOnLan                                   | Should -Be -ExpectedValue $true
                    $result.WakeOnLanTransmissionMethodType                   | Should -Be -ExpectedValue 'Unicast'
                    $result.RetryNumberOfSendingWakeupPacketTransmission      | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionDelayMins          | Should -Be -ExpectedValue 1
                    $result.MaximumNumberOfSendingWakeupPacketBeforePausing   | Should -Be -ExpectedValue 10000
                    $result.SendingWakeupPacketBeforePausingWaitSec           | Should -Be -ExpectedValue 10
                    $result.ThreadNumberOfSendingWakeupPacket                 | Should -Be -ExpectedValue 3
                    $result.SendingWakeupPacketTransmissionOffsetMins         | Should -Be -ExpectedValue 10
                    $result.ClientCertificateCustomStoreName                  | Should -Be -ExpectedValue 'Personal'
                    $result.TakeActionForMultipleCertificateMatchCriteria     | Should -Be -ExpectedValue 'FailSelectionAndSendErrorMessage'
                    $result.ClientCertificateSelectionCriteriaType            | Should -Be -ExpectedValue 'CertificateSubjectOrSanIncludesAtrributes'
                    $result.ClientCertificateSelectionCriteriaValue           | Should -Be -ExpectedValue 'Test'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMSiteConfiguration\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
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
                    ClientCertificateSelectionCriteriaValue           = ''
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMSite
            }

            Context 'When Set-TargetResource runs successfully' {
                BeforeEach {
                    $getReturnCas = @{
                        SiteCode                                          = 'Lab'
                        Comment                                           = 'Site Lab'
                        ClientComputerCommunicationType                   = 'HttpsOrHttp'
                        ClientCheckCertificateRevocationListForSiteSystem = $null
                        UsePkiClientCertificate                           = $null
                        UseSmsGeneratedCert                               = $true
                        RequireSigning                                    = $null
                        RequireSha256                                     = $null
                        UseEncryption                                     = $null
                        MaximumConcurrentSendingForAllSite                = 6
                        MaximumConcurrentSendingForPerSite                = 3
                        RetryNumberForConcurrentSending                   = 2
                        ConcurrentSendingDelayBeforeRetryingMins          = 10
                        EnableLowFreeSpaceAlert                           = $null
                        FreeSpaceThresholdWarningGB                       = $null
                        FreeSpaceThresholdCriticalGB                      = $null
                        ThresholdOfSelectCollectionByDefault              = 100
                        ThresholdOfSelectCollectionMax                    = 1000
                        SiteSystemCollectionBehavior                      = 'Warn'
                        SiteType                                          = 'Cas'
                    }

                    $inputNotMatch = @{
                        SiteCode                = 'Lab'
                        EnableLowFreeSpaceAlert = $false
                    }

                    $casMisMatch = @{
                        SiteCode                     = 'Lab'
                        EnableLowFreeSpaceAlert      = $false
                        FreeSpaceThresholdWarningGB  = 10
                        FreeSpaceThresholdCriticalGB = 20
                    }

                    $inputAlerts = @{
                        SiteCode                     = 'Lab'
                        EnableLowFreeSpaceAlert      = $true
                        FreeSpaceThresholdWarningGB  = 20
                        FreeSpaceThresholdCriticalGB = 10
                    }

                    $inputDefaultThresholdMismatch = @{
                        SiteCode                             = 'Lab'
                        Comment                              = 'Site Lab'
                        ThresholdOfSelectCollectionByDefault = 101
                    }

                    $collectionDefault = @{
                        SiteCode                             = 'Lab'
                        ThresholdOfSelectCollectionByDefault = 99
                    }

                    $collectionMax = @{
                        SiteCode                       = 'Lab'
                        ThresholdOfSelectCollectionMax = 999
                    }

                    $alertSetting = @{
                        SiteCode                     = 'Lab'
                        FreeSpaceThresholdWarningGB  = 20
                        FreeSpaceThresholdCriticalGB = 10
                    }

                    $ignoreSMSCert = @{
                        SiteCode                        = 'Lab'
                        UseSmsGeneratedCert             = $true
                        ClientComputerCommunicationType = 'HttpsOnly'
                    }

                    $inputWakeFalse = @{
                        SiteCode                                     = 'Lab'
                        EnableWakeOnLan                              = $false
                        RetryNumberOfSendingWakeupPacketTransmission = 3
                    }

                    $inputBadAuth = @{
                        SiteCode                                = 'Lab'
                        ClientCertificateSelectionCriteriaType  = 'ClientAuthentication'
                        ClientCertificateSelectionCriteriaValue = 'Test'
                    }

                    $inputAuthString = @{
                        SiteCode                                = 'Lab'
                        ClientCertificateSelectionCriteriaType  = 'CertificateSubjectContainsString'
                        ClientCertificateSelectionCriteriaValue = 'Test'
                    }

                    $inputNullCert = @{
                        SiteCode                         = 'Lab'
                        ClientCertificateCustomStoreName = ''
                    }
                }

                It 'Should call expected commands for when changing settings for Primary' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputDefaultThresholdMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for when changing settings for Cas' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnCas }

                    Set-TargetResource @inputDefaultThresholdMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for when changing settings for Primary only settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputNotMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for when changing Alert settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAlerts
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for when specifying Alert settings and enabling alerts is not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @alertSetting
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when specifying UseSmsGeneratedCert and setting ClientComputerCommunicationType to HttpsOnly' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @ignoreSMSCert
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for when changing settings for Cas and specifying Primary only settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnCas }

                    Set-TargetResource @casMisMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands for when changing settings for default collection settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnCas }

                    Set-TargetResource @collectionDefault
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands for when changing settings for max collection settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnCas }

                    Set-TargetResource @collectionMax
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands Wake On Lan false is specified along with additional Wake On Lan parameters' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputWakeFalse
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when ClientCertificateSelectionCriteriaType is erroniously specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputBadAuth
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when ClientCertificateSelectionCriteriaType is changed' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAuthString
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when changing the certificate store with a null string input' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputNullCert
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach {
                    $inputCollectionBad = @{
                        SiteCode                             = 'Lab'
                        ThresholdOfSelectCollectionByDefault = 9
                        ThresholdOfSelectCollectionMax       = 1
                    }

                    $inputEnableAlertCrit = @{
                        SiteCode                     = 'Lab'
                        Comment                      = 'Site Lab'
                        EnableLowFreeSpaceAlert      = $true
                        FreeSpaceThresholdCriticalGB = 6
                    }

                    $inputEnableAlertInvalid = @{
                        SiteCode                     = 'Lab'
                        Comment                      = 'Site Lab'
                        EnableLowFreeSpaceAlert      = $true
                        FreeSpaceThresholdWarningGB  = 5
                        FreeSpaceThresholdCriticalGB = 10
                    }

                    $inputMissingValue = @{
                        SiteCode                                = 'Lab'
                        ClientCertificateSelectionCriteriaType  = 'CertificateSubjectContainsString'
                    }

                    $inputMissingType = @{
                        SiteCode                                = 'Lab'
                        ClientCertificateSelectionCriteriaValue = 'Test'
                    }

                    $collectionError = 'ThresholdOfSelectCollectionByDefault of: 9 must be less than ThresholdOfSelectCollectionMax: 1.'
                    $alertMissing = 'When setting EnableLowFreeSpaceAlert to true, FreeSpaceThreshold warning and critical must be specified.'
                    $alertErrorMsg = 'FreeSpaceThresholdCritical is greater than or equal to FreeSpaceThresholdWarning.  Warning should be greater than Critical.'
                    $certValueError = 'When ClientCertificateSelectionCriteriaType is specified as CertificateSubjectContainsString, ClientCertificateSelectionCriteriaValue is required.'
                    $missingCertType = 'When ClientCertificateSelectionCriteriaValue is specified, ClientCertificateSelectionCriteriaType is required.'
                }

                It 'Should call expected commands and throw when collection default is greater than collection max' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @inputCollectionBad } | Should -Throw -ExpectedMessage $collectionError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw when not all params are specified when setting Alerts to enabled' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @inputEnableAlertCrit } | Should -Throw -ExpectedMessage $alertMissing
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw when not all params are specified when setting Alerts settings are invalid' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @inputEnableAlertInvalid } | Should -Throw -ExpectedMessage $alertErrorMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw when ClientCertificateSelectionCriteriaValue is required but omitted' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @inputMissingValue } | Should -Throw -ExpectedMessage $certValueError
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw when ClientCertificateSelectionCriteriaType is required but omitted' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @inputMissingType } | Should -Throw -ExpectedMessage $missingCertType
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMSite -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMSiteConfiguration\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
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
                }

                $getReturnCas = @{
                    SiteCode                                          = 'Lab'
                    Comment                                           = 'Site Lab'
                    ClientComputerCommunicationType                   = 'HttpsOrHttp'
                    ClientCheckCertificateRevocationListForSiteSystem = $null
                    UsePkiClientCertificate                           = $null
                    UseSmsGeneratedCert                               = $true
                    RequireSigning                                    = $null
                    RequireSha256                                     = $null
                    UseEncryption                                     = $null
                    MaximumConcurrentSendingForAllSite                = 6
                    MaximumConcurrentSendingForPerSite                = 3
                    RetryNumberForConcurrentSending                   = 2
                    ConcurrentSendingDelayBeforeRetryingMins          = 10
                    EnableLowFreeSpaceAlert                           = $null
                    FreeSpaceThresholdWarningGB                       = $null
                    FreeSpaceThresholdCriticalGB                      = $null
                    ThresholdOfSelectCollectionByDefault              = 100
                    ThresholdOfSelectCollectionMax                    = 1000
                    SiteSystemCollectionBehavior                      = 'Warn'
                    SiteType                                          = 'Cas'
                }

                $getReturnAlertDisabled = @{
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
                    EnableLowFreeSpaceAlert                           = $false
                    FreeSpaceThresholdWarningGB                       = $null
                    FreeSpaceThresholdCriticalGB                      = $null
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

                $inputAlertsWarning = @{
                    SiteCode                     = 'Lab'
                    EnableLowFreeSpaceAlert      = $true
                    FreeSpaceThresholdWarningGB  = 10
                    FreeSpaceThresholdCriticalGB = 20
                }

                $casMisMatch = @{
                    SiteCode                     = 'Lab'
                    EnableLowFreeSpaceAlert      = $true
                    FreeSpaceThresholdWarningGB  = 10
                    FreeSpaceThresholdCriticalGB = 20
                }

                $inputSmsCertWithHttpsOnly = @{
                    SiteCode                        = 'Lab'
                    Comment                         = 'Site Lab'
                    ClientComputerCommunicationType = 'HttpsOnly'
                    UseSmsGeneratedCert             = $true
                }

                $inputEnableAlertWithValue = @{
                    SiteCode                     = 'Lab'
                    Comment                      = 'Site Lab'
                    EnableLowFreeSpaceAlert      = $true
                    FreeSpaceThresholdWarningGB  = 11
                    FreeSpaceThresholdCriticalGB = 6
                }

                $inputEnableAlertCrit = @{
                    SiteCode                     = 'Lab'
                    Comment                      = 'Site Lab'
                    EnableLowFreeSpaceAlert      = $true
                    FreeSpaceThresholdCriticalGB = 6
                }

                $inputDisableAlertCrit = @{
                    SiteCode                     = 'Lab'
                    Comment                      = 'Site Lab'
                    EnableLowFreeSpaceAlert      = $false
                    FreeSpaceThresholdCriticalGB = 6
                }

                $collectionDefault = @{
                    SiteCode                             = 'Lab'
                    ThresholdOfSelectCollectionByDefault = 99
                }

                $collectionMax = @{
                    SiteCode                       = 'Lab'
                    ThresholdOfSelectCollectionMax = 999
                }

                $collectionBad = @{
                    SiteCode                             = 'Lab'
                    ThresholdOfSelectCollectionByDefault = 9
                    ThresholdOfSelectCollectionMax       = 1
                }

                $inputWakeFalse = @{
                    SiteCode                                     = 'Lab'
                    EnableWakeOnLan                              = $false
                    RetryNumberOfSendingWakeupPacketTransmission = 3
                }

                $inputBadAuth = @{
                    SiteCode                                = 'Lab'
                    ClientCertificateSelectionCriteriaType  = 'ClientAuthentication'
                    ClientCertificateSelectionCriteriaValue = 'Test'
                }

                $inputMissingValue = @{
                    SiteCode                                = 'Lab'
                    ClientCertificateSelectionCriteriaType  = 'CertificateSubjectContainsString'
                }

                $inputMissingType = @{
                    SiteCode                                = 'Lab'
                    ClientCertificateSelectionCriteriaValue = 'Test'
                }

                $inputAuthString = @{
                    SiteCode                                = 'Lab'
                    ClientCertificateSelectionCriteriaType  = 'CertificateSubjectContainsString'
                    ClientCertificateSelectionCriteriaValue = 'Test'
                }

                $inputNullCert = @{
                    SiteCode                         = 'Lab'
                    ClientCertificateCustomStoreName = ''
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource for Primary Server' {
                BeforeEach {
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

                It 'Should return desired result false when desired result when only specifying warning alert settings' {

                    Test-TargetResource @inputEnableAlertCrit | Should -Be $false
                }

                It 'Should return desired result false when desired result does not equal current state with enabling Alerts bad input' {

                    Test-TargetResource @inputAlertsWarning | Should -Be $false
                }

                It 'Should return desired result false when collection default does not match' {

                    Test-TargetResource @collectionDefault | Should -Be $false
                }

                It 'Should return desired result false when collection max does not match' {

                    Test-TargetResource @collectionMax | Should -Be $false
                }

                It 'Should return desired result false when collection default and max values are not valid' {

                    Test-TargetResource @collectionBad | Should -Be $false
                }

                It 'Should return desired result false when specifying alert settings and settings alerts to disabled' {

                    Test-TargetResource @inputDisableAlertCrit | Should -Be $false
                }

                It 'Should return desired result false when WOL is specified false and warn for bad params' {

                    Test-TargetResource @inputWakeFalse | Should -Be $false
                }

                It 'Should return desired result true fpr Cert Selection type and warn for bad params' {

                    Test-TargetResource @inputBadAuth | Should -Be $true
                }

                It 'Should return desired result false when ClientCertificateSelectionCriteriaValue is missing' {

                    Test-TargetResource @inputMissingValue | Should -Be $false
                }

                It 'Should return desired result false when ClientCertificateSelectionCriteriaType is missing' {

                    Test-TargetResource @inputMissingType | Should -Be $false
                }

                It 'Should return desired result false when ClientCertificateSelectionCriteriaType is mismatched' {

                    Test-TargetResource @inputAuthString | Should -Be $false
                }

                It 'Should return desired result false when Certificate Store mismatched and warn when null' {

                    Test-TargetResource @inputNullCert | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource for Cas Server' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnCas }
                }

                It 'Should return desired result true when desired result specifying Primary Setting on Cas' {

                    Test-TargetResource @casMisMatch | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
