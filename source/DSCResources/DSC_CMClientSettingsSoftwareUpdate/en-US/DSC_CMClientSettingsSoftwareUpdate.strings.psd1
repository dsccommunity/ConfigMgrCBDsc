ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client policy for software update.
    ClientPolicySetting  = Client Policy Setting {0} does not exist, and will need to be created prior to making client setting changes.
    TestState            = Test-TargetResource compliance check returned: {0}.
    TestDisabled         = Enabled currently is enabled and should be disabled.
    SettingValue         = Setting value: {0} to {1}.
    NewSchedule          = Modifying software update schedule.
    RequiredSchedule     = In order to create a schedule you must specify ScheduleType.
    WrongClientType      = Client Settings for software update only applies to Default and Device client settings.
    DeltaPortIgnore      = DeltaDownloadPort is specified, to set this setting EnableDeltaDownload must be set to true, ignoring setting.
    MissingEnforce       = When settings EnforceMandatory to true you must specify both TimeUnit and BatchingTimeOut.
    MaxBatchHours        = TimeUnits is set to hours, BatchingTimeOut max value is 23, setting BatchingTimeOut to 23.
    TimeBatchIgnore      = TimeUnit or BatchingTimeOut are specified, to set these settings EnforceMandatory must be set to true, ignoring settings.
'@
