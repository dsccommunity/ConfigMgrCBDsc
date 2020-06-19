<#
    .SYNOPSIS
        A DSC configuration script to disable Backup SMS Site Server task.
#>

Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSiteMaintenance BackupTaskDisabled
        {
            SiteCode = 'Lab'
            TaskName = 'Backup SMS Site Server'
            Enabled  = $false
        }
    }
}
