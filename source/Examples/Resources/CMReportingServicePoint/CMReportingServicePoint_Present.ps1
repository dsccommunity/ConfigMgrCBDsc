<#
    .SYNOPSIS
        A DSC configuration script to add a software update point to Configuration Manager with default settings.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMReportingServicePoint ExampleSettings
        {
            SiteCode       = 'Lab'
            SiteServerName = 'CA01.contoso.com'
            UserName       = 'contoso\Admin'
            Ensure         = 'Present'
        }
    }
}
