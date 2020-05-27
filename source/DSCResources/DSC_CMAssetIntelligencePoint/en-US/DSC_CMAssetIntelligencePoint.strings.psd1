ConvertFrom-StringData @'
    RetrieveSettingValue = Getting information for the specified Asset Intelligence Synchronization Point.
    APNotInstalled       = Asset Intelligence Synchronization Point is not installed on server: {0}.
    TestSetting          = Setting {0} expected value: {1} returned {2}.
    APAbsent             = {0} Asset Intelligence Synchronization Point expected absent returned present.
    TestState            = Test-TargetResource compliance check returned: {0}.
    ScheduleNoSync       = When specifying a schedule, the EnableSynchronization paramater must be true.
    CertMismatch         = When specifying a certificate, you can't specify RemoveCertificate as true.
    SiteServerRole       = {0} is not currently a site system server adding site system role.
    NullCertCheck        = Expected no certificate file to be configured, but detected that one is currently configured on {0}.
    ScheduleItem         = Schedule item {0} expected {1} returned {2}.
    AddAPRole            = Adding Asset Intelligence Synchronization Point role to {0}.
    SettingValue         = Setting value: {0} to {1}.
    RemoveCert           = Removing configured certificate file for site server {0}.
    RemoveAPRole         = Removing Asset Intelligence Synchronization Point role from {0}.
'@
