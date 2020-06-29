<#
    .SYNOPSIS
        A DSC configuration script to remove a distribution point group from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMDistributionPointGroup ExampleSettings
        {
            SiteCode               = 'Lab'
            DistributionPointGroup = 'DistroGroup1'
            Ensure                 = 'Absent'
        }
    }
}
