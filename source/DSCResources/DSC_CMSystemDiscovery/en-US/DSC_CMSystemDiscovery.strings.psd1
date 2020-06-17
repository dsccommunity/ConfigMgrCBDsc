ConvertFrom-StringData @'
    RetrieveSettingValue  = Getting results for Configuration Manager system discovery method.
    TestSetting           = {0} expected valued: {1} returned {2}.
    NoSchedule            = Expected PollingSchedule to be set to None.
    CurrentSchedule       = Current Schedule is set to none, desired: {0} {1}.
    ExpectedADContainer   = Expected AD Container: {0} to be present.
    ExcludeADContainer    = Expected AD Container: {0} to be absent.
    IntervalCount         = Invalid parameter usage specifying an Interval and didn't specify count.
    SIntervalTest         = NOT MATCH: Schedule interval expected: {0} returned {1}.
    SCountTest            = NOT MATCH: Schedule count expected: {0} returned {1}.
    TestState             = Test-TargetResource compliance check returned: {0}.
    TestDisabled          = Expected System Discovery to be set to disabled returned enabled.
    SetCommonSettings     = Setting {0} to desired setting {1}.
    SIntervalSet          = Setting Schedule interval to {0}.
    SCountSet             = Setting Schedule count to {0}.
    AddADContainer        = Adding AD Container: {0}.
    RemoveADContainer     = Removing AD Container: {0}.
    SetDisabled           = Setting System Discovery to disabled.
    SettingSchedule       = Schedule {0} expected {1}, settings to {1}.
    MissingDeltaDiscovery = When changing delta schedule, delta schedule must be enabled.
'@
