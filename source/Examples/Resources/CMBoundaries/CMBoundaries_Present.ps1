<#
    .SYNOPSIS
        A DSC configuration script to add boundaries to Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMBoundaries ExampleSubnet
        {
            SiteCode    = 'Lab'
            DisplayName = 'Subnet 1'
            Type        = 'IPSubnet'
            Value       = '10.1.1.1/24'
            Ensure      = 'Present'
        }

        CMBoundaries ExampleAdSite
        {
            SiteCode    = 'Lab'
            DisplayName = 'Site 1'
            Type        = 'ADSite'
            Value       = 'Default-First-Site'
            Ensure      = 'Present'
        }

        CMBoundaries ExampleIpRange
        {
            SiteCode    = 'Lab'
            DisplayName = 'Range 1'
            Type        = 'IPRange'
            Value       = '10.1.1.1-10.1.1.255'
            Ensure      = 'Present'
        }
    }
}
