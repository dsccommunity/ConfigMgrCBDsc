<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for software update settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsSoftwareUpdate DefaultAgent
        {
            SiteCode                = 'Lab'
            ClientSettingName       = 'Default Client Agent Settings'
            Enable                  = $true
            EnableDeltaDownload     = $false
            DeltaDownloadPort       = 8005
            ScanStart               = '2/1/1970 00:00'
            ScanRecurInterval       = 8
            ScanScheduleType        = 'Hours'
            EvalStart               = '2/1/1970 00:00'
            EvalScheduleType        = 'Hours'
            EvalRecurInterval       = 8
            EnforceMandatory        = $true
            TimeUnit                = 'Hours'
            BatchingTimeOut         = 1
            EnableThirdPartyUpdates = $true
            Office365ManagementType = 'Yes'
        }

        CMClientSettingsSoftwareUpdate DeviceAgent
        {
            SiteCode                = 'Lab'
            ClientSettingName       = 'PC Imaging'
            Enable                  = $true
            ScanStart               = '2/1/1970 00:00'
            ScanScheduleType        = 'Hours'
            ScanRecurInterval       = 1
            EvalStart               = '2/1/1970 00:00'
            EvalScheduleType        = 'Hours'
            EvalRecurInterval       = 3
            EnableDeltaDownload     = $true
            DeltaDownloadPort       = 8005
            EnforceMandatory        = $true
            TimeUnit                = 'Hours'
            BatchingTimeOut         = 23
            EnableThirdPartyUpdates = $true
            Office365ManagementType = 'NotConfigured'
        }
    }
}
