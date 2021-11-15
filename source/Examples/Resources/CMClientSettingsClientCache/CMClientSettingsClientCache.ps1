<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for client cache.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsClientCache DefaultAgent
        {
            SiteCode                  = 'Lab'
            BroadcastPort             = 8004
            MaxCacheSizePercent       = 20
            ConfigureBranchCache      = $true
            MaxCacheSize              = 20000
            MaxBranchCacheSizePercent = 10
            ConfigureCacheSize        = $true
            ClientSettingName         = 'Default Client Agent Settings'
            EnableSuperPeer           = $true
            DownloadPort              = 8003
            EnableBranchCache         = $true
        }

        CMClientSettingsClientCache DeviceAgent
        {
            SiteCode                  = 'Lab'
            BroadcastPort             = 8004
            MaxCacheSizePercent       = 20
            ConfigureBranchCache      = $true
            MaxCacheSize              = 20000
            MaxBranchCacheSizePercent = 10
            ConfigureCacheSize        = $true
            ClientSettingName         = 'ClientTest'
            EnableSuperPeer           = $true
            DownloadPort              = 8003
            EnableBranchCache         = $true
        }
    }
}
