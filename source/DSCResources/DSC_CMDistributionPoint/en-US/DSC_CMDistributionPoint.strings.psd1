ConvertFrom-StringData @'
    RetrieveSettingValue  = Getting results for Configuration Manager Distribution Points.
    DPNotInstalled        = Distribution Point role is not installed on server: {0}.
    SettingsNotEval       = The Distribution Point already exists the following settings will not be evaluated: MinimumFreeSpaceMB, Primary Secondary ContentLibraryLocation and PackageShareLocations, and CertificateExpirationTimeUTC.
    BoundaryGroupMissing  = NOMATCH: Currently missing boundary group: {0}.
    BoundaryGroupExtra    = NOMATCH: Unwanted boundary group is present: {0}.
    DPAbsent              = NOMATCH: {0} Distribution Point expected absent returned present.
    TestState             = Test-TargetResource compliance check returned: {0}.
    SiteServerRole        = {0} is not currently a site system server adding site system role.
    AddDPRole             = Adding distribution point role to {0}.
    SettingValue          = Setting value: {0} to {1}.
    BoundaryGroupAdd      = Adding boundary group {0}.
    BoundaryGroupRemove   = Removing boundary group {0}.
    RemoveDPRole          = Removing distribution point role from {0}.
    InvalidPriOrSecLetter = Primary and Secondary Library or Package locations must be a character A - Z.
    SecAndNoPrimary       = Must specify the assoicated primary location when a secondary location is specified.
'@
