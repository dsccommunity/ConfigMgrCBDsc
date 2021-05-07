<#
    .SYNOPSIS
        A DSC configuration script to create maintenance windows for collections.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMMaintenanceWindows ExampleMonthlyByWeek
        {
            SiteCode           = 'Lab'
            CollectionName     = 'Test'
            Name               = 'MonthlyByWeek'
            ServiceWindowsType = 'Any'
            IsEnabled          = $true
            HourDuration       = 1
            Start              = '2/2/2021 00:00'
            ScheduleType       = 'MonthlyByWeek'
            MonthlyWeekOrder   = 'Second'
            DayOfWeek          = 'Sunday'
            RecurInterval      = 1
        }

        CMMaintenanceWindows ExampleMonthlyByDay
        {
            SiteCode           = 'Lab'
            CollectionName     = 'Test'
            Name               = 'MonthlyByDay'
            ServiceWindowsType = 'TaskSequencesOnly'
            IsEnabled          = $true
            MinuteDuration     = 30
            Start              = '2/2/2021 00:00'
            ScheduleType       = 'MonthlyByDay'
            DayOfMonth         = 10
            RecurInterval      = 1
        }

        CMMaintenanceWindows ExampleWeekly
        {
            SiteCode           = 'Lab'
            CollectionName     = 'Test'
            Name               = 'Weekly'
            ServiceWindowsType = 'SoftwareUpdatesOnly'
            HourDuration       = 1
            ScheduleType       = 'Weekly'
            DayOfWeek          = 'Friday'
            RecurInterval      = 2
        }

        CMMaintenanceWindows ExampleDays
        {
            SiteCode           = 'Lab'
            CollectionName     = 'Test'
            Name               = 'Days'
            ServiceWindowsType = 'TaskSequencesOnly'
            HourDuration       = 1
            ScheduleType       = 'Days'
            RecurInterval      = 5
        }
    }
}
