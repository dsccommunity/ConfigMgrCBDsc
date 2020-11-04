ConvertFrom-StringData @'
    RetrieveSettingValue  = Getting results for Configuration Manager accounts.
    ComputerAccessAccount = Specifying both ComputerAccount and AccessAccount, these settings can not be specified together.
    ParamIgnore           = SiteSystems is specified, ignoring SiteSystemsToInclude and SiteSystemsToExclude.
    AccessAccountsInEx    = AccessAccountsToInclude and AccessAccountsToExclude contain the same member {0}.
    AllAccountsRemoved    = All AccessAccounts are being removed causing the ClientComputerAccount to be set to true.
    TestState             = Test-TargetResource compliance check returned: {0}.
    ModifySetting         = {0} expected value: {1}, changing value.
    AddingAccount         = Account is missing adding {0}.
    CMAccountMissing      = Account {0} is missing from configuration manager unable to add account.
    CMAccountExtra        = Account {0} is expected to absent removing account.
'@
