ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager File Replication settings.
    TestState            = Test-TargetResource compliance check returned: {0}.
    SetCommonSettings    = Setting {0} to desired setting {1}.
    FileRepAbsent        = The file replication route does not exist, returning false.
    FileRepCreate        = Creating file replication between {0} and {1}.
    LimitSchedMatch      = MATCH: Value for property 'RateLimitingSchedule' does match current state: LimitedBeginHour: {0} LimitedEndHour: {1} LimitAvailableBandwidthPercent: {2}.
    LimitSchedNonMatch   = NOTMATCH: Value for property 'RateLimitingSchedule' does not match current state, desired settings is LimitedBeginHour: {0} LimitedEndHour: {1} LimitAvailableBandwidthPercent: {2}.
    LimitedSchedSet      = Setting RateLimitingSchedule to LimitedBeginHour: {0} LimitedEndHour: {1} LimitAvailableBandwidthPercent: {2}.
    NetworkSchedMatch    = MATCH: Value for property 'NetworkLoadSchedule' does match current state: LimitedBeginHour: {0} LimitedEndHour: {1} Day: {2} Type: {3}.
    NetworkSchedNonMatch = NOTMATCH: Value for property 'NetworkLoadSchedule' does not match current state, desired settings is LimitedBeginHour: {0} LimitedEndHour: {1}  Day: {2} Type: {3}.
    NetworkSchedSet      = Setting NetworkLoadSchedule to LimitedBeginHour: {0} LimitedEndHour: {1}  Day: {2} Type: {3}.
    FileReplPresent      = NOTMATCH: File replication is present expected absent.
    RemoveReplSite       = Removing File replication from sourceSite: {0} to DestinationSite: {1}.
    ExtraSettings        = Setting {0} does not apply to file replication type specified.
    OverlappingRate      = Skipping RateLimitingSchedule as input specified overlap another parameter defined RateLimitSchedule for LimitedBeginHour: {0} LimitedEndHour: {1}.
    OverlappingSchedule  = NetworkLoadSchedule has an input overlap for BeginHour: {0} EndHour: {1} Day: {2}.
    MultipleTypes        = Only one type PulseMode, Limited, or Unlimited can be set to True in the configuration.
    AccountsError        = You are specifying UseSystemAccount $true and also sepcifying FileRepliacationAccountName, choose one.
    PulseModeError       = When setting PulseMode to True you must specify DataBlocks and DelayBetweenDataBlockSec.
    LimitedError         = When specifying Limited you must also specify RateLimitingSchedule.
    BadAccountName       = AccountName {0} does not exist in Configuraion Manager.
'@
