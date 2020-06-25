<#
    .SYNOPSIS
        A DSC configuration script to enable Pull Distribution Point for Configuration Manager.
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
            EnablePullDP   = $true
            SourceDistributionPoint = @(
                DSC_CMPullDistributionPointSourceDP
                {
                    SourceDP = 'DP02.contoso.com'
                    DPRank   = 1
                }
                DSC_CMPullDistributionPointSourceDP
                {
                    SourceDP = 'DP03.contoso.com'
                    DPRank   = 2
                }
            )
        }
    }
}
