<#
    .SYNOPSIS
        A DSC configuration script to set system discovery disabled.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSystemDiscovery ExampleSettings
        {
            SiteCode = 'Lab'
            Enabled  = $false
        }
    }
}
