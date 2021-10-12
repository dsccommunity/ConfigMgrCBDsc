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
            ConfigureBranchCache      = $false
            MaxCacheSize              = 20000
            MaxBranchCacheSizePercent = 10
            ConfigureCacheSize        = $true
            ClientSettingName         = 'Default Client Agent Settings'
            EnableSuperPeer           = $false
            DownloadPort              = 8003
            EnableBranchCache         = $false
        }

        CMClientSettingsClientCache DeviceAgent
        {
            SiteCode                  = 'Lab'
            BroadcastPort             = 8004
            MaxCacheSizePercent       = 20
            ConfigureBranchCache      = $false
            MaxCacheSize              = 20000
            MaxBranchCacheSizePercent = 10
            ConfigureCacheSize        = $true
            ClientSettingName         = 'ClientTest'
            EnableSuperPeer           = $false
            DownloadPort              = 8003
            EnableBranchCache         = $false
        }
    }
}
