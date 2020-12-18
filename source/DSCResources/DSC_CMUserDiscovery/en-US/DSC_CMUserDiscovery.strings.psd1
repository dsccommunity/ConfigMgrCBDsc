ConvertFrom-StringData @'
    RetrieveSettingValue  = Getting results for Configuration Manager User Discovery method.
    IntervalCount         = Invalid parameter usage specifying an Interval and didn't specify count.
    UIntervalTest         = NOT MATCH: Schedule interval expected: {0} returned {1}.
    UCountTest            = NOT MATCH: Schedule count expected: {0} returned {1}.
    ADIgnore              = ADContainers was specified, ADContainersInclude and ADContainersExclude will be ignored.
    ExpectedADContainer   = Expected AD Container: {0} to be present.
    ExcludeADContainer    = Expected AD Container: {0} to be absent.
    TestDisabled          = Expected User Discovery to be set to disabled returned enabled.
    TestState             = Test-TargetResource compliance check returned: {0}.
    MissingDeltaDiscovery = When changing delta schedule, delta schedule must be enabled.
    SetCommonSettings     = Setting {0} to desired setting {1}.
    UIntervalSet          = Setting Schedule interval to {0}.
    UCountSet             = Setting Schedule count to {0}.
    AddADContainer        = Adding AD Container: {0}.
    RemoveADContainer     = Removing AD Container: {0}.
    SetDisabled           = Setting User Discovery to disabled.
    ContainersInEx        = ADContainersToExclude and ADContainersToInclude contain to same entry {0}, remove from one of the arrays.
    DeltaNoInterval       = DeltaDiscoveryMins is not specified, specify DeltaDiscoveryMins when enabling Delta Discovery.
    MaxIntervalDays       = The maximum allowed interval is 31 for days. {0} was specified and will result in the interval being set to 31.
    MaxIntervalHours      = The maximum allowed interval is 23 for hours. {0} was specified and will result in the interval being set to 23.
    MaxIntervalMins       = The value specified for minutes must be between 5 and 59. {0} was specified and will result in the interval being set to 59.
    MinIntervalMins       = The value specified for minutes must be between 5 and 59. {0} was specified and will result in the interval being set to 5.
'@
