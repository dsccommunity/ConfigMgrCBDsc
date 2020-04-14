<#
    .SYNOPSIS
        A DSC configuration script to add a device collection from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        Collections ExampleSettings
        {
            SiteCode               = 'Lab'
            CollectionName         = 'TestDevice'
            CollectionType         = 'Device'
            LimitingCollectionName = 'All Systems'
            Comment                = 'This is a test device collection'
            RefreshSchedule        = MSFT_CollectionRefreshSchedule
            {
                RecurInterval = 'Days'
                RecurCount    = '7'
            }
            RefreshType            = 'Both'
            QueryRules = @(
                MSFT_CollectionQueryRules
                {
                    RuleName        = 'Test1'
                    QueryExpression = @(
                        'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,'
                        'SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,'
                        'SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System' 
                        'inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId' 
                        'where SMS_G_System_COMPUTER_SYSTEM.Domain = "jeffo.lab"'
                    ) -Join ' '
                }
                MSFT_CollectionQueryRules
                {
                    RuleName        = 'Test2'
                    QueryExpression = @(
                        'Select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,'
                        'SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System'
                        'inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId' 
                        'where SMS_G_System_COMPUTER_SYSTEM.Manufacturer = "Microsoft Corporation"'
                    ) -Join ''
                }
            )
            Excludemembership      = 'TestDeviceCollection1','TestDeviceCollection2'
            DirectMembership       = @('2063597577','2063597582')
            Ensure                 = 'Present'
        }
    }
}
