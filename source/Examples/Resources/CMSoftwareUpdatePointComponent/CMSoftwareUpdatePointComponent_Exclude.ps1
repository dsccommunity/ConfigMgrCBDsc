<#
    .SYNOPSIS
        A DSC configuration script to modify the top level hierarchy Software Update Point Component.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSoftwareUpdatePointComponent ExampleSettings
        {
            SiteCode                                = 'Lab'
            EnableSynchronization                   = $true
            SynchronizeAction                       = 'SynchronizeFromMicrosoftUpdate'
            ScheduleType                            = 'Days'
            RecurInterval                           = 7
            LanguageSummaryDetailsToExclude         = @('German','Italian')
            LanguageUpdateFilesToExclude            = @('German','Italian')
            ProductsToExclude                       = @('Windows XP','Windows Server 2003')
            UpdateClassificationsToExclude          = @('Feature Packs','Tools')
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
        }
    }
}
