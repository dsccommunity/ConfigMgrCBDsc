<#
    .SYNOPSIS
        A DSC configuration script to add an asset intelligence synchronization point to Configuration Manager.

    # MIGHT need to put a throw in the PSD1 if you set a schedule and don't enable synchronization
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMAssetIntelligencePoint ExampleSettings
        {
            SiteCode              = 'Lab'
            SiteServerName        = 'CA01.contoso.com'
            Ensure                = 'Present'
            Schedule              = DSC_CMAssetIntelligenceSynchronizationSchedule
            {
                RecurInterval = 'Days'
                RecurCount    = '7'
            }
            Enable                = $True
            EnableSynchronization = $True
        }
    }
}
