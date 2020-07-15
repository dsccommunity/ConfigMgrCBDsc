ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager Security Scopes.
    ScopeAbsent          = NOTMATCH: Security Scope: {0} expected present returned absent.
    DescriptionTest      = NOTMATCH: Description expected {0} returned {1}
    TestState            = Test-TargetResource compliance check returned: {0}.
    InUseStatement       = The Security Scope is in use and will not be deleted.
    ScopeStatusRemove    = NOTMATCH: SecurityScope: {0} expected absent returned present.
    NewScope             = Creating Security Scope {0}.
    SetDesc              = Setting Description: {0}.
    RemoveScope          = Removing {0} Security Scope from Configuration Manager.
'@
