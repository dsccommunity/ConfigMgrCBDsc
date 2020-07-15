<#
    .SYNOPSIS
        A DSC configuration script to remove a Security Scope from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSecurityScopes Example
        {
            SiteCode          = 'Lab'
            SecurityScopeName = 'TestScope1'
            Ensure            = 'Absent'
        }
    }
}
