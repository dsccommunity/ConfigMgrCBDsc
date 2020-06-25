<#
    .SYNOPSIS
        A DSC configuration script for system discovery to include ad containers.
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
            ScheduleInterval                = 'Days'
            ScheduleCount                   = 7
            EnableDeltaDiscovery            = $true
            DeltaDiscoveryMins              = 50
            EnableFilteringExpiredLogon     = $true
            TimeSinceLastLogonDays          = 20
            EnableFilteringExpiredPassword  = $true
            TimeSinceLastPasswordUpdateDays = 40
            ADContainersToInclude           = @(
                'LDAP://OU=Far,DC=contoso,DC=com','LDAP://OU=Far,OU=Domain Controllers,DC=contoso,DC=com',
                'LDAP://OU=Far,OU=Deployables,DC=contoso,DC=com'
            )
        }
    }
}
