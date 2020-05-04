<#
    .SYNOPSIS
        A DSC configuration script to add a boundary group and match boundaries in Configuration Manager.
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
            Boundaries    = 'TB1','TB2'
            Ensure        = 'Present'
        }
    }
}
