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

    .PARAMETER Version
        Specifies the version of SCCM that will be installed.
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
        $SccmInstallAccount,

        [Parameter(Mandatory = $true)]
        [ValidateSet('1902', '1906', '1910', '2002', '2006', '2010')]
        [UInt32]
        $Version
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    if ($Version -lt 1910)
    {
        $prefix = 'System Center'
    }
    else
    {
        $prefix = 'Microsoft Endpoint'
    }

    if ($SccmServerType -eq 'CAS')
    {
        $productName = "$prefix Configuration Manager Central Administration Site Setup"
    }
    if ($SccmServerType -eq 'Primary')
    {
        $productName = "$prefix Configuration Manager Primary Site Setup"
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
