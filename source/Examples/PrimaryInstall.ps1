#Requires -Module ConfigMgrCBDsc

<#
    .DESCRIPTION
        This configuration will install the prerequistes that are need for SCCM, install SQL, create the ini file
        needed for the SCCM install, and install SCCM. This will also perform a basic configuration on the Primary
        Site Server.

    .NOTES
        Having AD set up is a pre-requisite. Please ensure the appropriate accounts are created and nested as desired.
        ADK, MDT, SQL, and SCCM source media are required in order to use this example.
        Please examine the Import-DscResource statements and ensure that the appropriate modules are installed.
        Replace the line items specified with entries appropriate to your environment.
        Ensure the SCCM install is not on a drive that is specified for xSccmPreReqs NoSmsOnDrives.
        Ensure the SQLInstall SqlPort is not the same as SQLSSBPort in the SCCM ini file.

        This configuration will generate a mof and a meta mof. Please use the Set-DscLocalConfigurationManager
        commandlet to apply the meta mof first.

        Please note: this example provides no methodology to encrypt the mof file and any credentials will be
        saved in the mof in plain text.
#>
Configuration PrimaryInstall
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.String]
        $SiteName,

        [Parameter()]
        [System.String]
        $SiteCode,

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
        $SccmInstallAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential[]]
        $CMAccounts,

        [Parameter()]
        [System.Nullable[UInt32]]
        $ConfigMgrVersion
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName ComputerManagementDsc -ModuleVersion 8.2.0
    Import-DscResource -ModuleName ConfigMgrCBDsc -ModuleVersion 0.2.0
    Import-DscResource -ModuleName SqlServerDsc -ModuleVersion 14.0.0
    Import-DscResource -ModuleName UpdateServicesDsc -ModuleVersion 1.2.1
    Import-DscResource -ModuleName NetworkingDsc -ModuleVersion 7.4.0.0

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        $serverShortName = $ServerName.split('.')[0]

        if ($serverShortName.Length -gt 4)
        {
            $dbInstanceName = $serverShortName.SubString($serverShortName.Length - 4) + "DB01"
        }
        else
        {
            $dbInstanceName = $serverShortName + "DB01"
        }

        if ($ConfigMgrVersion -lt '1910')
        {
            $adkProductID   = 'fb450356-9879-4b2e-8dc9-282709286661'
            $winPeProductID = 'd8369a05-1f4a-4735-9558-6e131201b1a2'
        }
        else
        {
            $adkProductID   = '9346016b-6620-4841-8ea4-ad91d3ea02b5'
            $winPeProductID = '353df250-4ecc-4656-a950-4df93078a5fd'
        }

        #SCCM PreReqs
        xSccmPreReqs SCCMPreReqs
        {
            InstallAdk             = $true
            InstallMdt             = $true
            AdkSetupExePath        = 'C:\Temp\adksetup.exe'
            AdkWinPeSetupPath      = 'C:\Temp\adkwinpesetup.exe'
            MdtMsiPath             = 'C:\Temp\MicrosoftDeploymentToolkit_x64_1809.msi'
            InstallWindowsFeatures = $true
            WindowsFeatureSource   = 'C:\Windows\WinSxS'
            SccmRole               = 'CASorSiteServer','ManagementPoint','DistributionPoint','SoftwareUpdatePoint'
            AddWindowsFirewallRule = $true
            FirewallProfile        = 'Domain','Private'
            LocalAdministrators    = @('contoso\SCCM-Servers','contoso\SCCM-CMInstall','contoso\Admin')
            DomainCredential       = $DomainCredential
            AdkInstallPath         = 'C:\Apps\ADK'
            MdtInstallPath         = 'C:\Apps\MDT'
            AdkProductName         = 'Windows Assessment and Deployment Kit - Windows 10'
            AdkProductID           = $adkProductID
            AdkWinPeProductName    = 'Windows Assessment and Deployment Kit Windows Preinstallation Environment Add-ons - Windows 10'
            AdkWinPeProductID      = $winPeProductID
        }

        xSccmSqlSetup SCCMSqlInstall
        {
            SqlVersion                = '2014'
            Features                  = 'SQLENGINE,RS,CONN,BC,SSMS,ADV_SSMS'
            InstallSharedDir          = 'C:\Apps\Microsoft SQL Server'
            InstallSharedWowDir       = 'C:\Apps (x86)\Microsoft SQL Server'
            InstanceDir               = 'C:\Apps\Microsoft SQL Server'
            SqlInstanceName           = $dbInstanceName
            SqlServiceCredential      = $SqlServiceCredential
            SqlAgentServiceCredential = $SqlAgentServiceCredential
            RSInstallMode             = 'DefaultNativeMode'
            RSSVCStartUpType          = 'Automatic'
            AgtSvcStartupType         = 'Automatic'
            SQLCollation              = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSysAdminAccounts       = @('contoso\SCCM-Servers','contoso\Admin','contoso\SCCM-CMInstall')
            InstallSQLDataDir         = "C:"
            SQLUserDBDir              = "C:\MSSQL12.$dbInstanceName\MSSQL\Data\App"
            SQLUserDBLogDir           = "C:\MSSQL12.$dbInstanceName\MSSQL\Log\App"
            SQLTempDBDir              = "C:\MSSQL12.$dbInstanceName\MSSQL\Data\System"
            SQLTempDBLogDir           = "C:\MSSQL12.$dbInstanceName\MSSQL\Log\System"
            SqlInstallPath            = 'C:\temp\SQL\MSSQL2014wSP3'
            UpdateEnabled             = $false
            DependsOn                 = '[xSccmPreReqs]SCCMPreReqs'
        }

        #Install WSUS features
        WindowsFeatureSet WSUSFeatures
        {
            Name   = 'UpdateServices-Services','UpdateServices-DB','UpdateServices-API','UpdateServices-UI'
            Ensure = 'Present'
            Source = 'C:\Windows\WinSxS'
        }

        # WSUS registry value to fix issues with WSUS self-signed certificates
        Registry EnableWSUSSelfSignedCert
        {
            Ensure    = 'Present'
            Key       = 'HKLM:\Software\Microsoft\Update Services\Server\Setup'
            ValueName = 'EnableSelfSignedCertificates'
            ValueData = '1'
            ValueType = 'Dword'
        }

        File WSUSUpdates
        {
            DestinationPath = 'C:\Apps\WSUS'
            Ensure          = 'Present'
            Type            = 'Directory'
        }

        UpdateServicesServer WSUSConfig
        {
            Ensure             = 'Present'
            SQLServer          = "$ServerName\$dbInstanceName"
            ContentDir         = 'C:\Apps\WSUS'
            Products           = '*'
            Classifications    = '*'
            UpstreamServerSSL  = $false
            Synchronize        = $false
            DependsOn          = '[File]WSUSUpdates','[WindowsFeatureSet]WSUSFeatures','[Registry]EnableWSUSSelfSignedCert'
        }

        File CreateIniFolder
        {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = 'C:\SetupFiles'
            DependsOn       = '[xSccmSqlSetup]SCCMSqlInstall'
        }

        CMIniFile CreateSCCMIniFile
        {
            IniFileName               = 'Demo.ini'
            IniFilePath               = 'C:\SetupFiles\'
            Action                    = 'InstallPrimarySite'
            CDLatest                  = $false
            ProductID                 = 'eval'
            SiteCode                  = $SiteCode
            SiteName                  = "$SiteName - Primary Site"
            SMSInstallDir             = 'C:\Apps\Microsoft Configuration Manager'
            SDKServer                 = $ServerName
            RoleCommunicationProtocol = 'HTTPorHTTPS'
            ClientsUsePKICertificate  = $true
            PreRequisiteComp          = $true
            PreRequisitePath          = 'C:\temp\SCCMInstall\Downloads'
            AdminConsole              = $true
            JoinCeip                  = $false
            MobileDeviceLanguage      = $false
            SQLServerName             = $ServerName
            DatabaseName              = "$dbInstanceName\CM_$SiteCode"
            SQLSSBPort                = 4022
            SQLDataFilePath           = "C:\MSSQL12.$dbInstanceName\MSSQL\Data\"
            SQLLogFilePath            = "C:\MSSQL12.$dbInstanceName\MSSQL\Log\"
            CloudConnector            = $false
            SAActive                  = $true
            CurrentBranch             = $true
            DependsOn                 = '[File]CreateIniFolder'
        }

        xSccmInstall SccmInstall
        {
            SetupExePath       = 'C:\temp\SCCMInstall\SMSSETUP\BIN\X64'
            IniFile            = 'C:\SetupFiles\Demo.ini'
            SccmServerType     = 'Primary'
            SccmInstallAccount = $SccmInstallAccount
            Version            = $ConfigMgrVersion
            DependsOn          = '[CMIniFile]CreateSCCMIniFile'
        }

        # Ensuring the machine reboots after SCCM install in order to be sure configurations proceed properly
        Script RebootAfterSccmSetup
        {
            TestScript = {
                return (Test-Path HKLM:\SOFTWARE\Microsoft\SMS\RebootAfterSCCMSetup)
            }
            SetScript  = {
                $process = Get-Process | Where-Object -FilterScript {$_.Description -eq 'Configuration Manager Setup BootStrapper'}

                if ([string]::IsNullOrEmpty($process))
                {
                    Write-Verbose -Message "SCCM has finished installing setting reboot"
                    New-Item -Path HKLM:\SOFTWARE\Microsoft\SMS\RebootAfterSCCMSetup -Force
                    $global:DSCMachineStatus = 1
                }
                else
                {
                    throw 'Configuration Manager setup is still running'
                }
            }
            GetScript  = { return @{result = 'result'}}
            DependsOn  = '[xSccmInstall]SccmInstall'
        }

        #region ConfigCBMgr configurations
        foreach ($account in $CMAccounts)
        {
            CMAccounts "AddingAccount-$($account.Username)"
            {
                SiteCode             = $SiteCode
                Account              = $account.Username
                AccountPassword      = $account
                Ensure               = 'Present'
                PsDscRunAsCredential = $SccmInstallAccount
                DependsOn            = '[Script]RebootAfterSccmSetup'
            }

            [array]$cmAccountsDependsOn += "[CMAccounts]AddingAccount-$($account.Username)"
        }

        CMForestDiscovery CreateForestDiscovery
        {
            SiteCode             = $SiteCode
            Enabled              = $false
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        CMSystemDiscovery CreateSystemDiscovery
        {
            SiteCode                        = $SiteCode
            Enabled                         = $true
            ScheduleInterval                = 'Days'
            ScheduleCount                   = 7
            EnableDeltaDiscovery            = $true
            DeltaDiscoveryMins              = 60
            EnableFilteringExpiredLogon     = $true
            TimeSinceLastLogonDays          = 90
            EnableFilteringExpiredPassword  = $true
            TimeSinceLastPasswordUpdateDays = 90
            ADContainers                    = @('LDAP://OU=Domain Controllers,DC=contoso,DC=com','LDAP://CN=Computers,DC=contoso,DC=com')
            PsDscRunAsCredential            = $SccmInstallAccount
            DependsOn                       = '[Script]RebootAfterSccmSetup'
        }

        CMNetworkDiscovery DisableNetworkDiscovery
        {
            SiteCode             = $SiteCode
            Enabled              = $false
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        CMHeartbeatDiscovery CreateHeartbeatDiscovery
        {
            SiteCode             = $SiteCode
            Enabled              = $true
            ScheduleInterval     = 'Days'
            ScheduleCount        = '1'
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        CMUserDiscovery CreateUserDiscovery
        {
            SiteCode             = $SiteCode
            Enabled              = $true
            ScheduleInterval     = 'Days'
            ScheduleCount        = 7
            EnableDeltaDiscovery = $true
            DeltaDiscoveryMins   = 5
            ADContainers         = @('LDAP://CN=Users,DC=contoso,DC=com')
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        CMClientStatusSettings CreateClientStatusSettings
        {
            SiteCode               = $SiteCode
            IsSingleInstance       = 'Yes'
            ClientPolicyDays       = 7
            HeartbeatDiscoveryDays = 7
            SoftwareInventoryDays  = 7
            HardwareInventoryDays  = 7
            StatusMessageDays      = 7
            HistoryCleanupDays     = 31
            PsDscRunAsCredential   = $SccmInstallAccount
            DependsOn              = '[Script]RebootAfterSccmSetup'
        }

        File CreateBackupFolder
        {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = 'C:\cmsitebackups'
        }

        CMSiteMaintenance Backup
        {
            SiteCode             = $SiteCode
            TaskName             = 'Backup SMS Site Server'
            Enabled              = $true
            DaysOfWeek           = @('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')
            BeginTime            = '1500'
            LatestBeginTime      = '2000'
            BackupLocation       = 'C:\cmsitebackups'
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup','[File]CreateBackupFolder'
        }

        [array]$cmSiteMaintenanceDependsOn += '[CMSiteMaintenance]Backup'

        CMSiteMaintenance DeleteEP
        {
            SiteCode             = $SiteCode
            TaskName             = 'Delete Aged EP Health Status History Data'
            Enabled              = $false
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        [array]$cmSiteMaintenanceDependsOn += '[CMSiteMaintenance]DeleteEP'

        CMSiteMaintenance UpdateAppTables
        {
            SiteCode             = $SiteCode
            TaskName             = 'Update Application Catalog Tables'
            Enabled              = $true
            RunInterval          = 1380
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        [array]$cmSiteMaintenanceDependsOn += '[CMSiteMaintenance]UpdateAppTables'

        CMSiteMaintenance InactiveDisco
        {
            SiteCode             = $SiteCode
            TaskName             = 'Delete Inactive Client Discovery Data'
            Enabled              = $true
            DaysOfWeek           = 'Saturday'
            DeleteOlderThanDays  = 90
            BeginTime            = '1500'
            LatestBeginTime      = '2000'
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        [array]$cmSiteMaintenanceDependsOn += '[CMSiteMaintenance]InactiveDisco'

        CMBoundaries DemoBoundary
        {
            SiteCode             = $SiteCode
            DisplayName          = 'Contoso Boundary'
            Value                = '10.10.1.1-10.10.1.254'
            Type                 = 'IPRange'
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        CMBoundaryGroups DemoBoundaryGroup
        {
            SiteCode             = $SiteCode
            BoundaryGroup        = 'Contoso BoundaryGroup'
            Boundaries           = @(
                DSC_CMBoundaryGroupsBoundaries
                {
                    Value = '10.10.1.1-10.10.1.254'
                    Type  = 'IPRange'
                }
            )
            SiteSystemsToInclude = @($ServerName)
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[CMBoundaries]DemoBoundary'
        }

        CMAdministrativeUser SiteAdmins
        {
            SiteCode        = $SiteCode
            AdminName       = 'Contoso\SCCM-SiteAdmins'
            RolesToInclude  = 'Full Administrator'
            ScopesToInclude = 'All'
            Ensure          = 'Present'
            DependsOn       = '[Script]RebootAfterSccmSetup'
        }


        CMCollectionMembershipEvaluationComponent CollectionSettings
        {
            SiteCode             = $SiteCode
            EvaluationMins       = 5
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        CMStatusReportingComponent StatusReportingSettings
        {
            SiteCode                   = $SiteCode
            ClientLogChecked           = $false
            ClientLogFailureChecked    = $false
            ClientReportChecked        = $true
            ClientReportFailureChecked = $true
            ClientReportType           = 'AllMilestones'
            ServerLogChecked           = $false
            ServerLogFailureChecked    = $false
            ServerReportChecked        = $true
            ServerReportFailureChecked = $true
            ServerReportType           = 'AllMilestones'
            PsDscRunAsCredential       = $SccmInstallAccount
            DependsOn                  = '[Script]RebootAfterSccmSetup'
        }

        Registry MaxHWMifSize
        {
            Ensure    = 'Present'
            Key       = 'HKLM:\Software\Microsoft\SMS\Components\SMS_Inventory_Data_Loader'
            ValueName = 'Max MIF Size'
            ValueData = 500000000
            ValueType = 'Dword'
            DependsOn = '[Script]RebootAfterSccmSetup'
        }

        CMDistributionGroup DistroPtGroup
        {
            SiteCode             = $SiteCode
            DistributionGroup    = "$SiteCode - All Distribution Points"
            Ensure               = 'Present'
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        CMDistributionPoint DPRole
        {
            SiteCode                = $SiteCode
            SiteServerName          = $ServerName
            Description             = 'Standard Distribution Point'
            MinimumFreeSpaceMB      = 100
            BoundaryGroups          = @('Contoso BoundaryGroup')
            BoundaryGroupStatus     = 'Add'
            AllowPrestaging         = $false
            EnableAnonymous         = $true
            EnableBranchCache       = $true
            EnableLedbat            = $true
            ClientCommunicationType = 'Http'
            PsDscRunAsCredential    = $SccmInstallAccount
            DependsOn               = '[CMDistributionGroup]DistroPtGroup'
        }

        CMDistributionPointGroupMembers DPGroupMembers
        {
            SiteCode                    = $SiteCode
            DistributionPoint           = $ServerName
            DistributionGroupsToInclude = @("$SiteCode - All Distribution Points")
            PsDscRunAsCredential        = $SccmInstallAccount
            DependsOn                   = "[CMDistributionPoint]DPRole"
        }

        CMManagementPoint MPInstall
        {
            SiteCode             = $SiteCode
            SiteServerName       = $ServerName
            Ensure               = 'Present'
            GenerateAlert        = $true
            UseSiteDatabase      = $true
            UseComputerAccount   = $true
            PsDscRunAsCredential = $SccmInstallAccount
            DependsOn            = '[Script]RebootAfterSccmSetup'
        }

        CMSoftwareUpdatePoint SUPInstall
        {
            SiteCode                      = $SiteCode
            SiteServerName                = $ServerName
            ClientConnectionType          = 'Intranet'
            EnableCloudGateway            = $false
            UseProxy                      = $false
            UseProxyForAutoDeploymentRule = $false
            WsusIisPort                   = '8530'
            WsusIisSslPort                = '8531'
            WsusSsl                       = $false
            PsDscRunAsCredential          = $SccmInstallAccount
            DependsOn                     = '[Script]RebootAfterSccmSetup'
        }

        Script RebootAfterSCCMConfigurationInstall
        {
            TestScript = {
                return (Test-Path HKLM:\SOFTWARE\Microsoft\SMS\RebbotAfterConfiguration)
            }
            SetScript = {
                New-Item -Path HKLM:\SOFTWARE\Microsoft\SMS\RebbotAfterConfiguration -Force
                $global:DSCMachineStatus = 1
            }
            GetScript = { return @{result = 'result'}}
            DependsOn = $cmAccountsDependsOn,'[CMForestDiscovery]CreateForestDiscovery','[CMSystemDiscovery]CreateSystemDiscovery','[CMNetworkDiscovery]DisableNetworkDiscovery',
                '[CMHeartbeatDiscovery]CreateHeartbeatDiscovery','[CMUserDiscovery]CreateUserDiscovery','[CMClientStatusSettings]CreateClientStatusSettings',$cmSiteMaintenanceDependsOn,
                '[CMBoundaryGroups]DemoBoundaryGroup','[CMAdministrativeUser]SiteAdmins','[CMCollectionMembershipEvaluationComponent]CollectionSettings',
                '[CMStatusReportingComponent]StatusReportingSettings','[Registry]MaxHWMifSize','[CMDistributionPointGroupMembers]DPGroupMembers','[CMManagementPoint]MPInstall',
                '[CMSoftwareUpdatePoint]SUPInstall'
        }
    }
}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'Localhost'
            PSDscAllowDomainUser        = $true
            PSDscAllowPlainTextPassword = $true
        }
    )
}

$params = @{
    ServerName                = 'PR01.contoso.com'
    SiteCode                  = 'PRI'
    ConfigMgrVersion          = 1902
    SiteName                  = 'Contoso'
    DomainCredential          = Get-Credential -Username 'contoso\SCCM-CMInstall' -Message 'SCCM Install account'
    SqlServiceCredential      = Get-Credential -Username 'contoso\SCCM-SqlSvc' -Message 'SCCM SQL Service account'
    SqlAgentServiceCredential = Get-Credential -Username 'contoso\SCCM-SqlAgt' -Message 'SCCM SQL Agent account'
    SccmInstallAccount        = Get-Credential -Username 'contoso\SCCM-CMInstall' -Message 'SCCM Install account'
    CMAccounts                = @(
        Get-Credential -Username 'contoso\SCCM-Network' -Message 'SCCM Network Service account'
        Get-Credential -Username 'contoso\SCCM-ClientPush' -Message 'SCCM Client Push account'
        Get-Credential -Username 'contoso\SCCM-ADJoin' -Message 'SCCM AD Join account'
    )
}

PrimaryInstall -ConfigurationData $ConfigurationData -OutputPath C:\Temp\Primary @params
