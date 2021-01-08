<#
    .SYNOPSIS
        A DSC configuration script to configure SoftwareDistributionComponent for Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMSoftwareDistributionComponent ExampleServer
        {
            SiteCode                         = 'Lab'
            MaximumPackageCount              = 10
            MaximumThreadCountPerPackage     = 100
            RetryCount                       = 3
            DelayBeforeRetryingMins          = 2
            MulticastRetryCount              = 3
            MulticastDelayBeforeRetryingMins = 2
            AccessAccountsToInclude          = @('contoso\Network1','contoso\Network2')
            AccessAccountsToExclude          = @('contoso\Network3')
        }
    }
}
