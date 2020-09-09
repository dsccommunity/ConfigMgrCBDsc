ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager Distribution Point Group members.
    DistroPointInstall   = The distribution point role on {0} is not installed, run DSC_CMDistibutionPoint to install the role.
    GroupMissing         = NOTMATCH: {0} is missing Distribution Point Group {1}.
    GroupExclude         = NOTMATCH: {0} was expecting Distribution Point Group to be absent {1}.
    TestState            = Test-TargetResource compliance check returned: {0}.
    AddDistroGroup       = Adding {0} group to Distribution Point {1}.
    RemoveDistroGroup    = Removing {0} group from Distribution Point {1}.
    ParamIgnore          = DistributionGroups was specifed, ignoring DistributionGroupsToInclude and DistributionGroupsToExclude.
    ErrorGroup           = Distribution Groups: {0} does not exist.
    ErrorBoth            = Distribution Group: {0} is a member of the include group and exclude group.
    GroupAddError        = Unable to add the Distribution Point: {0} to Group: {1}.
'@
