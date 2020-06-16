<#
    .SYNOPSIS
        A DSC configuration script to enable Network Discovery for Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMNetworkDiscovery ExampleSettings
        {
            SiteCode = 'Lab'
            Enabled  = $true
        }
    }
}
