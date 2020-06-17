<#
    .SYNOPSIS
        A DSC composite resource to install SCCM.

    .PARAMETER SetupExePath
        Specifies the path to the setup.exe for SCCM.

    .PARAMETER IniFile
        Specifies the path of the ini file, to include the filename.

    .PARAMETER SccmServerType
        Specifies the SCCM Server type install, CAS or Primary.

    .PARAMETER SccmInstallAccount
        Specifies the credentials to use for the SCCM install.
#>
Configuration xSCCMInstall
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SetupExePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IniFile,

        [Parameter(Mandatory = $true)]
        [ValidateSet('CAS', 'Primary')]
        [System.String]
        $SccmServerType,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SccmInstallAccount
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    if ($SccmServerType -eq 'CAS')
    {
        $productName = 'System Center Configuration Manager Central Administration Site Setup'
    }
    if ($SccmServerType -eq 'Primary')
    {
        $productName = 'System Center Configuration Manager Primary Site Setup'
    }

    Package SCCM
    {
        Ensure               = 'Present'
        Path                 = "$SetupExePath\Setup.exe"
        Name                 = $productName
        ProductId            = ''
        Arguments            = "/SCRIPT $IniFile"
        DependsOn            = $dependsOnChain
        PsDscRunAsCredential = $SccmInstallAccount
    }
}
