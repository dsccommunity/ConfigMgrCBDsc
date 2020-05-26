<#
    .SYNOPSIS
        A DSC configuration script to disable Pxe Distribution Point for Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMPxeDistributionPoint ExampleSettings
        {
            SiteCode       = 'Lab'
            SiteServerName = 'DP01.contoso.com'
            EnablePxe      = $false
        }
    }
}
