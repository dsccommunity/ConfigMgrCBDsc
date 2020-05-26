<#
    .SYNOPSIS
        A DSC configuration script to configure Pxe Distribution Point for Configuration Manager.

    .PARAMETER PxePassword
        Specify the password to be used for the Pxe.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $PxePassword
    )

    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        CMPxeDistributionPoint ExampleSettings
        {
            SiteCode                     = 'Lab'
            SiteServerName               = 'DP01.contoso.com'
            EnablePxe                    = $true
            EnableNonWdsPxe              = $true
            EnableUnknownComputerSupport = $true
            AllowPxeResponse             = $true
            PxeServerResponseDelaySec    = 2
            UserDeviceAffinity           = 'AllowWithAutomaticApproval'
            PxePassword                  = $PxePassword
        }
    }
}
