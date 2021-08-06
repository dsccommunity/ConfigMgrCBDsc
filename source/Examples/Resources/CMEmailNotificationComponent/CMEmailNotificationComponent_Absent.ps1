<#
    .SYNOPSIS
        A DSC configuration script to disable email notification component in Configuration Manager.
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
