ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager Distribution Point Group.
    DistroMissing        = NOTMATCH:  Distribution Point Group is missing {0}.
    DistroRemove         = NOTMATCH:  Distribution Point Group expected {0} to be absent.
    ParamIgnore          = DistributionPoints was specifed, ignoring DistributionPointsToInclude and DistributionPointsToExclude.
    DistroGroupPresent   = Distribution Group is present expected absent.
    TestState            = Test-TargetResource compliance check returned: {0}.
    AddGroup             = Adding {0} Distribution Point Group.
    AddDistro            = Adding {0} Distribution Point to Distribution Point Group {1}.
    RemoveDistro         = Removing {0} Distribution Point from Distribution Point Group {1}.
    RemoveGroup          = Removing {0} Distribution Point Group.
    ErrorGroup           = Distribution Point: {0} do not exist.
'@
