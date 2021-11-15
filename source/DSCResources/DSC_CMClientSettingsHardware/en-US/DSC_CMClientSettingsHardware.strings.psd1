ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client policy for hardware inventory.
    ClientPolicySetting  = Client Policy Setting {0} does not exist, and will need to be created prior to making client setting changes.
    TestState            = Test-TargetResource compliance check returned: {0}.
    TestDisabled         = Enabled currently is enabled and should be disabled.
    SettingValue         = Setting value: {0} to {1}.
    NewSchedule          = Modifying hardware inventory schedule.
    RequiredSchedule     = In order to create a schedule you must specify ScheduleType.
    DeviceIgnore         = CollectMifFile and MaxThirdPartyMifSize settings are only set in the Default Client Agent Settings, ignoring setting.
    DisableIgnore        = In order to set a schedule, MaxRandomDelayMins CollectMifFile, or MaxThirdPartyMifSize, Enable must be set to true, ignoring settings.
    WrongClientType      = Client Settings for Hardware Inventory only applies to Default and Device client settings.
'@
