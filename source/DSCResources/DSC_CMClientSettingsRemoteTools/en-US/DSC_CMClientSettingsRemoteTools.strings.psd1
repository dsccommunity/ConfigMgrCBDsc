ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client policy for remote tools settings.
    ClientPolicySetting  = Client Policy Setting {0} does not exist, and will need to be created prior to making client setting changes.
    TestState            = Test-TargetResource compliance check returned: {0}.
    SettingValue         = Setting value: {0} to {1}.
    WrongClientType      = Client Settings for remote tools only applies to Default and Device Client settings.
    RemoteToolsDisabled  = Remote tools is currenly disabled and must be enabled to set settings for Remote Tools.
    ExtraSettings        = AllowPermittedViewer or RequireAuthentication was specified, these settings can only be set when ManageRemoteDesktopSetting is set to true, ignoring settings.
    SetFirewall          = Setting FirewallExceptionProfile to {0}.
    SetPermittViewer     = Setting PermittedViewer to {0}.
'@
