<#
    .SYNOPSIS
        A DSC configuration script to remove a distribution point from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMDistributionPoint ExampleSettings
        {
            SiteCode       = 'Lab'
            SiteServerName = 'DP01.contoso.com'
            Ensure         = 'Absent'
        }
    }
}
