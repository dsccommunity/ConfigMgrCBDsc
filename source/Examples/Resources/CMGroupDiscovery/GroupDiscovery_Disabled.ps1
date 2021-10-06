<#
    .SYNOPSIS
        A DSC configuration script to set group discovery disabled.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMGroupDiscovery ExampleSettings
        {
            SiteCode = 'Lab'
            Enabled  = $false
        }
    }
}
