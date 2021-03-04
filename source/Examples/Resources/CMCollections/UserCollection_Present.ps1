<#
    .SYNOPSIS
        A DSC configuration script to add an user collection from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMCollections ExampleSettings
        {
            SiteCode               = 'Lab'
            CollectionName         = 'TestUser'
            CollectionType         = 'User'
            LimitingCollectionName = 'All Users'
            Comment                = 'This is a test user collection'
            ScheduleType           = 'Days'
            RecurInterval          = 7
            RefreshType            = 'Both'
            QueryRules             = @(
                DSC_CMCollectionQueryRules
                {
                    RuleName        = 'UserTestQuery'
                    QueryExpression = @(
                        'select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,'
                        'SMS_R_USER.Name,SMS_R_USER.UniqueUserName,'
                        'SMS_R_USER.WindowsNTDomain from SMS_R_User'
                        'where SMS_R_User.UserName = "Test4"'
                    ) -Join ' '
                }
                DSC_CMCollectionQueryRules
                {
                    RuleName        = 'UserTestQuery2'
                    QueryExpression = @(
                        'select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,'
                        'SMS_R_USER.Name,SMS_R_USER.UniqueUserName,SMS_R_USER.WindowsNTDomain'
                        ' from SMS_R_User where SMS_R_User.NetworkOperatingSystem = "Windows NT"'
                    ) -Join ' '
                }
            )
            ExcludeMembership      = 'TestUserGroup1','TestUserGroup2'
            DirectMembership       = @('2063597577','TestUser1')
            IncludeMembership      = @('TestUserGroup3','TestUserGroup4')
            Ensure                 = 'Present'
        }
    }
}
