Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMClientPushSettings Clientsettings
        {
            SiteCode          = 'Lab'
            AccountsToInclude = @('contoso\Push1','contoso\Push2')
            AccountsToExclude = @('contoso\Push3','contoso\Push4')
        }
    }
}
