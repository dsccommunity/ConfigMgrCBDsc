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
        [System.Management.Automation.PSCredential]
        $SccmInstallAccount
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    # Based off the ini file determine which site is going to be installed and verified by package resource.
    $iniContent = Get-Content -Path $IniFile
    $action = $iniContent.Where({$_ -match 'Action='})

    if ($action -match 'InstallCAS')
    {
        $productName = 'System Center Configuration Manager Central Administration Site Setup'
    }
    if ($action -match 'InstallPrimarySite')
    {
        $productName = 'System Center Configuration Manager Primary Site Setup'
    }

    # Install SCCM 1906
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
