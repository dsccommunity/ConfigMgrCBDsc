<#
    .SYNOPSIS
        A DSC configuration script to add a distribution point group from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMDistributionGroup ExampleSettingsCreate
        {
            SiteCode          = 'Lab'
            DistributionGroup = 'DistroGroup1'
            Ensure            = 'Present'
        }

        CMDistributionGroup ExampleSettingsMatch
        {
            SiteCode           = 'Lab'
            DistributionGroup  = 'DistroGroup2'
            DistributionPoints = 'DP01.contoso.com','DP02.contoso.com'
            SecurityScopes     = 'Scope1','Scope2'
            Collections        = 'Collection 1', 'Collection 2'
            Ensure             = 'Present'
        }

        CMDistributionGroup ExampleSettingsAdd
        {
            SiteCode                    = 'Lab'
            DistributionGroup           = 'DistroGroup3'
            DistributionPointsToInclude = 'DP01.contoso.com','DP02.contoso.com'
            SecurityScopesToInclude     = 'Scope1','Scope2'
            CollectionsToInclude        = 'Collection 1', 'Collection 2'
            Ensure                      = 'Present'
        }

        CMDistributionGroup ExampleSettingsRemove
        {
            SiteCode                    = 'Lab'
            DistributionGroup           = 'DistroGroup4'
            DistributionPointsToExclude = 'DP01.contoso.com'
            SecurityScopesToExclude     = 'Scope1'
            CollectionsToExclude        = 'Collection 1', 'Collection 2'
            Ensure                      = 'Present'
        }
    }
}
