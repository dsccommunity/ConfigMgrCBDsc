<#
    .SYNOPSIS
        A DSC configuration script to configure site system server for Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSiteSystemServer SS01Server
        {
            SiteCode             = 'Lab'
            SiteSystemServer     = 'SS01.contoso.com'
            UseSiteServerAccount = $false
            PublicFqdn           = 'SS01.contoso.com'
            EnableProxy          = $false
            ProxyServerName      = 'CA01.contoso.com'
            ProxyAccessAccount   = 'contoso\Proxy'
            FdmOperation         = $true
            AccountName          = 'contoso\Account'
            Ensure               = 'Present'
        }

        CMSiteSystemServer SS02Server
        {
            SiteCode             = 'Lab'
            SiteSystemServer     = 'SS02.contoso.com'
            UseSiteServerAccount = $true
            PublicFqdn           = ''
            EnableProxy          = $false
            ProxyServerName      = 'CA01.contoso.com'
            ProxyAccessAccount   = 'contoso\Proxy'
            ProxyServerPort      = 443
            FdmOperation         = $true
            Ensure               = 'Present'
        }

        CMSiteSystemServer SS03Server
        {
            SiteCode             = 'Lab'
            SiteSystemServer     = 'SS03.contoso.com'
            UseSiteServerAccount = $true
            PublicFqdn           = ''
            EnableProxy          = $false
            ProxyServerName      = 'CA01.contoso.com'
            ProxyAccessAccount   = ''
            ProxyServerPort      = 443
            FdmOperation         = $true
            Ensure               = 'Present'
        }
    }
}
