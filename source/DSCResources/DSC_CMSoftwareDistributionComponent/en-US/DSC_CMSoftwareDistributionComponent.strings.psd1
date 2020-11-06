ConvertFrom-StringData @'
    RetrieveSettingValue  = Getting results for Configuration Manager accounts.
    ComputerAccessAccount = Specifying both ComputerAccount and AccessAccount, these settings can not be specified together.
    AccountsFalse         = Setting ClientComputerAccount to false and no access account is currently set or specified.
    ParamIgnore           = AccessAccounts is specified, ignoring AccessAccountsToInclude and AccessAccountsToExclude for testing.
    AccessAccountsInEx    = AccessAccountsToInclude and AccessAccountsToExclude contain the same member {0}.
    AllAccountsRemoved    = All AccessAccounts would be removed causing the ClientComputerAccount to be set to true causing invalid configuration.
    TestState             = Test-TargetResource compliance check returned: {0}.
    ParamsError           = AccessAccounts and AccessAccountsToInclude or AccessAccountToExclude is specified remove AccessAccounts or the include or exclude setting.
    ModifySetting         = {0} expected value: {1}, changing value.
    AddingAccount         = AccessAccount is missing adding {0}.
    CMAccountMissing      = Account {0} is missing from configuration manager unable to add account.
    CMAccountExtra        = AccessAccount {0} is expected to absent removing account.
'@
