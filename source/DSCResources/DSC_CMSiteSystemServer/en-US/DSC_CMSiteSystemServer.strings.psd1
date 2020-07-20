ConvertFrom-StringData @'
    RetrieveSettingValue     = Getting results for Configuration Manager accounts.
    NonSiteServer            = {0} is currently not a Site Server.
    SiteSvrAccountandAccount = You have specified to use SiteSystemAccount and an Account for site server communications, you can only specify 1 or the other.
    EnableProxyNoServer      = When EnableProxy equals $True you must at least specify ProxyServerName.
    ProxySettingNoEnable     = When specifying a proxy setting you must specify EnableProxy = $True.
    ProxyCheck               = NOTMATCH:  {0} Expected {1} returned {2}.
    NoProxyPort              = No ProxyServerPort specified the port will be set to default value of 80 overwritting current value of {0}.
    NoProxyAccessAccount     = No ProxyAccess account specified and is currently set to {0} will reset the proxy access account to use the system account.
    CurrentRoleCount         = Must uninstall all other roles prior to removing the site server component current rolecount: {0}.
    SetSetting               = Setting {0} to expected result {1}.
    BadAccountName           = AccountName {0} does not exist in Configuraion Manager.
    BadProxyAccess           = ProxyAccessAccount {0} does not exist in Configuraion Manager.
    TestState                = Test-TargetResource compliance check returned: {0}.
'@
