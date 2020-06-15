<#
    .SYNOPSIS
        A DSC configuration script to add a software update point to Configuration Manager with CMG enabled.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSoftwareUpdatePoint ExampleSettings
        {
            SiteCode                      = 'Lab'
            SiteServerName                = 'CA01.contoso.com'
            ClientConnectionType          = 'InternetAndIntranet'
            EnableCloudGateway            = $true
            UseProxy                      = $false
            UseProxyForAutoDeploymentRule = $false
            WsusAccessAccount             = 'contoso\admin'
            WsusIisPort                   = '8530'
            WsusIisSslPort                = '8531'
            WsusSsl                       = $true
            Ensure                        = 'Present'
        }
    }
}
