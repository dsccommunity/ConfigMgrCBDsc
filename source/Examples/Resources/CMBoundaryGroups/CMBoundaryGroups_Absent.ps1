<#
    .SYNOPSIS
        A DSC configuration script to remove a boundary group from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMBoundaryGroups ExampleSettings
        {
            SiteCode      = 'Lab'
            BoundaryGroup = 'TestGroup'
            Ensure        = 'Absent'
        }
    }
}
