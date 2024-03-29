ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client policy for user and device affinity settings.
    ClientPolicySetting  = Client Policy Setting {0} does not exist, and will need to be created prior to making client setting changes.
    TestState            = Test-TargetResource compliance check returned: {0}.
    SettingValue         = Setting value: {0} to {1}.
    NonDefaultClient     = AllowUserAffinity can only be set for the default or user client policy settings, ignoring setting.
    NonUserSettings      = LogOnThresholdMins, UsageThresholdDays, and AutoApproveAffinity can only be set for the default or device client policy settings, ignoring settings.
'@
