ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client policy for software metering settings.
    ClientPolicySetting  = Client Policy Setting {0} does not exist, and will need to be created prior to making client setting changes.
    TestState            = Test-TargetResource compliance check returned: {0}.
    TestDisabled         = Enabled currently is enabled and should be disabled.
    SettingValue         = Setting value: {0} to {1}.
    NewSchedule          = Modifying software metering schedule.
    RequiredSchedule     = In order to create a schedule you must specify ScheduleType.
    WrongClientType      = Client Settings for software metering settings only applies to Default and Device client settings.
    EnableFalse          = In order to set a schedule, Enable must be set to true, ignoring settings.
'@
