<#
    .SYNOPSIS
        A DSC configuration script to remove Security Roles from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSecurityRoles ExampleSettings
        {
            SiteCode          = 'Lab'
            SecurityRoleName  = 'Field Services'
            Ensure            = 'Absent'
        }
    }
}
