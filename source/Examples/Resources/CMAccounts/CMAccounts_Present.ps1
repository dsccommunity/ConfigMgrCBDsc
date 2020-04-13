<#
    .SYNOPSIS
        A DSC configuration script to add an account from Configuration Manager.

    .PARAMETER AccountPassword
        Specify the password to be used when adding an account into Configuration Manager.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $AccountPassword
    )

    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMAccounts ExampleSettings
        {
            SiteCode        = 'Lab'
            Account         = 'domain\User'
            AccountPassword = $AccountPassword
            Ensure          = 'Present'
        }
    }
}
