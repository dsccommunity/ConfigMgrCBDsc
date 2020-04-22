<#
    .SYNOPSIS
        A DSC  composite resource to configure a basic installation of Microsoft SQL Server for 2014 SCCM Servers.

    .PARAMETER SqlInstallPath
        Specifies the path to the setup.exe file for SQL.

    .PARAMETER SqlInstanceName
        Specifies a SQL Server instance name.

    .PARAMETER SqlServiceCredential
        Specifies the credential for the service account used to run the SQL Service.

    .PARAMETER SqlAgentServiceCredential
        Specifies the credential for the service account used to run the SQL Agent Service.

    .PARAMETER SqlSysAdminAccounts
        Use this parameter to provision logins to be members of the sysadmin role.

    .PARAMETER SqlUserDBDir
        Specifies the directory for the data files for user databases.

    .PARAMETER SqlUserDBLogDir
        Specifies the directory for the log files for user databases.

    .PARAMETER SqlTempDBDir
        Specifies the directory for the data files for tempdb.

    .PARAMETER SqlTempDBLogDir
        Specifies the directory for the log files for tempdb.

    .PARAMETER SqlPort
        Specifies the port SQL listens on.

    .PARAMETER InstallSharedDir
        Specifies the installation directory for 64-bit shared components.

    .PARAMETER InstallSharedWowDir
        Specifies the installation directory for 32-bit shared components. Supported only on a 64-bit system.

    .PARAMETER RSSvcStartupType
        Specifies the startup mode for Reporting Services.

    .PARAMETER AgtSvcStartupType
        Specifies the startup mode for the SQL Server Agent service.

    .PARAMETER RSInstallMode
        Specifies the Install mode for Reporting Services.
        Supported Values:
            SharePointFilesOnlyMode
            DefaultNativeMode
            FilesOnlyMode
                Note:
                If the installation includes the SQL Server Database engine, the default RSInstallMode is DefaultNativeMode.
                If the installation does not include the SQL Server Database engine, the default RSInstallMode is FilesOnlyMode.
                If you choose DefaultNativeMode but the installation does not include the SQL Server Database engine,
                the installation will automatically change the RSInstallMode to FilesOnlyMode.

    .PARAMETER SqlCollation
        Specifies the collation settings for SQL Server.

    .PARAMETER InstallSqlDataDir
        Specifies the data directory for SQL Server data files.

    .PARAMETER UpdateEnabled
        Specify whether SQL Server setup should discover and include product updates.

    .PARAMETER InstallManagementStudio
        Specify whether to install SQL Management Studio.

    .PARAMETER SqlManagementStudioExePath
        Specify that path and filename to the exe for Management Studio instal..

    .PARAMETER SqlManagementStudioName
        Specify the name of SQL Server Management Studio.
        Default is 'SQL Server Management Studio'.

    .PARAMETER SqlManagementStudioProductId
        Specify the product if of the SQL Management Studio install being performed.
        Defaults to 18.5 ProductID.
#>
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
        $UpdateEnabled = $false,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [Boolean]
        $InstallManagementStudio = $false,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlManagementStudioExePath,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlManagementStudioName = 'SQL Server Management Studio',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [String]
        $SqlManagemenStudioProductId = 'E3FD687D-6757-474B-8D83-5AA944B02C58'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SqlServerDsc

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

    if ($InstallManagementStudio)
    {
        if ($null -eq $SqlManagementStudioExePath)
        {
            Write-Error -Message $('When specifying to Install SQL Management Studio, you need to provide ' +
                'SqlManagementStudioExePath.')
        }

        Package InstallSqlManagementStudio
        {
            Ensure      = 'Present'
            Path        = $SqlManagementStudioExePath
            Name        = $SqlManagementStudioName
            Arguments   = '/install /quiet /norestart'
            ProductId   = $SqlManagemenStudioProductId
            DependsOn   = '[SqlServerNetwork]EnableTcpIp'
        }
    }
}
