<#
    .SYNOPSIS
        A DSC configuration script to configure the Collection Membership Evaluation Component in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMCollectionMembershipEvaluationComponent ExampleSettings
        {
            SiteCode       = 'LAB'
            EvaluationMins = 5
        }
    }
}
