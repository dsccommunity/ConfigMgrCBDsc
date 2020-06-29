<#
    .SYNOPSIS
        A DSC configuration script to add a distribution point group from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMDistributionPointGroup ExampleSettingsCreate
        {
            SiteCode               = 'Lab'
            DistributionPointGroup = 'DistroGroup1'
            Ensure                 = 'Present'
        }

        CMDistributionPointGroup ExampleSettingsMatch
        {
            SiteCode               = 'Lab'
            DistributionPointGroup = 'DistroGroup2'
            DistributionPoints     = 'DP01.contoso.com','DP02.contoso.com'
            Ensure                 = 'Present'
        }

        CMDistributionPointGroup ExampleSettingsAdd
        {
            SiteCode                    = 'Lab'
            DistributionPointGroup      = 'DistroGroup3'
            DistributionPointsToInclude = 'DP01.contoso.com','DP02.contoso.com'
            Ensure                      = 'Present'
        }

        CMDistributionPointGroup ExampleSettingsRemove
        {
            SiteCode                    = 'Lab'
            DistributionPointGroup      = 'DistroGroup4'
            DistributionPointsToExclude = 'DP01.contoso.com'
            Ensure                      = 'Present'
        }
    }
}
