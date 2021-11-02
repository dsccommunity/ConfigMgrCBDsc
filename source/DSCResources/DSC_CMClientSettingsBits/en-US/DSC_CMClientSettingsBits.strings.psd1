ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client policy for bits settings.
    ClientPolicySetting  = Client Policy setting {0} does not exist, and will need to be created prior to making client setting changes.
    TestState            = Test-TargetResource compliance check returned: {0}.
    SettingEnable        = NOT MATCH:  EnableBitsMaxBandwidth is currently set to {0}, expected {1}.
    SettingValue         = Setting value: {0} to {1}.
    WrongClientType      = Client Settings for Bits only applies to Default and Device Client settings.
    MaxOffBits           = MaxTransferRateOffSchedule is specified, this setting can not be set unless EnableDownloadOffSchedule is set to true, ignoring setting.
    DisabledExtraParams  = Setting EnableBitsMaxBandwidth to disabled, ignoring all other parameters specified.
'@
