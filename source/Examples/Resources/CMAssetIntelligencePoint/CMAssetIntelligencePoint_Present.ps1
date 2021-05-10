<#
    .SYNOPSIS
        A DSC configuration script to add an asset intelligence synchronization point to Configuration Manager.
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
            ScheduleType          = 'Days'
            RecurInterval         = '7'
            Enable                = $True
            EnableSynchronization = $True
            IsSingleInstance      = 'Yes'
        }
    }
}
