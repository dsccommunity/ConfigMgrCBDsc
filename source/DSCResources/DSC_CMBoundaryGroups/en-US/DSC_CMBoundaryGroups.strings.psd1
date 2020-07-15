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
    ParamIgnoreScopes    = SecurityScopes was specifed, ignoring SecurityScopesToInclude and SecurityScopesToExclude.
    SiteInEx             = SiteSystemsToInclude and SiteSystemsToExclude contain the same member {0}.
    ScopeInEx            = SecurityScopesToInclude and SecurityScopesToExclude contain to same entry {0}, remove from one of the arrays.
    SystemMissing        = NOTMATCH:  Boundary Group is missing the following Site System: {0}.
    SystemRemove         = NOTMATCH:  Boundary Group expected the following Site System to be absent: {0}.
    SiteSystemMissing    = The Site Systems specified does not exist: {0}.
    SecurityScopeMissing = The Security Scope specified does not exist: {0}.
    ScopeMissing         = NOTMatch:  Boundary Group expected the following Scopes: {0}.
    ScopeRemove          = NOTMATCH:  Boundary Group expected the following Scopes to be absent: {0}.
    AddScope             = Adding Security Scope {0} to {1}.
    RemoveScope          = Removing Security Scope {0} from {1}.
'@
