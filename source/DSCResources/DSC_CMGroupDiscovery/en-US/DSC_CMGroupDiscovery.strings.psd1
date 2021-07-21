ConvertFrom-StringData @'
    RetrieveSettingValue  = Getting results for Configuration Manager group discovery method.
    TestState             = Test-TargetResource compliance check returned: {0}.
    TestDisabled          = Expected Group Discovery to be set to disabled returned enabled.
    SetCommonSettings     = Setting {0} to desired setting {1}.
    SetDisabled           = Setting Group Discovery to disabled.
    MissingDeltaDiscovery = When changing delta schedule, delta schedule must be enabled.
    GdsIgnore             = GroupDiscoveryScope was specified, GroupDiscoveryScopeInclude and GroupDiscoveryScopeToExclude will be ignored.
    GdsInEx               = GroupDiscoveryScopeToExclude and GroupDiscoveryScopeToInclude contain to same entry {0}, remove from one of the arrays.
    GdsMissing            = Group Discovery Scope Name: {0} LDAPPath: {1} Recurse {2} is missing.
    GdsUpdate             = Group Discovery Scope Name: {0} expected LdapLocation: {1} Recurse {2}, returned LdapLocation: {3} Recurse {4}.
    GdsExtra              = Group Discovery Scope Name {0} is expected to be absent.
    DeltaNoInterval       = DeltaDiscoveryMins is not specified, specify DeltaDiscoveryMins when enabling Delta Discovery.
    NewSchedule           = Modifying group discovery schedule.
'@
