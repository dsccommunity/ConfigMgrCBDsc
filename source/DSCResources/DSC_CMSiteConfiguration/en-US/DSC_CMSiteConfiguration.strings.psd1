ConvertFrom-StringData @'
    RetrieveSettingValue = Getting information for the specified Fallback Status Point.
    IgnoreSMSCert        = When specifying HttpsOnly, UseSMSGeneratedCert can not be specified, ignoring setting.
    IgnorePrimarySetting = Current site type is CAS, {0} does not apply to a CAS server.
    IgnoreAlertsSettings = EnableLowFreeSpaceAlert is disabled and FreeSpaceThreshold Warning or Critical GB was specified, ignoring settings.
    CollectionError      = ThresholdOfSelectCollectionByDefault of: {0} must be less than ThresholdOfSelectCollectionMax: {1}.
    AlertMissing         = When setting EnableLowFreeSpaceAlert to true, FreeSpaceThreshold warning and critical must be specified.
    AlertErrorMsg        = FreeSpaceThresholdCritical is greater than or equal to FreeSpaceThresholdWarning.  Warning should be greater than Critical.
    TestState            = Test-TargetResource compliance check returned: {0}.
    SettingValue         = Setting value: {0} to {1}.
    WakeFalse            = When EnableWakeOnLan is disabled the {0} parameter will be ignored.
    IgnoreCertValue      = When ClientCertificateSelectionCriteriaType is set to ClientAuthentication, the ClientCertificateSelectionCriteriaValue is ignored.
    MissingCertValue     = When ClientCertificateSelectionCriteriaType is specified as {0}, ClientCertificateSelectionCriteriaValue is required.
    MissingCertType      = When ClientCertificateSelectionCriteriaValue is specified, ClientCertificateSelectionCriteriaType is required.
    NullCertStore        = ClientCertificateCustomStoreName cannot be specified as empty. The default value of Personal will be used.
'@
