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
            AdkSetupExePath     = 'C:\temp\ADKInstall\adksetup.exe'
            AdkWinPeSetupPath   = 'C:\temp\ADKInstall\adkwinpesetup.exe'
            MdtMsiPath          = 'C:\temp\MDTInstall\MicrosoftDeploymentToolkit_x64_1809.msi'
            LocalAdministrators = @('contoso\steadmin','contoso\C-FE-CM Servers-GS','contoso\svc.FE.cminstall')
            NoSmsOnDrives       = 'c','d'
            DomainCredential    = $DomainCredential
            AdkInstallPath      = 'E:\Apps\ADK'
            MdtInstallPath      = 'E:\Apps\MDT'
        }
    }
}
