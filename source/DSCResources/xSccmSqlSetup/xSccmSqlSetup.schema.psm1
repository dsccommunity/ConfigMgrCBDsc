Configuration xSccmSqlSetup
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlInstallPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SqlServiceCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $SqlAgentServiceCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]
        $SqlSysAdminAccounts,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlUserDBDir,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlUserDBLogDir,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlTempDBDir,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlTempDBLogDir,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [Uint16]
        $SqlPort,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $InstallSharedDir = 'C:\Program Files\Microsoft SQL Server',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $InstallSharedWowDir = 'C:\Program Files (x86)\Microsoft SQL Server',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $RSSvcStartupType = 'Automatic',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $AgtSvcStartupType = 'Automatic',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $RSInstallMode = 'DefaultNativeMode',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlCollation = 'SQL_Latin1_General_CP1_CI_AS',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $InstallSqlDataDir = 'C:\',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $UpdateEnabled = $false
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SqlServerDsc -ModuleVersion 13.5.0

    # Check SQl 2016 2014

    SqlSetup InstallSql
    {
        Features            = 'SQLENGINE,RS,CONN,BC,SSMS,ADV_SSMS'
        InstallSharedDir    = $InstallSharedDir
        InstallSharedWowDir = $InstallSharedWowDir
        InstanceName        = $SqlInstanceName
        SQLSvcAccount       = $SqlServiceCredential
        AgtSvcAccount       = $SqlAgentServiceCredential
        RSInstallMode       = $RSInstallMode
        RSSVCStartUpType    = $RSSVCStartUpType
        AgtSvcStartupType   = $AgtSvcStartupType
        SQLCollation        = $SqlCollation
        SQLSysAdminAccounts = $SqlSysAdminAccounts
        InstallSQLDataDir   = $InstallSqlDataDir
        SQLUserDBDir        = $SqlUserDBDir
        SQLUserDBLogDir     = $SqlUserDBLogDir
        SQLTempDBDir        = $SqlTempDBDir
        SQLTempDBLogDir     = $SqlTempDBLogDir
        SourcePath          = $SqlInstallPath
        UpdateEnabled       = $UpdateEnabled
    }

    SqlServerNetwork EnableTcpIp
    {
        InstanceName    = $SqlInstanceName
        ProtocolName    = 'Tcp'
        IsEnabled       = $true
        TcpPort         = $SqlPort
        RestartService  = $true
        DependsOn       = '[SqlSetup]InstallSql'
    }
}
