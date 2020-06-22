<#
    .SYNOPSIS
        A DSC configuration script to system discovery set to a custom schedule to none.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSystemDiscovery ExampleSettings
        {
            SiteCode                        = 'Lab'
            Enabled                         = $true
            ScheduleInterval                = 'None'
            EnableDeltaDiscovery            = $true
            DeltaDiscoveryMins              = 50
            EnableFilteringExpiredLogon     = $true
            TimeSinceLastLogonDays          = 20
            EnableFilteringExpiredPassword  = $true
            TimeSinceLastPasswordUpdateDays = 40
            ADContainers                    = @(
                'LDAP://OU=Far,DC=contoso,DC=com','LDAP://OU=Far,OU=Domain Controllers,DC=contoso,DC=com',
                'LDAP://OU=Far,OU=Deployables,DC=contoso,DC=com'
            )
        }
    }
}
