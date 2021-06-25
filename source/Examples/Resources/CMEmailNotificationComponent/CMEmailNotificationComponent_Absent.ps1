<#
    .SYNOPSIS
        A DSC configuration script to disabled email notification component in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMEmailNotificationComponent ExampleSettings
        {
            SiteCode = 'Lab'
            Enabled  = $false
        }
    }
}
