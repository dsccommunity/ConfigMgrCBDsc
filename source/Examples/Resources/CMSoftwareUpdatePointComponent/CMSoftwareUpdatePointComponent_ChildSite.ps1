<#
    .SYNOPSIS
        A DSC configuration script to modify the Software Update Point Component on a child Primary Site.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSoftwareUpdatePointComponent ExampleSettings
        {
            SiteCode            = 'Lab'
            LanguageUpdateFiles = @('English','French')
            ReportingEvent      = 'DoNotCreateWsusReportingEvents'
        }
    }
}
