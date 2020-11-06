ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager client push settings.
    AccountsIgnore       = Accounts is specified, ignoring settings for AccountsToInclude and AccountsToExclude.
    AccountsInEx         = AccountsToExclude and AccountsToInclude contain the same setting {0}.
    DisabledSettings     = Client push is getting set to disabled or is disabled, unable to set the following settings: EnableSystemTypeConfigurationManager, EnableSystemTypeServer, EnableSystemTypeWorkstation.
    AccountsMissing      = NOTMATCH: Client push settings is missing the following accounts: {0}.
    AccountsExtra        = NOTMATCH: Client push settings expected the following accounts to be absent: {0}.
    TestState            = Test-TargetResource compliance check returned: {0}.
    MissingMP            = Unable to enable client push settings, no Management Point could be found on {0} site.
    ModifySetting        = {0} expected value: {1}, changing value.
    AddingAccount        = Account is missing adding {0}.
    CMAccountMissing     = Account {0} is missing from configuration manager, unable to add account.
    CMAccountExtra       = Account {0} is expected to absent, removing account.
'@
