ConvertFrom-StringData @'
    AddDP            = Distribution Point Name {0} Distribution Point Group Name: {1}.
    Wait             = Waiting 10 seconds to for the Distribution Point {0} to fully provision.
    StartFormat      = Start: {0} is not formatted correctly, example: 01/01/2021 01:00.
    MissingInterval  = Missing RecurInverval setting for the schedule, setting a schedule will fail.
    MonthlyByWeek    = ScheduleType of MonthWeekly is missing MonthlyWeekOrder or DayofWeek.
    MonthlyByDay     = ScheduleType of MonthlyByDay is missing DayOfMonth.
    Weekly           = ScheduleType of Weekly is missing DayOfWeek.
    ExtraSettings    = Setting {0} does not apply to ScheduleType {1}.
    MaxIntervalMon   = The maximum allowed interval is 12 for months. {0} was specified and will result in the interval being set to 12.
    MaxIntervalWeek  = The maximum allowed interval is 4 for weeks. {0} was specified and will result in the interval being set to 4.
    MaxIntervalDays  = The maximum allowed interval is 31 for days. {0} was specified and will result in the interval being set to 31.
    MaxIntervalHours = The maximum allowed interval is 23 for hours. {0} was specified and will result in the interval being set to 23.
    MaxIntervalMins  = The value specified for minutes must be between 5 and 59. {0} was specified and will result in the interval being set to 59.
    MinIntervalMins  = The value specified for minutes must be between 5 and 59. {0} was specified and will result in the interval being set to 5.
'@
