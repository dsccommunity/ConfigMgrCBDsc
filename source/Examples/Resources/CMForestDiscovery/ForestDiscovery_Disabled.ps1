<#
    .SYNOPSIS
        A DSC configuration script to disable AD Forest Discovery for Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMForestDiscovery ExampleSettings
        {
            SiteCode = 'Lab'
            Enabled  = $false
        }
    }
}
