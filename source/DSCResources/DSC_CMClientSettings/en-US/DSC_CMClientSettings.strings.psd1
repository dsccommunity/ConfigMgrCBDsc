ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client policy settings.
    TestState            = Test-TargetResource compliance check returned: {0}.
    SettingValue         = Setting value: {0} to {1}.
    TypeMisMatch         = The {0} client setting already exists as a different type.
    AbsentMsg            = NOT MATCH: {0} current state is present and expected absent.
    SetAbsent            = Removing {0} client setting policy.
    DefaultClient        = Not able to modify the default client settings.
    ParamIgnoreScopes    = SecurityScopes was specifed, ignoring SecurityScopesToInclude and SecurityScopesToExclude.
    ScopeInEx            = SecurityScopesToInclude and SecurityScopesToExclude contain to same entry {0}, remove from one of the arrays.
    ScopeMissing         = NOT MATCH:  Client Settings Policy expected the following Scopes: {0}.
    ScopeRemove          = NOT MATCH:  Client Settings Policy expected the following Scopes to be absent: {0}.
    AddScope             = Adding Security Scope {0} to {1}.
    RemoveScope          = Removing Security Scope {0} from {1}.
    ScopeExcludeAll      = Client Settings Policy must have at least 1 Security Scope assigned, SecurityScopesToExclude is currently set to remove all Security Scopes.
    SecurityScopeMissing = The Security Scope specified does not exist: {0}.
'@
