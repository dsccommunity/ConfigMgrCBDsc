<#
    .SYNOPSIS
        A DSC configuration script to remove a software update point from Configuration Manager.
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
            Ensure         = 'Absent'
        }
    }
}
