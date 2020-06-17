<#
    .SYNOPSIS
        A DSC configuration script to system discovery set to none.
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
                'LDAP://OU=Far East,DC=contoso,DC=com','LDAP://OU=Far East,OU=Domain Controllers,DC=jeffo,DC=lab',
                'LDAP://OU=Far East,OU=Deployables,DC=jeffo,DC=lab'
            )
        }
    }
}
