<#
    .SYNOPSIS
        A DSC configuration script to add a device collection from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMCollections ExampleSettings
        {
            SiteCode               = 'Lab'
            CollectionName         = 'TestDevice'
            CollectionType         = 'Device'
            LimitingCollectionName = 'All Systems'
            Comment                = 'This is a test device collection'
            RefreshSchedule        = DSC_CMCollectionRefreshSchedule
            {
                RecurInterval = 'Days'
                RecurCount    = '7'
            }
            RefreshType            = 'Both'
            QueryRules             = @(
                DSC_CMCollectionQueryRules
                {
                    RuleName        = 'Test1'
                    QueryExpression = @(
                        'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,'
                        'SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,'
                        'SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System' 
                        'inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId' 
                        'where SMS_G_System_COMPUTER_SYSTEM.Domain = "Contoso.com"'
                    ) -Join ' '
                }
                DSC_CMCollectionQueryRules
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
            ExcludeMembership      = 'TestDeviceCollection1','TestDeviceCollection2'
            DirectMembership       = @('2063597577','2063597582')
            Ensure                 = 'Present'
        }
    }
}
