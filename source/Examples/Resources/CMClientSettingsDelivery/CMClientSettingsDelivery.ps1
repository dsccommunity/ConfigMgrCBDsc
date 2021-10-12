<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for delivery.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientSettingsDelivery DefaultAgent
        {
            SiteCode          = 'Lab'
            Enable            = $true
            ClientSettingName = 'Default Client Agent Settings'
        }

        CMClientSettingsDelivery DeviceAgent
        {
            SiteCode          = 'Lab'
            Enable            = $false
		    ClientSettingName = 'ClientTest'
        }
    }
}
