ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager administrative user.
    TestState            = Test-TargetResource compliance check returned: {0}.
    AddAdmin             = Expected {0} to be present but is absent.
    RolesMissing         = The following roles are missing {0}.
    RolesRemove          = The following roles need to be removed {0}.
    ScopesMissing        = The following scopes are missing {0}.
    ScopesRemove         = The following scopes need to be removed {0}.
    CollectionsMissing   = The following collections are missing {0}.
    CollectionsRemove    = The following collections need to be removed {0}.
    RemoveAdmin          = Expected {0} to be absent but is present.
    RolesIgnore          = Roles is set, ignoring RolesToInclude and RolesToExclude settings.
    ScopesIgnore         = Scopes is set, ignoring ScopesToInclude and ScopesToExclude settings.
    CollectionsIgnore    = Collections is set, ignoring CollectionsToInclude and CollectionsToExclude settings.
    ValidRole            = When administrative user does not exist, at least 1 valid role must be specified.
    ErrorMsg             = {0} was not added as is not a valid {1}.
    AllParam             = Unable to add the All scopes setting via Desired State Configuration, All can be used for new account only.
    RemoveAll            = Unable to remove the All scope via Desired State Configuration.
    ModifyAll            = Unable to modify scope with Desired State Configuration as it is currently set to All.
'@
