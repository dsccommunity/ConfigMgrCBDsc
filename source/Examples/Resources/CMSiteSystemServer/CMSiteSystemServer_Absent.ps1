<#
    .SYNOPSIS
        A DSC configuration script to remove a site system server from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSiteSystemServer ExampleServer
        {
            SiteCode         = 'Lab'
            SiteSystemServer = 'SS01.contoso.com'
            Ensure           = 'Absent'
        }
    }
}
