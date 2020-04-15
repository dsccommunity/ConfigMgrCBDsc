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
        $InstanceName,

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
        [ValidateSet('2008','2008R2','2012','2014','2016','2017','2019')]
        [String]
        $SqlVersion,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $InstallSharedDir = 'C:\Program Files\Microsoft SQL Server',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $InstallSharedWowDir = 'C:\Program Files (x86)\Microsoft SQL Server',

        #[Parameter()]
        #[ValidateNotNullorEmpty()]
        #[String]
        #$InstanceDir,

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

        #[Parameter(Mandatory = $true)]
        #[ValidateNotNullorEmpty()]
        #[String]
        #$SqlUserDBDir,

        #[Parameter(Mandatory = $true)]
        #[ValidateNotNullorEmpty()]
        #[String]
        #$SqlUserDBLogDir,

        #[Parameter(Mandatory = $true)]
        #[ValidateNotNullorEmpty()]
        #[String]
        #$SqlTempDBDir,

        #[Parameter(Mandatory = $true)]
        #[ValidateNotNullorEmpty()]
        #[String]
        #$SqlTempDBLogDir,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $UpdateEnabled = $false
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SqlServerDsc -ModuleVersion 13.5.0

    switch ($SqlVersion)
    {
        '2008'   { $version = '10' }
        '2008R2' { $version = '10' }
        '2012'   { $version = '11' }
        '2014'   { $version = '12' }
        '2016'   { $version = '13' }
        '2017'   { $version = '14' }
        '2019'   { $version = '15' }
    }

    if ([string]::IsNullOrEmpty($InstanceDir))
    {
        $newInstanceDir = "$InstallSharedDir\MSSQL$version.$InstanceName"
    }
    else
    {
        $newInstanceDir = $InstanceDir
    }

    SqlSetup InstallSql
    {
        Features            = 'SQLENGINE,RS,CONN,BC,SSMS,ADV_SSMS'
        InstallSharedDir    = $InstallSharedDir
        InstallSharedWowDir = $InstallSharedWowDir
        InstanceName        = $InstanceName
        #InstanceDir         = $newInstanceDir
        SQLSvcAccount       = $SqlServiceCredential
        AgtSvcAccount       = $SqlAgentServiceCredential
        RSInstallMode       = $RSInstallMode
        RSSVCStartUpType    = $RSSVCStartUpType
        AgtSvcStartupType   = $AgtSvcStartupType
        SQLCollation        = $SqlCollation
        SQLSysAdminAccounts = $SqlSysAdminAccounts
        InstallSQLDataDir   = $InstallSqlDataDir
        #SQLUserDBDir        = $SqlUserDBDir
        #SQLUserDBLogDir     = $SqlUserDBLogDir
        #SQLTempDBDir        = $SqlTempDBDir
        #SQLTempDBLogDir     = $SqlTempDBLogDir
        SourcePath          = $SqlInstallPath
        UpdateEnabled       = $UpdateEnabled
    }

    SqlServerNetwork EnableTcpIp
    {
        InstanceName    = $SqlInstanceName
        ProtocolName    = 'Tcp'
        IsEnabled       = $true
        TcpPort         = 1433
        RestartService  = $true
        DependsOn       = '[SqlSetup]InstallSql'
    }
}
