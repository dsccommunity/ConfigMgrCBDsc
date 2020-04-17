<#
    .SYNOPSIS
        A DSC configuration script to remove a collection from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMCollections ExampleSettings
        {
            SiteCode       = 'Lab'
            CollectionName = 'Test'
            CollectionType = 'Device'
            Ensure         = 'Absent'
        }
    }
}
