ConvertFrom-StringData @'
    RetrieveSettingValue = Getting information for the specified Software Update Point.
    SUPNotInstalled      = Software Update Point is not installed on server: {0}.
    SUPAbsent            = {0} Software Update Point expected absent returned Present.
    TestState            = Test-TargetResource compliance check returned: {0}.
    SiteServerRole       = {0} is not currently a site system server adding site system role.
    AddSUPRole           = Adding Software Update Point role to {0}.
    SettingValue         = Setting value: {0} to {1}.
    RemoveSUPRole        = Removing Software Update Point role from {0}.
    EnableGateway        = When CloudGateway is enabled, ClientConnectionType must not equal Intranet.
    GatewaySsl           = When CloudGateway is enabled SSL must also be enabled.
    UsernameComputer     = You can not specify a WsusAccessAccount and set AnonymousWsusAccess to $true.
    NoProxy              = No proxy is configured on the server. Please configure a proxy before specifying UseProxy or UseProxyForAutoDeploymentRule as true.
'@
