<#
    .SYNOPSIS
        A DSC configuration to configure the different types of file replication settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMFileReplication ExampleLimited
        {
            SiteCode             = 'LAB'
            DestinationSiteCode  = 'PR1'
            Limited              = $true
            NetworkLoadSchedule  = @(
                DSC_CMReplicationNetworkLoadSchedule
                {
                    Day       = 'Wednesday'
                    BeginHour = 0
                    EndHour   = 0
                    Type      = 'High'
                }
                DSC_CMReplicationNetworkLoadSchedule
                {
                    Day       = 'Friday'
                    BeginHour = 0
                    EndHour   = 4
                    Type      = 'All'
                }
            )
            RateLimitingSchedule = @(
                DSC_CMRateLimitingSchedule
                {
                    LimitedBeginHour               = 0
                    LimitedEndHour                 = 4
                    LimitAvailableBandwidthPercent = 70
                }
                DSC_CMRateLimitingSchedule
                {
                    LimitedBeginHour               = 4
                    LimitedEndHour                 = 12
                    LimitAvailableBandwidthPercent = 90
                }
                DSC_CMRateLimitingSchedule
                {
                    LimitedBeginHour               = 12
                    LimitedEndHour                 = 0
                    LimitAvailableBandwidthPercent = 100
                }
            )
        }

        CMFileReplication ExamplePulse
        {
            SiteCode                 = 'LAB'
            DestinationSiteCode      = 'PR2'
            PulseMode                = $true
            DataBlockSizeKB          = 200
            DelayBetweenDataBlockSec = 15
            UseSystemAccount         = $true
            NetworkLoadSchedule      = @(
                DSC_CMReplicationNetworkLoadSchedule
                {
                    Day       = 'Wednesday'
                    BeginHour = 0
                    EndHour   = 0
                    Type      = 'High'
                }
                DSC_CMReplicationNetworkLoadSchedule
                {
                    Day       = 'Friday'
                    BeginHour = 0
                    EndHour   = 4
                    Type      = 'All'
                }
            )
        }

        CMFileReplication ExampleUnlimited
        {
            SiteCode                   = 'LAB'
            DestinationSiteCode        = 'PR3'
            Unlimited                  = $true
            FileReplicationAccountName = 'contoso\ReplAccount'
        }
    }
}
