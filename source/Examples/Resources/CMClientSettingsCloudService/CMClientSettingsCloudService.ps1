<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for cloud services.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsCloudService DefaultAgent
        {
            SiteCode                    = 'Lab'
            AutoAzureADJoin             = $true
            AllowCloudDistributionPoint = $false
            AllowCloudManagementGateway = $true
            ClientSettingName           = 'Default Client Agent Settings'
        }

        CMClientSettingsCloudService DeviceAgent
        {
            SiteCode                    = 'Lab'
            AutoAzureADJoin             = $true
            AllowCloudDistributionPoint = $true
            AllowCloudManagementGateway = $true
            ClientSettingName           = 'ClientTest'
        }

        CMClientSettingsCloudService UserAgent
        {
            SiteCode                    = 'Lab'
            AllowCloudDistributionPoint = $true
            ClientSettingName           = 'UserTest'
        }
    }
}
