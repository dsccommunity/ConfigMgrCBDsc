<#
    .SYNOPSIS
        A DSC configuration script to enable Backup SMS Site Server backup task.
#>

Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSiteMaintenance BackupTask
        {
            SiteCode        = 'Lab'
            TaskName        = 'Backup SMS Site Server'
            Enabled         = $true
            DaysOfWeek      = 'Sunday'
            BeginTime       = '0100'
            LatestBeginTime = '0500'
            BackupLocation  = 'C:\Temp'
        }
    }
}
