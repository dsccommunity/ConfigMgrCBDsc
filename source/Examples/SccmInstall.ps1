#Requires -Module ConfigMgrCBDsc

<#
    .DESCRIPTION
        This configuration will install the prerequistes that are need for SCCM, install SQL, create the ini file
        needed for the SCCM install, and install SCCM.

    .NOTES
        Ensure the SCCM install is not on a drive that is specified for xSccmPreReqs NoSmsOnDrives.
        Ensure the SQLInstall SqlPort is not the same as SQLSSBPort in the SCCM ini file.
#>
Configuration SCCMInstall
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DomainCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SccmInstallAccount
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

        xSccmSqlSetup SccmSqlSetup
        {
            SqlInstanceName           = 'CA12INST01'
            SqlServiceCredential      = $SqlServiceCredential
            SqlAgentServiceCredential = $SqlAgentServiceCredential
            SqlSysAdminAccounts       = @('contoso\W-YO-SQLAdmins-LS','contoso\steadmin','contoso\svc.FE.cminstall')
            InstallSharedDir          = 'E:\Apps\Microsoft SQL Server'
            InstallSharedWowDir       = 'E:\Apps (x86)\Microsoft SQL Server'
            InstallSqlDataDir         = 'E:'
            SqlInstallPath            = 'C:\Windows\Temp\SQL\MSSQL2014wSP3'
            SqlUserDBDir              = 'E:\MSSQL12.CA12INST01\MSSQL\Data\App'
            SqlUserDBLogDir           = 'E:\MSSQL12.CA12INST01\MSSQL\Log\App'
            SqlTempDBDir              = 'E:\MSSQL12.CA12INST01\MSSQL\Data\System'
            SqlTempDBLogDir           = 'E:\MSSQL12.CA12INST01\MSSQL\Log\System'
            SqlPort                   = 1433
        }

        SccmIniFile CreateSCCMIniFile
        {
            IniFileName               = 'Lab-CAS-Test.ini'
            IniFilePath               = 'C:\temp\'
            Action                    = 'InstallCAS'
            CDLatest                  = $true
            ProductID                 = 'BXH69-M62YX-QQD6R-3GPWX-8WMFY'
            SiteCode                  = 'LAB'
            SiteName                  = 'Contoso - Central Administration Site'
            SMSInstallDir             = 'E:\Program Files\Microsoft Configuration Manager'
            SDKServer                 = 'CA01.contoso.com'
            PreRequisiteComp          = $true
            PreRequisitePath          = 'C:\Temp\SCCMInstall\Downloads'
            AdminConsole              = $true
            JoinCeip                  = $false
            MobileDeviceLanguage      = $false
            SQLServerName             = 'CA01.contoso.com'
            DatabaseName              = 'CA12INST01\CM_LAB'
            SQLSSBPort                = 4022
            SQLDataFilePath           = 'E:\MSSQL12.CA12INST01\MSSQL\Data\'
            SQLLogFilePath            = 'E:\MSSQL12.CA12INST01\MSSQL\Log\'
            CloudConnector            = $false
            SAActive                  = $true
            CurrentBranch             = $true
        }

        xSccmInstall SccmInstall
        {
            SetupExePath       = 'C:\Temp\SCCMInstall\SMSSETUP\BIN\X64'
            IniFile            = 'C:\temp\Lab-CAS-Test.ini'
            SccmServerType     = 'CAS'
            SccmInstallAccount = $SccmInstallAccount
            DependsOn          = '[xSccmPreReqs]SCCMPreReqs','[xSccmSqlSetup]SccmSqlSetup','[SccmIniFile]CreateSCCMIniFile'
        }
    }
}
