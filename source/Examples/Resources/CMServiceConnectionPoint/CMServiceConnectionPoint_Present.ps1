<#
    .SYNOPSIS
        A DSC configuration script to add a service connection point to Configuration Manager.
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
            Mode           = 'Online'
            Ensure         = 'Present'
        }
    }
}
