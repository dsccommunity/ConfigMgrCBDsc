Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientPushSettings Clientsettings
        {
            SiteCode                              = 'Lab'
            EnableAutomaticClientPushInstallation = $true
            EnableSystemTypeConfigurationManager  = $false
            EnableSystemTypeServer                = $true
            EnableSystemTypeWorkstation           = $true
            InstallClientToDomainController       = $true
            InstallationProperty                  = 'SMSSITECODE=Lab CCMLOGMAXSIZE=3000000 CCMLOGLEVEL=0 CCMLOGMAXHISTORY=2 /skipprereq:silverlight.exe'
            Accounts                              = @('contoso\Push1','contoso\Push2')
        }
    }
}
