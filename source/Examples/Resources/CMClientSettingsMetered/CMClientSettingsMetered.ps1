<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for metered network.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsMetered DefaultAgent
        {
            SiteCode            = 'Lab'
            MeteredNetworkUsage = 'Block'
            ClientSettingName   = 'Default Client Agent Settings'
        }

        CMClientSettingsMetered DeviceAgent
        {
            SiteCode            = 'Lab'
            MeteredNetworkUsage = 'Allow'
            ClientSettingName   = 'ClientTest'
        }
    }
}
