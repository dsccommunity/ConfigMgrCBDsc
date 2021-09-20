<#
    .SYNOPSIS
        A DSC configuration script to set group discovery enabled.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMGroupDiscovery ExampleSettings
        {
            SiteCode                            = 'Lab'
            Enabled                             = $true
            ScheduleType                        = 'MonthlyByWeek'
            RecurInterval                       = 1
            MonthlyWeekOrder                    = 'Last'
            DayOfWeek                           = 'Friday'
            EnableDeltaDiscovery                = $true
            DeltaDiscoveryMins                  = 60
            EnableFilteringExpiredLogon         = $true
            TimeSinceLastLogonDays              = 90
            EnableFilteringExpiredPassword      = $true
            TimeSinceLastPasswordUpdateDays     = 90
            DiscoverDistributionGroupMembership = $true
            GroupDiscoveryScope                 = @(
                DSC_CMGroupDiscoveryScope
                {
                    Name         = 'test1'
                    LdapLocation = 'LDAP://OU=Test1,DC=contoso,DC=com'
                    Recurse      = $false
                }
                DSC_CMGroupDiscoveryScope
                {
                    Name         = 'test2'
                    LdapLocation = 'LDAP://OU=Test2,DC=contoso,DC=com'
                    Recurse      = $false
                }
            )
        }
    }
}
