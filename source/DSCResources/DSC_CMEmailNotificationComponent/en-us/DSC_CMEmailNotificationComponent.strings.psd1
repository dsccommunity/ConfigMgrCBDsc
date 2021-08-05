ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager accounts.
    TestState            = Test-TargetResource compliance check returned: {0}.
    Enabled              = NOTMATCH: Value for property Enabled does not match. Current State is False and desired state is True.
    Disabled             = NOTMATCH: Value for property Enabled does not match. Current State is True and desired state is False.
    SettingValue         = Setting value: {0} to {1}.
    MissingParams        = When specifying Enabled equals true you must specify SmtpServerFqdn, Sendfrom, and TypeOfAuthentication.
    UserAuthNotOther     = When specifying UserName you must set TypeOfAuthentication to Other.
    AuthOtherNoUser      = When setting TypeOfAuthentication to Other, you must specify UserName.
    SslTrueNoPort        = Changing UseSSL from false to true and no port was specified, the Port will automatically be changed to 465.
    SslFalseNoPort       = Chaning UseSSL from true to false and no port was specified, the Port will automatically be changed to 25
    SslBadPort           = When using SSL, you must specify a port other than the default non-SSL port 25.
    NonSslBadPort        = When not using SSL, you must specify a port other than the default SSL port 465.
    AbsentUsername       = UserAccount specifed {0} does not exist in Configuration Manager and will need to be created prior to adding as the connection account.
    SmtpError            = SmtpServerFqdn {0} should use . vs @ format, example test.contoso.com.
    SendFromError        = SendFrom {0} should use @ format, example sendfrom@contoso.com.
'@
