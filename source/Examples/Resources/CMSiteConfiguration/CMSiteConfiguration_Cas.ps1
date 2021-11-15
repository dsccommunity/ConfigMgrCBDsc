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
            SiteCode                                 = 'Lab'
            Comment                                  = 'Lab Site CAS'
            MaximumConcurrentSendingForAllSite       = 5
            MaximumConcurrentSendingForPerSite       = 3
            RetryNumberForConcurrentSending          = 10
            ConcurrentSendingDelayBeforeRetryingMins = 5
            ThresholdOfSelectCollectionByDefault     = 100
            ThresholdOfSelectCollectionMax           = 0
            SiteSystemCollectionBehavior             = 'Block'
            ClientComputerCommunicationType          = 'HttpsOrHttp'
            UseSmsGeneratedCert                      = $true
        }
    }
}
