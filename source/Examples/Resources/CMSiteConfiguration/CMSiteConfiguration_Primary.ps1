<#
    .SYNOPSIS
        A DSC configuration to configure Site Configurations in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSiteConfiguration ExampleConfig
        {
            SiteCode                                          = 'PRI'
            Comment                                           = 'Lab Site Primary'
            MaximumConcurrentSendingForAllSite                = 5
            MaximumConcurrentSendingForPerSite                = 3
            RetryNumberForConcurrentSending                   = 10
            ConcurrentSendingDelayBeforeRetryingMins          = 5
            ThresholdOfSelectCollectionByDefault              = 100
            ThresholdOfSelectCollectionMax                    = 0
            SiteSystemCollectionBehavior                      = 'Block'
            EnableLowFreeSpaceAlert                           = $true
            FreeSpaceThresholdWarningGB                       = 10
            FreeSpaceThresholdCriticalGB                      = 5
            ClientComputerCommunicationType                   = 'HttpsOrHttp'
            ClientCheckCertificateRevocationListForSiteSystem = $true
            UsePkiClientCertificate                           = $true
            UseSmsGeneratedCert                               = $true
            RequireSha256                                     = $true
            RequireSigning                                    = $true
            UseEncryption                                     = $true
            EnableWakeOnLan                                   = $true
            WakeOnLanTransmissionMethodType                   = 'Unicast'
            RetryNumberOfSendingWakeupPacketTransmission      = 3
            SendingWakeupPacketTransmissionDelayMins          = 1
            MaximumNumberOfSendingWakeupPacketBeforePausing   = 10000
            SendingWakeupPacketBeforePausingWaitSec           = 10
            ThreadNumberOfSendingWakeupPacket                 = 3
            SendingWakeupPacketTransmissionOffsetMins         = 0
            ClientCertificateCustomStoreName                  = 'Personal'
            TakeActionForMultipleCertificateMatchCriteria     = 'SelectCertificateWithLongestValidityPeriod'
            ClientCertificateSelectionCriteriaType            = 'ClientAuthentication'
        }
    }
}
