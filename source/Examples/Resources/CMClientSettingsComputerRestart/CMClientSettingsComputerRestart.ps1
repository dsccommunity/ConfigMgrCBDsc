<#
    .SYNOPSIS
        A DSC configuration script to modify client policy settings for computer restart settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {

        CMClientSettingsComputerRestart DeviceAgent
        {
            SiteCode                           = 'Lab'
            ClientSettingName                  = 'ClientTest'
            NoRebootEnforcement                = $true
            CountdownMins                      = 30
            FinalWindowMins                    = 10
            ReplaceToastNotificationWithDialog = $true
        }
    }
}
