<#
    .SYNOPSIS
        A DSC configuration script to remove an account from Configuration Manager.
#>
Configuration Example
{
    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMAccounts ExampleSettings
        {
            SiteCode = 'Lab'
            Account  = 'domain\User'
            Ensure   = 'Absent'
        }
    }
}
