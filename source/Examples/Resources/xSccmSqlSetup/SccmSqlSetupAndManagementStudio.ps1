#Requires -Module ConfigMgrCBDsc

<#
    .DESCRIPTION
        This configuration Install SQL for an SCCM install. The DSC resource module, SqlServerDsc, can be used to
        create a more sophisticated install.
#>
Configuration Example
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceCredential
    )

    Import-DscResource -ModuleName ConfigMgrCBDsc

    Node localhost
    {
        xSccmSqlSetup SccmSqlSetupAndManagementStudio
        {
            SqlVersion                 = '2014'
            SqlInstanceName            = 'CASINST01'
            SqlServiceCredential       = $SqlServiceCredential
            SqlAgentServiceCredential  = $SqlAgentServiceCredential
            SqlSysAdminAccounts        = @('contoso\SqlAdmin01','contoso\SqlAdmin02','contoso\SqlAdminGroup')
            SqlInstallPath             = 'C:\Windows\Temp\SQL\MSSQL2014wSP3'
            InstallManagementStudio    = $true
            SqlManagementStudioExePath = 'C:\Windows\temp\SSMS18_5\SSMS-Setup-ENU.exe'
        }
    }
}
