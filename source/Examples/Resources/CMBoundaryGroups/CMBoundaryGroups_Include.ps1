<#
    .SYNOPSIS
        A DSC configuration script to add a boundary group and append boundaries in Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMBoundaryGroups ExampleSettings
        {
            SiteCode            = 'Lab'
            BoundaryGroup       = 'TestGroup'
            BoundariesToInclude = 'TB1','TB2'
            Ensure              = 'Present'
        }
    }
}
