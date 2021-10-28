ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client policy for software inventory settings.
    ClientPolicySetting  = Client Policy Setting {0} does not exist, and will need to be created prior to making client setting changes.
    TestState            = Test-TargetResource compliance check returned: {0}.
    TestDisabled         = Enabled currently is enabled and should be disabled.
    SettingValue         = Setting value: {0} to {1}.
    NewSchedule          = Modifying software inventory schedule.
    RequiredSchedule     = In order to create a schedule you must specify ScheduleType.
    WrongClientType      = Client Settings for software inventory settings only applies to Default and Device client settings.
    EnableFalse          = In order to set a schedule or ReportOptions, Enable must be set to true, ignoring settings.
    DisableIgnore        = Currently setting EnableCustomize to false all other parameters specified will be ignored.
'@
