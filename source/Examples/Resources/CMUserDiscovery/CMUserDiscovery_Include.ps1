<#
    .SYNOPSIS
        A DSC configuration script for user discovery to include ad containers.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMUserDiscovery ExampleSettings
        {
            SiteCode              = 'Lab'
            Enabled               = $true
            ScheduleInterval      = 'Days'
            ScheduleCount         = 7
            EnableDeltaDiscovery  = $true
            DeltaDiscoveryMins    = 50
            ADContainersToInclude = @(
                'LDAP://OU=Far,DC=contoso,DC=com','LDAP://OU=Far,OU=Domain Controllers,DC=contoso,DC=com',
                'LDAP://OU=Far,OU=Deployables,DC=contoso,DC=com'
            )
        }
    }
}
