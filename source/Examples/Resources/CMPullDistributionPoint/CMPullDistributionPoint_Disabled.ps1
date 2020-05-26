<#
    .SYNOPSIS
        A DSC configuration script to disable Pull Distribution Point for Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMPullDistributionPoint ExampleSettings
        {
            SiteCode       = 'Lab'
            SiteServerName = 'DP01.contoso.com'
            EnablePullDP   = $false
        }
    }
}
