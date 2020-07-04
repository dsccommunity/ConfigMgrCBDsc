<#
    .SYNOPSIS
        A DSC configuration script to add Distribution Groups to a Distribution Point in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMDistributionPointGroupMembers DP01
        {
            SiteCode           = 'Lab'
            DistributionPoint  = 'DP01.contoso.com'
            DistributionGroups = 'TestGroup1','TestGroup2','TestGroup3'
        }

        CMDistributionPointGroupMembers DP02
        {
            SiteCode                    = 'Lab'
            DistributionPoint           = 'DP02.contoso.com'
            DistributionGroupsToInclude = 'TestGroup1','TestGroup2'
            DistributionGroupsToExclude = 'TestGroup3','TestGroup4'
        }
    }
}
