<#
    .SYNOPSIS
        A DSC configuration script to remove a fallback status point from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMFallbackStatusPoint ExampleSettings
        {
            SiteCode       = 'Lab'
            SiteServerName = 'FSP01.contoso.com'
            Ensure         = 'Absent'
        }
    }
}
