<#
    .SYNOPSIS
        A DSC configuration script to add a fallback status point to Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMFallbackStatusPoint ExampleSettings
        {
            SiteCode          = 'Lab'
            SiteServerName    = 'FSP01.contoso.com'
            Ensure            = 'Present'
            StateMessageCount = '10000'
            ThrottleSec       = '3600'
        }
    }
}
