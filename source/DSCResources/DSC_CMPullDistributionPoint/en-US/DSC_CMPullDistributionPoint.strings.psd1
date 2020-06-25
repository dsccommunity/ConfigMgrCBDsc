ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager pull distribution point.
    DistroPointInstall   = The Distribution Point role on {0} is not installed, run DSC_CMDistibutionPoint to install the role.
    TestEnablePull       = EnablePullDP is currently set to {0} expected {1}.
    SourceDPMatch        = MATCH:  The settings is present {0} and {1}.
    SourceDPMissing      = NOTMATCH:  The setting is missing {0} and {1}.
    SourceDPExtra        = NOTMATCH:  The setting is extra {0} and {1}.
    InvalidConfig        = EnablePullDP is being set to false or is currently false and can not specify a SourceDistributionPoint, set to enable of remove SourceDistributionPoint from the configuration.
    PullDPEnabledThrow   = When enabling a Pull DP SourceDistributionPoint must be specified.
    EnablePullDP         = Setting EnablePullDP to true.
    SourceDPMismatch     = SourceDistributionPoint do not match setting to desired state.
    SourceDPSiteServer   = You can not specify the Pull DP {0} as a SourceDistributionPoint.
'@
