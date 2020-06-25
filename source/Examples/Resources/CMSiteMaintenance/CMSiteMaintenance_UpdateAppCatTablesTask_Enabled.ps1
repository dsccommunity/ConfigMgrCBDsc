<#
    .SYNOPSIS
        A DSC configuration script to enable and set Update Application Catalog Tables task.
#>

Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSiteMaintenance UpdateAppCatTable
        {
            SiteCode    = 'Lab'
            TaskName    = 'Update Application Catalog Tables'
            Enabled     = $true
            RunInterval = 1380
        }
    }
}
