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
        Ensure    = 'Present'
        Path      = "$SetupExePath\Setup.exe"
        Name      = $productName
        ProductId = ''
        Arguments = "/SCRIPT $IniFile"
        DependsOn = $dependsOnChain
        PsDscRunAsCredential = $SccmInstallAccount
    }
}
