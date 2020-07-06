ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager Distribution Group.
    GroupMissing         = NOTMATCH:  {0} Distribution Group is absent expected present.
    DistroMissing        = NOTMATCH:  Distribution Group is missing the following Distribution Point: {0}.
    DistroRemove         = NOTMATCH:  Distribution Group expected the following Distribution Point to be absent: {0}.
    ParamIgnore          = DistributionPoints was specifed, ignoring DistributionPointsToInclude and DistributionPointsToExclude.
    DistroGroupPresent   = NOTMATCH:  Distribution Group is present expected absent.
    TestState            = Test-TargetResource compliance check returned: {0}.
    AddGroup             = Adding {0} Distribution Group.
    AddDistro            = Adding {0} Distribution Point to Distribution Group {1}.
    RemoveDistro         = Removing {0} Distribution Point from Distribution Group {1}.
    RemoveGroup          = Removing {0} Distribution Group.
    ErrorGroup           = Distribution Point: {0} does not exist.
    DistroInEx           = DistributionPointsToInclude and DistributionPointsToExclude contain to same entry {0}, remove from one of the arrays.
'@
