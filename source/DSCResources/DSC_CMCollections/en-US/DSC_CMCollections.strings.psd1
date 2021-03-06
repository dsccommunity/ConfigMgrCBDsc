ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager collection.
    MissingLimiting      = Collection does not exist and no LimitingCollectionName has been specified.
    CollectionAbsent     = {0} collection is missing expected present.
    CollectionType       = Desired collection type is {0} and currently is {1}, if specified collection type is correct the collection will need deleted prior to creating a new collection.
    RuleConflict         = Input for IncludeMembership and ExcludeMembership contain the same entry {0}.
    ExcludeError         = Exclude rule name {0} already exists as a rule name for another query on the collection, rule names must be unique per collection.
    ExcludeMemberRule    = {0} collection expected Exclude membership rule {1} to be present.
    DirectMemberRule     = {0} collection expected Direct membership rule {1} to be present.
    IncludeError         = Include rule name {0} already exists as a rule name for another query on the collection rule names must be unique per collection.
    IncludeMemberRule    = {0} collection expected Include membership rule {1} to be present.
    QueryRule            = {0} collection expected Query rule {1} to be present.
    RemoveCollection     = Expected {0} to be absent.
    TestState            = Test-TargetResource compliance check returned: {0}.
    DirectConflict       = DirectMembership contains the ResourceID {0} and Name {1} for the same resource.
    InvalidId            = Unable to find object with resource ID {0}.
    CollectionCreate     = {0} collection is missing, creating collection.
    CollectionSetting    = {0} collection expected {1} to be "{2}" returned "{3}".
    NewSchedule          = Modifying collection schedule.
    ExcludeNonAdd        = Collection {0} does not exist and can not be added to exclude membership.
    IncludeNonAdd        = Collection {0} does not exist and can not be added to include membership.
    DirectNonAdd         = {0} does not exist and can not be added to as direct membership.
'@
