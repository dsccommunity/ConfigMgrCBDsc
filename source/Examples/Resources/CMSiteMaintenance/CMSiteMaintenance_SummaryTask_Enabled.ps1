<#
    .SYNOPSIS
        A DSC configuration script to enable Summarize Installed Software Data summary task.
#>

Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSiteMaintenance SummaryTask
        {
            SiteCode        = 'Lab'
            TaskName        = 'Summarize Installed Software Data'
            Enabled         = $true
            DaysOfWeek      = @('Friday','WednesDay','Monday')
            BeginTime       = '0000'
            LatestBeginTime = '0400'
        }
    }
}
