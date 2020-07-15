<#
    .SYNOPSIS
        A DSC configuration script to add a Security Scope to Configuration Manager.
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
            Description       = 'Test Scope for DSC'
            Ensure            = 'Present'
        }
    }
}
