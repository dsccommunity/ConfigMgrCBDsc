<#
    .SYNOPSIS
        A DSC configuration to remove a file replication configuration.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMFileReplication ExampleAbsent
        {
            SiteCode             = 'LAB'
            DestinationSiteCode  = 'PR1'
            Ensure               = 'Absent'
        }
    }
}
