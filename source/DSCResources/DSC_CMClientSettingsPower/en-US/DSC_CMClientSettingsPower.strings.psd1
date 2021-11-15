ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client policy for power management settings.
    ClientPolicySetting  = Client Policy Setting {0} does not exist, and will need to be created prior to making client setting changes.
    TestState            = Test-TargetResource compliance check returned: {0}.
    SettingValue         = Setting value: {0} to {1}.
    WrongClientType      = Client Settings for power management only applies to Default and Device Client settings.
    WakeOnLanMsg         = In order to set WakeOnLanPort you must specify NetworkWakeUpOption Enabled and also set EnableWakeUpProxy true.
    WakeOnProxyMsg       = In order to set WakeUpProxyPort, FirewallExceptionForWakeupProxy, or WakeupProxyDirectAccessPrefix, EnableWakeUpProxy must be set to $true.
    FirewallMsg          = When specifying FirewallExceptionForWakeupProxy and specifying None, you can not specify any other firewall exceptions.
    SetFirewall          = Setting FirewallExceptionForWakeupProxy to {0}.
    DirectProxy          = Setting WakeupProxyDirectAccessPrefix to {0}.
'@
