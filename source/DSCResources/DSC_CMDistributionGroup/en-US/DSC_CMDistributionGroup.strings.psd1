ConvertFrom-StringData @'
    RetrieveSettingValue   = Getting results for Configuration Manager Distribution Group.
    GroupMissing           = NOTMATCH:  {0} Distribution Group is absent expected present.
    DistroMissing          = NOTMATCH:  Distribution Group is missing the following Distribution Point: {0}.
    DistroRemove           = NOTMATCH:  Distribution Group expected the following Distribution Point to be absent: {0}.
    ScopeMissing           = NOTMatch:  Distribution Group expected the following Scopes: {0}.
    ScopeRemove            = NOTMATCH:  Distribution Group expected the following Scopes to be absent: {0}.
    CollectionMissing      = NOTMatch:  Distribution Group expected the following Collections: {0}.
    CollectionRemove       = NOTMATCH:  Distribution Group expected the following Collections to be absent: {0}.
    ParamIgnore            = DistributionPoints was specifed, ignoring DistributionPointsToInclude and DistributionPointsToExclude.
    ParamIgnoreScopes      = SecurityScopes was specifed, ignoring SecurityScopesToInclude and SecurityScopesToExclude.
    ParamIgnoreCollections = Collections was specifed, ignoring CollectionsToInclude and CollectionsToExclude.
    DistroGroupPresent     = NOTMATCH:  Distribution Group is present expected absent.
    TestState              = Test-TargetResource compliance check returned: {0}.
    AddGroup               = Adding {0} Distribution Group.
    AddDistro              = Adding {0} Distribution Point to Distribution Group {1}.
    RemoveDistro           = Removing {0} Distribution Point from Distribution Group {1}.
    AddScope               = Adding {0} Security Scope to Distribution Group {1}.
    RemoveScope            = Removing {0} Security Scope from Distribution Group {1}.
    AddCollection          = Adding {0} Collection to Distribution Group {1}.
    RemoveCollection       = Removing {0} Collection from Distribution Group {1}.
    RemoveGroup            = Removing {0} Distribution Group.
    ErrorGroup             = {0}: {1} does not exist.
    DistroInEx             = DistributionPointsToInclude and DistributionPointsToExclude contain to same entry {0}, remove from one of the arrays.
    ScopeInEx              = SecurityScopesToInclude and SecurityScopesToExclude contain to same entry {0}, remove from one of the arrays.
    CollectionInEx         = CollectionsToInclude and CollectionsToExclude contain to same entry {0}, remove from one of the arrays.
'@
