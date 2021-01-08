ConvertFrom-StringData @'
RetrieveSettingValue = Getting results for Configuration Manager heartbeat discovery method.
EnableStatus         = Heartbeat discovery is set to {0} return {1}.
IntervalCountTest    = Missing ScheduleInterval or ScheduleCount unable to evaluate schedule.
SIntervalTest        = NOT MATCH: Schedule interval expected: {0} returned {1}.
SCountTest           = NOT MATCH: Schedule count expected: {0} returned {1}.
TestState            = Test-TargetResource compliance check returned: {0}.
SettingEnable        = Heartbeat discovery is currently {0}, setting to {1}.
IntervalCount        = Invalid parameter usage must specify ScheduleInterval and ScheduleCount.
SIntervalSet         = Setting Schedule interval to {0}.
SCountSet            = Setting Schedule count to {0}.
MaxIntervalDays      = The maximum allowed interval is 31 for days. {0} was specified and will result in the interval being set to 31.
MaxIntervalHours     = The maximum allowed interval is 23 for hours. {0} was specified and will result in the interval being set to 23.
'@
