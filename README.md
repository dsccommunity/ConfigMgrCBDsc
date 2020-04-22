# ConfigMgrCBDsc

This module contains DSC resources for the management and
configuration of Microsoft System Center Configuration Manager.

[![Build Status](https://dev.azure.com/dsccommunity/ConfigMgrCBDsc/_apis/build/status/dsccommunity.ConfigMgrCBDsc?branchName=master)](https://dev.azure.com/dsccommunity/ConfigMgrCBDsc/_build/latest?definitionId=23&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/ConfigMgrCBDsc/23/master)
[![codecov](https://codecov.io/gh/dsccommunity/ConfigMgrCBDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/dsccommunity/ConfigMgrCBDsc)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/ConfigMgrCBDsc/23/master)](https://dsccommunity.visualstudio.com/ConfigMgrCBDsc/_test/analytics?definitionId=23&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/ConfigMgrCBDsc?label=ConfigMgrCBDsc%20Preview)](https://www.powershellgallery.com/packages/ConfigMgrCBDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/ConfigMgrCBDsc?label=ConfigMgrCBDsc)](https://www.powershellgallery.com/packages/ConfigMgrCBDsc/)

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Resources

- **xSccmPreReqs**: Provides a composite resource to install ADK, ADK WinPE, MDT,
  required Windows Features, modify Local Administrators group, and create the
  no_sms_on_drive files.
- **xSccmSqlSetup**: Provides a composite resource to install SQL for SCCM.
- **xSccmInstall**: Provides a composite reosurce to install SCCM.
- **ClientSettings**: Provides a resource to perform configuration of client settings.
- **CMAccounts**: Provides a resource to manage Configuration Manager accounts.
- **SccmIniFile** This resource allows for the creation of the ini file
  used during the SCCM install, for CAS and Primary.

### xSccmPreReqs

- **[String] AdkSetupExePath** _(Required)_: Specifies the path and filename to
  the ADK Setup.
- **[String] AdkWinPeSetupPath** _(Required)_: Specifies the path and filename
  to the ADK WinPE Setup.
- **[String] MdtMsiPath** _(Required)_: Specifies the path and filename to the
  MDT Setup.
- **[String] InstallWindowsFeatures** : Specifies to install Windows Features
  needed for the SCCM install.
- **[String] LocalAdministrators** : Specifies the accounts and/or groups you
  want to add to the local administrators group.
- **[String] NoSmsOnDrives** : Specifies the drive letters of the drive you
  don't want SCCM to install on.
- **[PSCredential] DomainCredential** : Specifies credentials that have domain
  read permissions to add domain users or groups to the local administrators group.
- **[String] AdkProductName** : Specifies the Product Name for ADK.
  Default Value: 'Windows Assessment and Deployment Kit - Windows 10'
- **[String] AdkProductID** : Specifies the Product ID for ADK.
  Default Value: 'fb450356-9879-4b2e-8dc9-282709286661'
- **[String] AdkWinPeProductName** : Specifies the Product Name for  ADK WinPE.
  Default Value: 'Windows Assessment and Deployment Kit Windows Preinstallation
  Environment Add-ons - Windows 10'
- **[String] AdkWinPeProductID** : Specifies the Product ID for ADK WinPE.
  Default Value: 'd8369a05-1f4a-4735-9558-6e131201b1a2'
- **[String] AdkInstallPath** : Specifies the path to install ADK and ADK WinPE.
  Default Value: 'C:\Program Files (x86)\Windows Kits\10'
- **[String] MdtProductName** : Specifies the Product Name for MDT.
  Default Value: 'Microsoft Deployment Toolkit (6.3.8456.1000)'
- **[String] MdtProductID** : Specifies the Product ID for MDT.
  Default Value: '2E6CD7B9-9D00-4B04-882F-E6971BC9A763'
- **[String] MdtInstallPath** : Specifies the path to install MDT.
  Default Value: 'C:\Program Files\Microsoft Deployment Toolkit'

#### xSccmPreReqs Examples

- [SccmPreReqs](Source\Examples\Resources\xSccmPreReqs\SccmPreReqs.ps1)

### xSccmInstall

- **[String] SetupExePath** _(Required)_: Specifies the path to the setup.exe
  for SCCM.
- **[String] IniFile** _(Required)_: Specifies the path of the ini file, to include
  the filename.
- **[String] SccmServerType** _(Required)_: Specifies the SCCM Server type install,
  CAS or Primary.
  - Values: { CAS | Primary }
- **[PSCredential] SccmInstallAccount** _(Required)_: Specifies the credentials to
  use for the SCCM install.

#### xSccmInstall Examples

- [SccmInstall](Source\Examples\Resources\xSccmInstall\SccmInstall.ps1)

### xSccmSqlSetup

- **[String] SqlVersion** _(Required)_: Specify the version of SQL to be installed.
  - Values: { 2008 | 2008R2 | 2012 | 2014 | 2016 | 2017 | 2019 }
- **[String] SqlInstallPath** _(Required)_: Specifies the path to the setup.exe
  file for SQL.
- **[String] SqlInstanceName** _(Required)_: Specifies a SQL Server instance name.
- **[PSCredential] SqlServiceCredential** _(Required)_: Specifies the credential
  for the service account used to run the SQL Service.
- **[PSCredential] SqlAgentServiceCredential** _(Required)_: Specifies the
  credential for the service account used to run the SQL Agent Service.
- **[String] SqlSysAdminAccounts** _(Required)_: Use this parameter to provision
  logins to be members of the sysadmin role.
- **[String] InstallSharedDir** : Specifies the installation directory for
  64-bit shared components.
  Default Value: 'C:\Program Files\Microsoft SQL Server'
- **[String] InstallSharedWowDir** : Specifies the installation directory for
  32-bit shared components. Supported only on a 64-bit system.
  Default Value: 'C:\Program Files (x86)\Microsoft SQL Server'
- **[String] RSSvcStartupType** : Specifies the startup mode for Reporting Services.
  Default Value: 'Automatic'
- **[String] AgtSvcStartupType** : Specifies the startup mode for the SQL Server
  Agent service.
  Default Value: 'Automatic'
- **[String] RSInstallMode** : Specifies the Install mode for Reporting Services.
  Default Value: 'DefaultNativeMode'
- **[String] SqlCollation** : Specifies the collation settings for SQL Server.
  Default Value: 'SQL_Latin1_General_CP1_CI_AS'
- **[String] InstallSqlDataDir** : Specifies the data directory for SQL Server
  data files.
  Default Value: 'C:\'
- **[String] SqlUserDBDir** : Specifies the directory for the data
  files for user databases.
  Default Value: '<InstallSQLDataDir>\<SQLInstanceID>\MSSQL\Data'
- **[String] SqlUserDBLogDir** : Specifies the directory for the log
  files for user databases.
  Default Value: '<InstallSQLDataDir>\<SQLInstanceID>\MSSQL\Data'
- **[String] SqlTempDBDir** : Specifies the directory for the data
  files for tempdb.
  Default Value: '<InstallSQLDataDir>\<SQLInstanceID>\MSSQL\Data'
- **[String] SqlTempDBLogDir** : Specifies the directory for the log
  files for tempdb.
  Default Value: '<InstallSQLDataDir>\<SQLInstanceID>\MSSQL\Data'
- **[String] UpdateEnabled** : Specify whether SQL Server setup should discover
  and include product updates.
  Default Value: $false
- **[String] SqlPort** : Specifies the port SQL listens on.
  Default Value: 1433
- **[String] InstallManagementStudio** : Specify whether to install SQL
  Management Studio.
  Default Value: $false
- **[String] SqlManagementStudioExePath** : Specify that path and filename to
  the exe for Management Studio instal.
- **[String] SqlManagementStudioName** : Specify the name of SQL Server
  Management Studio.
  Default Value: 'SQL Server Management Studio'
- **[String] SqlManagementStudioProductId** : Specify the product if of the SQL
  Management Studio install being performed.
  Default Value: 'E3FD687D-6757-474B-8D83-5AA944B02C58'

#### xSccmSqlSetup Examples

- [SccmSqlSetup](Source\Examples\Resources\xSccmSqlSetup\SccmSqlSetup.ps1)

### ClientSettings

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] Name** _(Key)_: Specifies the display name of the client setting.
  package.
- **[String] DeviceSettingName** _(Key)_: Specifies the parent setting category.
  - Values include: { BackgroundIntelligentTransfer |ClientCache |
    ClientPolicy | Cloud | ComplianceSettings | ComputerAgent |
    ComputerRestart | DeliveryOptimization | EndpointProtection |
    HardwareInventory | MeteredNetwork | MobileDevice |
    NetworkAccessProtection | PowerManagement | RemoteTools | SoftwareCenter |
    SoftwareDeployment | SoftwareInventory | SoftwareMetering| SoftwareUpdates |
    StateMessaging | UserAndDeviceAffinity | WindowsAnalytics }
- **[String] Setting** _(Key)_: Specifies the client setting to validate.
- **[String] SettingValue** _(Required)_: Specifies the value for the setting.

#### ClientSettings Examples

- [ProvisionedPackages_Present](Source\Examples\Resources\ClientSettings\ClientSettings.ps1)

### CMAccounts

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] Account** _(Key)_: Specifies the Configuration Manager account name.
- **[PSCredential] AccountPassword** _(Write)_: Specifies the password of the
  account being added to Configuration Manager.
- **[String] Ensure** _(Write)_: Specifies whether the account is present or
  absent.
  - Values include: { Present | Absent }

#### CMAccounts Examples

- [CMAccounts_Absent](Source\Examples\Resources\CMAccounts\CMAccounts_Absent.ps1)
- [CMAccounts_Present](Source\Examples\Resources\CMAccounts\CMAccounts_Present.ps1)

### SCCMIniFile

- **IniFileName** _(Key)_: Specifies the ini file name.
- **IniFilePath** _(Key)_: Specifies the path of the ini file.
- **Action** _(Required)_: Specifies whether to install a CAS or Primary.
  - Values include: { InstallCAS | InstallPrimarySite }
- **CDLatest** _(Write)_: This value informs setup that you're using media from
  CD.Latest.
- **ProductID** _(Required)_: Specifies the Configuration Manager installation
  product key, including the dashes.
- **SiteCode** _(Required)_: Specifies three alphanumeric characters that
  uniquely identify the site in your hierarchy.
- **SiteName** _(Required)_: Specifies the name for this site.
- **SMSInstallDir** _(Required)_: Specifies the installation folder for the
  Configuration Manager program files.
- **SDKServer** _(Required)_: Specifies the FQDN for the server that will host
  the SMS Provider.
- **PreRequisiteComp** _(Required)_: Specifies whether setup prerequisite files
  have already been downloaded.
- **PreRequisitePath** _(Required)_: Specifies the path to the setup
  prerequisite files.
- **AdminConsole** _(Required)_: Specifies whether to install the Configuration
  Manager console.
- **JoinCeip** _(Required)_: Specifies whether to join the Customer Experience
  Improvement Program (CEIP).
- **MobileDeviceLanguage** _(Required)_: Specifies whether the mobile device
  client languages are installed.
- **RoleCommunicationProtocol** _(Write)_: Specifies whether to configure all
  site systems to accept only HTTPS communication from clients, or to configure
  the communication method for each site system role.
  - Values include: { EnforceHTTPS | HTTPorHTTPS }
- **ClientsUsePKICertificate** _(Write)_: Specifies whether clients will use a
  client PKI certificate to communicate with site system roles.
- **ManagementPoint** _(Write)_: Specifies the FQDN of the server that will
  host the management point site system role.
- **ManagementPointProtocol** _(Write)_: Specifies the protocol to use for the
  management point.
  - Values include: { HTTPS | HTTP }
- **DistributionPoint** _(Write)_: Specifies the FQDN of the server that will
  host the distribution point site system role.
- **DistributionPointProtocol** _(Write)_: Specifies the protocol to use for the
  distribution point.
  - Values include: { HTTPS | HTTP }
- **AddServerLanguages** _(Write)_: Specifies the server languages that will be
  available for the Configuration Manager console, reports, and Configuration
    Manager objects.
  - Values include: { DEU | FRA | RUS | CHS | JPN | CHT | CSY | ESN | HUN | ITA |
    KOR | NLD | PLK | PTB | PTG | SVE | TRK | ZHH }
- **AddClientLanguages** _(Write)_: Specifies the languages that will be
  available to client computers.
  - Values include: { DEU | FRA | RUS | CHS | JPN | CHT | CSY | ESN | HUN | ITA |
    KOR | NLD | PLK | PTB | PTG | SVE | TRK | ZHH }
- **DeleteServerLanguages** _(Write)_: Modifies a site after it's installed.
  Specifies the languages to remove, and which will no longer be available for the
  Configuration Manager console, reports, and Configuration Manager objects.
  - Values include: { DEU | FRA | RUS | CHS | JPN | CHT | CSY | ESN | HUN | ITA |
    KOR | NLD | PLK | PTB | PTG | SVE | TRK | ZHH }
- **DeleteClientLanguages** _(Write)_: Modifies a site after it's installed.
  Specifies the languages to remove, and which will no longer be available to
  client computers.
  - Values include: { DEU | FRA | RUS | CHS | JPN | CHT | CSY | ESN | HUN | ITA |
    KOR | NLD | PLK | PTB | PTG | SVE | TRK | ZHH }
- **SQLServerName** _(Required)_: Specifies the name of the server or clustered
  instance that's running SQL Server to host the site database.
- **DatabaseName** _(Required)_: Specifies the name of the SQL Server database
  to create, or the SQL Server database to use, when setup installs the CAS
  database. This can also include the instance, instance\<DatabaseName>.
- **SqlSsbPort** _(Write)_: Specifies the SQL Server Service Broker (SSB) port
  that SQL Server uses.
- **SQLDataFilePath** _(Write)_: Specifies an alternate location to create the
  database .mdb file.
- **SQLLogFilePath** _(Write)_: Specifies an alternate location to create the
  database .ldf file.
- **CCARSiteServer** _(Write)_: Specifies the CAS that a primary site attaches
  to when it joins the Configuration Manager hierarchy.
- **CasRetryInterval** _(Write)_: Specifies the retry interval in minutes to
  attempt a connection to the CAS after the connection fails.
- **WaitForCasTimeout** _(Write)_: Specifies the maximum timeout value in
  minutes for a primary site to connect to the CAS.
- **CloudConnector** _(Required)_: Specifies the FQDN of the server that will
  host the service connection point site system role.
- **CloudConnectorServer** _(Write)_: Specifies the FQDN of the server that will
  host the service connection point site system role.
- **UseProxy** _(Write)_: Specifies whether the service connection point uses a
  proxy server.
- **ProxyName** _(Write)_: Specifies the FQDN of the proxy server that the
  service connection point uses.
- **ProxyPort** _(Write)_: Specifies the port number to use for the proxy port.
- **SAActive** _(Write)_: Specify if you have active Software Assurance.
- **CurrentBranch** _(Write)_: Specify whether to use Configuration Manager current
  branch or long-term servicing branch (LTSB).

#### SccmIniFile Examples

- [SccmIniFile_CAS](Source\Examples\Resources\SccmIniFile\SccmIniFile_CAS.ps1)
- [SccmIniFile_Primary](Source\Examples\Resources\SccmIniFile\SccmIniFile_Primary.ps1)