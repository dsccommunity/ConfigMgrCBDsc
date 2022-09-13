<#
    .SYNOPSIS
        A DSC configuration script to enable usage of a fallback site called FB1.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMHierarchySetting ExampleSettings
        {
            SiteCode         = 'Lab'
            UseFallbackSite  = $true
            FallbackSiteCode = 'FB1'
        }
    }
}
