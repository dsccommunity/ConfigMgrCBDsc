<#
    .SYNOPSIS
        A DSC configuration script to enable Delete Aged Client Operations maintenance task.
#>

Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSiteMaintenance MaintenanceTask
        {
            SiteCode            = 'Lab'
            TaskName            = 'Delete Aged Client Operations'
            Enabled             = $true
            DaysOfWeek          = @('Saturday','Friday','Thursday','Wednesday','Tuesday','Monday','Sunday')
            BeginTime           = '0100'
            LatestBeginTime     = '0500'
            DeleteOlderThanDays = 30
        }
    }
}
