<#
    .SYNOPSIS
        A DSC configuration script to create an administrative users in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMAdministrativeUser User1
        {
            SiteCode             = 'Lab'
            AdminName            = 'contoso\User1'
            RolesToInclude       = 'Security Administrator'
            RolesToExclude       = 'Remote Tools Operator'
            CollectionsToInclude = 'Collection0'
            CollectionsToExclude = 'Collection1'
            ScopesToInclude      = 'Default'
            ScopesToExclude      = 'Test'
            Ensure               = 'Present'
        }

        CMAdministrativeUser User2
        {
            SiteCode    = 'Lab'
            AdminName   = 'contoso\User2'
            Roles       = 'Security Administrator'
            Collections = 'Collection0'
            Scopes      = 'Default'
            Ensure      = 'Present'
        }

        CMAdministrativeUser User3
        {
            SiteCode    = 'Lab'
            AdminName   = 'contoso\User3'
            Roles       = 'Security Administrator','Full Administrator'
            Collections = 'Collection0','Collection1'
            Scopes      = 'Default','Scope1'
            Ensure      = 'Present'
        }
    }
}
