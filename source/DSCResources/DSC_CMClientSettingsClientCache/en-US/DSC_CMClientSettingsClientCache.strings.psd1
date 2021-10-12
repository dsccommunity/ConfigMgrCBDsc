ConvertFrom-StringData @'
    RetrieveSettingValue  = Getting results for Configuration Manager client policy for client cache settings.
    ClientPolicySetting   = Client Policy setting {0} does not exist, and will need to be created prior to making client setting changes.
    TestState             = Test-TargetResource compliance check returned: {0}.
    SettingValue          = Setting value: {0} to {1}.
    DisabledBranchwithMax = When trying to set EnableBranchCache or MaxBranchCacheSizePercent, ConfigurureBranchCache must be set to true.
    ConfigCacheFalseSize  = When trying to set MaxCacheSize or MaxCacheSizePercent, ConfigureCacheSize must be set to true.
    DisableSuperBroad     = When trying to set BroadcastPort or DownloadPort, EnableSuperPeer must be set to true.
    BranchMaxCache        = When setting MaxCacheSizePercent, ConfigureBranchCache must be set to true.
    WrongClientType       = Client Settings for Client Cache only applies to Default and Device Client settings.
'@
