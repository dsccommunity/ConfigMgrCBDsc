Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientPushSettings Clientsettings
        {
            SiteCode                              = 'Lab'
            EnableAutomaticClientPushInstallation = $false
        }
    }
}
