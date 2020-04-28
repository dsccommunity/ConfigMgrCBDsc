#Requires -Module ConfigMgrCBDsc

<#
    .DESCRIPTION
        This configuration will install: ADK, ADK WinPE and MDT, add users/groups to the Local Administrators group,
        and put nosms files on specified drives.
#>
Configuration Example
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DomainCredential
    )

    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {

        xSccmPreReqs SCCMPreReqs
        {
            AddWindowsFirewallRule = $true
            FirewallProfile        = 'Domain','Private'
            FirewallTcpLocalPort   = '1433','1434','4022','445','135','139','49154-49157'
            FirewallUdpLocalPort   = '137-138','5355'
            AdkSetupExePath        = 'C:\temp\ADKInstall\adksetup.exe'
            AdkWinPeSetupPath      = 'C:\temp\ADKInstall\adkwinpesetup.exe'
            MdtMsiPath             = 'C:\temp\MDTInstall\MicrosoftDeploymentToolkit_x64_1809.msi'
            LocalAdministrators    = @('contoso\administrator','contoso\AdminGroup','contoso\svc.installaccount')
            NoSmsOnDrives          = 'd'
            DomainCredential       = $DomainCredential
        }
    }
}
