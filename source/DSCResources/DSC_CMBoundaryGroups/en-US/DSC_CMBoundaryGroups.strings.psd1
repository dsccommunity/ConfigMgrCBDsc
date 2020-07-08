ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager Boundary Group.
    BoundaryGroupMissing = {0} Boundary Group is missing.
    MissingBoundary      = {0} Boundary Group is missing boundary: {1} {2}.
    ExtraBoundary        = {0} Boundary Group contains unwanted boundary: {1} {2}.
    BoundaryGroupRemove  = {0} needs to be removed.
    TestState            = Test-TargetResource compliance check returned: {0}.
    CreateBoundaryGroup  = Creating {0} Boundary Group.
    AddingBoundary       = {0} Boundary Group is missing boundary {1} {2}, adding boundary.
    ExcludingBoundary    = {0} Boundary Group contains unwanted boundary: {1} {2}, removing.
    BoundaryAbsent       = Boundary {0} {1} doesn't exist in Configuration Manager.
    BoundaryGroupDelete  = {0} Boundary Group exists, deleting.
    ParamIgnore          = SiteSystems is specified, ignoring SiteSystemsToInclude and SiteSystemsToExclude.
    SiteInEx             = SiteSystemsToInclude and SiteSystemsToExclude contain the same member {0}.
    SystemMissing        = NOTMATCH:  Boundary Group is missing the following Site System: {0}.
    SystemRemove         = NOTMATCH:  Boundary Group expected the following Site System to be absent: {0}.
    SiteSystemMissing    = The Site Systems specified do not exist: {0}.
'@
