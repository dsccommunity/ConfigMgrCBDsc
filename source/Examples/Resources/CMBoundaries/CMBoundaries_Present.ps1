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
            Value       = '10.1.1.0/24'
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

        CMBoundaries ExampleVPN
        {
            SiteCode    = 'Lab'
            DisplayName = 'VPN AutoDetect'
            Type        = 'VPN'
            Value       = 'Auto:On'
            Ensure      = 'Present'
        }


        CMBoundaries ExampleVPNDescription
        {
            SiteCode    = 'Lab'
            DisplayName = 'VPN ConnectionDescription'
            Type        = 'VPN'
            Value       = 'Description:Contoso VPN'
            Ensure      = 'Present'
        }

        CMBoundaries ExampleVPNName
        {
            SiteCode    = 'Lab'
            DisplayName = 'VPN ConnectionName'
            Type        = 'VPN'
            Value       = 'Name:Contoso.com'
            Ensure      = 'Present'
        }

        CMBoundaries ExampleIPv6
        {
            SiteCode    = 'Lab'
            DisplayName = 'IPv6 1'
            Type        = 'IPv6Prefix'
            Value       = '2001:0DB8:0000:000b'
            Ensure      = 'Present'
        }
    }
}
