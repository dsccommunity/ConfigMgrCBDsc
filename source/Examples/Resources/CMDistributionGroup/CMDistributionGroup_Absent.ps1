<#
    .SYNOPSIS
        A DSC configuration script to remove a distribution point group from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMDistributionGroup ExampleSettings
        {
            SiteCode          = 'Lab'
            DistributionGroup = 'DistroGroup1'
            Ensure            = 'Absent'
        }
    }
}
