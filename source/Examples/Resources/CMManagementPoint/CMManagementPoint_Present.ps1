<#
    .SYNOPSIS
        A DSC configuration script to add a mangement point to Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMManagementPoint ExampleSettings
        {
            SiteCode           = 'Lab'
            SiteServerName     = 'MP01.contoso.com'
            Ensure             = 'Present'
            EnableSSL          = $true
            GenerateAlert      = $true
            UseSiteDatabase    = $true
            UseComputerAccount = $true
        }
    }
}
