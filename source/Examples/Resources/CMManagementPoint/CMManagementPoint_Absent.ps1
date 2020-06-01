<#
    .SYNOPSIS
        A DSC configuration script to remove a management point to Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMManagementPoint ExampleSettings
        {
            SiteCode       = 'Lab'
            SiteServerName = 'MP01.contoso.com'
            Ensure         = 'Absent'
        }
    }
}
