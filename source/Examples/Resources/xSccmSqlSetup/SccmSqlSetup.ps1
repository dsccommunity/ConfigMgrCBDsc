#Requires -Module ConfigMgrCBDsc

<#
    .DESCRIPTION
        This configuration Install SQL for an SCCM install. The DSC resource module, SqlServerDsc, can be used to
        create a more sophisticated install.
#>
Configuration SccmSqlSetup
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
        xSccmSqlSetup SccmSqlSetup
        {
            SqlInstanceName           = 'CA12INST01'
            SqlServiceCredential      = $SqlServiceCredential
            SqlAgentServiceCredential = $SqlAgentServiceCredential
            SqlSysAdminAccounts       = @('contoso\SqlAdmin01','contoso\SqlAdmin02','contoso\SqlAdminGroup')
            InstallSharedDir          = 'E:\Apps\Microsoft SQL Server'
            InstallSharedWowDir       = 'E:\Apps (x86)\Microsoft SQL Server'
            InstallSqlDataDir         = 'E:'
            SqlInstallPath            = 'C:\Windows\Temp\SQL\MSSQL2014wSP3'
            SqlUserDBDir              = 'E:\MSSQL12.CA12INST01\MSSQL\Data\App'
            SqlUserDBLogDir           = 'E:\MSSQL12.CA12INST01\MSSQL\Log\App'
            SqlTempDBDir              = 'E:\MSSQL12.CA12INST01\MSSQL\Data\System'
            SqlTempDBLogDir           = 'E:\MSSQL12.CA12INST01\MSSQL\Log\System'
            SqlPort                   = 4022
        }
    }
}
