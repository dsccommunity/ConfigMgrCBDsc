ConvertFrom-StringData @'
    RetrieveSettingValue  = Getting results for Configuration Manager system discovery method.
    IntervalCount         = Invalid parameter usage specifying an Interval and didn't specify count.
    SIntervalTest         = NOT MATCH: Schedule interval expected: {0} returned {1}.
    SCountTest            = NOT MATCH: Schedule count expected: {0} returned {1}.
    TestState             = Test-TargetResource compliance check returned: {0}.
    TestDisabled          = Expected System Discovery to be set to disabled returned enabled.
    SetCommonSettings     = Setting {0} to desired setting {1}.
    SIntervalSet          = Setting Schedule interval to {0}.
    SCountSet             = Setting Schedule count to {0}.
    SetDisabled           = Setting System Discovery to disabled.
    MissingDeltaDiscovery = When changing delta schedule, delta schedule must be enabled.
    ADIgnore              = ADContainers was specified, ADContainersInclude and ADContainersExclude will be ignored.
    ContainersInEx        = ADContainersToExclude and ADContainersToInclude contain to same entry {0}, remove from one of the arrays.
    ADContainerMissing    = AD Container {0} is missing from configuration manager, adding.
    ADContainerExtra      = AD Container {0} is expected to absent, removing AD Container.
    DeltaNoInterval       = DeltaDiscoveryMins is not specified, specify DeltaDiscoveryMins when enabling Delta Discovery.
    MaxIntervalDays       = The maximum allowed interval is 31 for days. {0} was specified and will result in the interval being set to 31.
    MaxIntervalHours      = The maximum allowed interval is 23 for hours. {0} was specified and will result in the interval being set to 23.
    MaxIntervalMins       = The value specified for minutes must be between 5 and 59. {0} was specified and will result in the interval being set to 59.
    MinIntervalMins       = The value specified for minutes must be between 5 and 59. {0} was specified and will result in the interval being set to 5.
'@
