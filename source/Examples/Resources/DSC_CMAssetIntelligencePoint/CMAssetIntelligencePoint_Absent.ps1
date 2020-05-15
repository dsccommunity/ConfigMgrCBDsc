<#
    .SYNOPSIS
        A DSC configuration script to remove an asset intelligence synchronization point from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMAssetIntelligencePoint ExampleSettings
        {
            SiteCode       = 'Lab'
            SiteServerName = 'CA01.contoso.com'
            Ensure         = 'Absent'
        }
    }
}
