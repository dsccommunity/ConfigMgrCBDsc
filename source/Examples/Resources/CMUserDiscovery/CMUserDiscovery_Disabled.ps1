<#
    .SYNOPSIS
        A DSC configuration script to set user discovery disabled.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMUserDiscovery ExampleSettings
        {
            SiteCode = 'Lab'
            Enabled  = $false
        }
    }
}
