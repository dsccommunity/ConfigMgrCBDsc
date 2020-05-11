ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager collection.
    MPNotInstalled       = Management Point is not installed on server: {0}.
    TestSetting          = {0} expected value: {1} returned {2}.
    MPAbsent             = {0} management point expected absent returned Present.
    TestState            = Test-TargetResource compliance check returned: {0}.
    SiteServerRole       = {0} is not currently a site system server adding site system role.
    AddMPRole            = Adding management point role to {0}.
    SettingValue         = Setting value: {0} to {1}.
    RemoveMPRole         = Removing management point role from {0}.
    EnableGateway        = When CloudGateway is enabled, ClientConnectionType must not equal Intranet.
    GatewaySsl           = When CloudGateway is enabled SSL must also be enabled.
    GatewayIntranet      = Can not specify Client connection type of Internet if Cloud Gateway is not enabled.
    SqlDatabase          = SQLServerFqdn and database name must be specified together.
    SqlSiteDatabase      = When specifying using a SQL database you must set UseSiteDatabase to $false.
    UsernameComputer     = You can not specify a Username and UseComputerAccount to $true.
'@
