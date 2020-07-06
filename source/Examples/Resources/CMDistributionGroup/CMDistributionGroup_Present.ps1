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
            Ensure             = 'Present'
        }

        CMDistributionGroup ExampleSettingsAdd
        {
            SiteCode                    = 'Lab'
            DistributionGroup           = 'DistroGroup3'
            DistributionPointsToInclude = 'DP01.contoso.com','DP02.contoso.com'
            Ensure                      = 'Present'
        }

        CMDistributionGroup ExampleSettingsRemove
        {
            SiteCode                    = 'Lab'
            DistributionGroup           = 'DistroGroup4'
            DistributionPointsToExclude = 'DP01.contoso.com'
            Ensure                      = 'Present'
        }
    }
}
