<#
    .SYNOPSIS
        A DSC configuration script to remove a service connection point from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMServiceConnectionPoint ExampleSettings
        {
            SiteCode       = 'Lab'
            SiteServerName = 'CA01.contoso.com'
            Ensure         = 'Absent'
        }
    }
}
