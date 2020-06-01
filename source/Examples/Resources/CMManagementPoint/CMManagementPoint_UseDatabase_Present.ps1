<#
    .SYNOPSIS
        A DSC configuration script to add a management point with local database to Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMManagementPoint ExampleSettings
        {
            SiteCode              = 'Lab'
            SiteServerName        = 'MP01.contoso.com'
            Ensure                = 'Present'
            EnableSSL             = $true
            GenerateAlert         = $true
            Username              = 'contoso\username'
            UseSiteDatabase       = $false
            EnableCloudGateway    = $true
            ClientConnectionType  = 'InternetAndIntranet'
            SqlServerFqdn         = 'MP01.contoso.com'
            DatabaseName          = 'CM_Lab'
            SqlServerInstanceName = 'MP01SqlInstance'
        }
    }
}
