<#
    .SYNOPSIS
        A DSC configuration script for system discovery to include and exclude group discovery scopes.
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
            ScheduleType                        = 'Days'
            RecurInterval                       = 7
            EnableDeltaDiscovery                = $true
            DeltaDiscoveryMins                  = 50
            EnableFilteringExpiredLogon         = $true
            TimeSinceLastLogonDays              = 20
            EnableFilteringExpiredPassword      = $true
            TimeSinceLastPasswordUpdateDays     = 40
            DiscoverDistributionGroupMembership = $true
            GroupDiscoveryScopeToInclude        = @(
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
            GroupDiscoveryScopeToExclude = @('Test4')
        }
    }
}
