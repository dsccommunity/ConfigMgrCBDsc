ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager Distribution Point Group.
    GroupMissing         = NOTMATCH:  {0} Distribution Point Group is absent expected present.
    DistroMissing        = NOTMATCH:  Distribution Point Group is missing the following Distribution Point: {0}.
    DistroRemove         = NOTMATCH:  Distribution Point Group expected the following Distribution Point to be absent: {0}.
    ParamIgnore          = DistributionPoints was specifed, ignoring DistributionPointsToInclude and DistributionPointsToExclude.
    DistroGroupPresent   = NOTMATCH:  Distribution Point Group is present expected absent.
    TestState            = Test-TargetResource compliance check returned: {0}.
    AddGroup             = Adding {0} Distribution Point Group.
    AddDistro            = Adding {0} Distribution Point to Distribution Point Group {1}.
    RemoveDistro         = Removing {0} Distribution Point from Distribution Point Group {1}.
    RemoveGroup          = Removing {0} Distribution Point Group.
    ErrorGroup           = Distribution Point: {0} does not exist.
'@
