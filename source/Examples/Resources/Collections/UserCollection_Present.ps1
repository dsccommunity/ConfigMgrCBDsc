<#
    .SYNOPSIS
        A DSC configuration script to add an user collection from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        Collections ExampleSettings
        {
            SiteCode               = 'Lab'
            CollectionName         = 'TestUser'
            CollectionType         = 'User'
            LimitingCollectionName = 'All Users'
            Comment                = 'This is a test user collection'
            RefreshSchedule        = @{
                RecurInterval = 'Days'
                RecurCount    = '7'
            }
            RefreshType            = 'Both'
            QueryRules = @(
                @{
                    RuleName        = 'UserTestQuery'
                    QueryExpression = @(
                        'select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,'
                        'SMS_R_USER.Name,SMS_R_USER.UniqueUserName,'
                        'SMS_R_USER.WindowsNTDomain from SMS_R_User'
                        'where SMS_R_User.UserName = "Test4"'
                    ) -Join ''
                }
                @{
                    RuleName        = 'UserTestQuery2'
                    QueryExpression = @(
                        'select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,'
                        'SMS_R_USER.Name,SMS_R_USER.UniqueUserName,SMS_R_USER.WindowsNTDomain'
                        ' from SMS_R_User where SMS_R_User.NetworkOperatingSystem = "Windows NT"'
                    ) -Join ''
                }
            )
            Excludemembership      = 'TestUserGroup1','TestUserGroup2'
            DirectMembership       = @('2063597577','2063597582')
            Ensure                 = 'Present'
        }
    }
}
