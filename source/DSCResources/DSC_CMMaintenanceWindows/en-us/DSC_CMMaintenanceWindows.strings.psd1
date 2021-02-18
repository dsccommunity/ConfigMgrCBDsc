ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager maintenance windows.
    MixedDuration        = Currently, you can only specify Hour or Minute you can not specify both settings.
    MissingCollection    = Collection {0} does not exist and will not be able to create Maintenance Windows.
    MissingWindowParam   = Maintenance Window {0} does not exist, need to specify a ScheduleType and a duration to create a new maintence window.
    ChangingApplyTo      = ServiceWindowsType returned: {0} expected {1}, changing to desired state.
    ChangingIsEnabled    = IsEnabled returned: {0} expected {1}, changing to desired state.
    NewSchedule          = Creating a new schedule.
    NewWindow            = Creating a new maintenance window.
    ModifyWindow         = Modify the maintenance window.
    RemoveMW             = Removing maintenance window {0} from Configuration Manager.
    MissingWindow        = Maintenance Window {0} does not exist.
    TestState            = Test-TargetResource compliance check returned: {0}.
    Absent               = NOTMATCH: Value (type 'System.Boolean') for property Ensure does not match. Current state is 'Present' and desired state is 'Absent'.
'@
