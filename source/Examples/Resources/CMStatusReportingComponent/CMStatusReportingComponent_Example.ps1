<#
    .SYNOPSIS
        A DSC configuration script to configure the Status Reporting Component in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMStatusReportingComponent ExampleSettings
        {
            SiteCode                   = 'LAB'
            ClientLogChecked           = $true
            ClientLogFailureChecked    = $true
            ClientLogType              = 'ErrorMilestones'
            ClientReportChecked        = $true
            ClientReportFailureChecked = $true
            ClientReportType           = 'AllMilestones'
            ServerLogChecked           = $true
            ServerLogFailureChecked    = $true
            ServerLogType              = 'AllMilestones'
            ServerReportChecked        = $true
            ServerReportFailureChecked = $true
            ServerReportType           = 'AllMilestones'
        }
    }
}
