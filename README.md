# ConfigMgrCBDsc

This module contains DSC resources for the management and
configuration of Microsoft System Center Configuration Manager Current Branch (ConfigMgrCB).

Current Branch starts after System Center 2012 with version 1511 [Configuration Manager CurrentBranch](https://docs.microsoft.com/en-us/mem/configmgr/core/plan-design/changes/what-has-changed-from-configuration-manager-2012).

Starting with version 1910 Configuration Manager is now part of [Microsoft Endpoint Manager](https://docs.microsoft.com/en-us/mem/configmgr/core/understand/introduction).

This module has been tested on the following versions:

- Configuration Manager 2006
- Configuration Manager 2002
- Configuration Manager 1906
- Configuration Manager 1902

**Note**

ConfigMgrCBDsc module uses the ConfigurationManager module that is installed with
Configuration Manager.  In order to use this module, the site needs to be
registered and the certificate needs to be in the Trusted Publishers store.
Import-ConfigMgrPowerShellModule, adds keys to the HKEY_Users hive and imports
the signing certificate from the ConfigurationManager.psd1 to allow the module
to function, as either LocalSystem, or PSDscRunAsCredential specified.

This occurs in Get, Test, and Set. The function that is called in the resources
is Import-ConfigMgrPowerShellModule.

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
- **CMIniFile** This resource allows for the creation of the ini file
  used during the SCCM install, for CAS and Primary.
- **CMCollections**: Provides a resource for creating collections and collection
  queries, direct, and exclude membership rules.
- **CMBoundaries**: Provides a resource for creating and removing boundaries.
- **CMForestDiscovery**: Provides a resource to manage the Configuration Manager
  AD Forest Discovery method.
- **CMClientStatusSettings**: Provides a resource for modifying configuration
  manager client status settings.
- **CMBoundariesGroup**: Provides a resource for creating boundary groups and
  adding boundaries to the groups.
- **CMManagementPoint**: Provides a resource for creating and removing
  management points.
- **CMAssetIntelligencePoint**: Provides a resource for creating and managing
  the SCCM Asset Intelligence Synchronization Point role.
- **CMFallbackStatusPoint**: Provides a resource for creating and managing
  the SCCM Fallback Status Point role.
- **CMSoftwareUpdatePoint**: Provides a resource for creating and managing
  the SCCM Software Update Point role.
- **CMDistributionPoint**: Provides a resource for creating and managing
  the distribution point role.
- **CMHeartbeatDiscovery**: Provides a resource to manage the Configuration Manager
  Heartbeat Discovery method.
- **CMSystemDiscovery**: Provides a resource to manage the Configuration Manager
  System Discovery method.
- **CMNetworkDiscovery**: Provides a resource to manage the Configuration Manager
  Network Discovery method.
- **CMServiceConnectionPoint**: Provides a resource for creating and managing
  the SCCM Service Connection Point role.
- **CMReportingServicePoint**: Provides a resource for creating and managing
  the SCCM Reporting Service Point role.
- **CMPxeDistributionPoint**: Provides a resource for modifying a distribution point
  to changing to a PXE enabled distribution point.
- **CMPullDistributionPoint**: Provides a resource for modifying a distribution point
  and making the distribution point a Pull Distribution Point.
- **CMSiteMaintenance**: Provides a resource for modifying the Site Maintenance tasks.
- **CMAdministrativeUser**:  Provides a resource for adding, removing, and configuring
  administrative users.
- **CMDistributionGroup**: Provides a resource for creating Distribution Point
  Groups and adding Distribution Points to the group.
- **CMSiteSystemServer**: Provides a resource for adding and modifying a Site
  System Server and its properties.
- **CMStatusReportingComponent**: Provides a resource for modifying the Status
  Reporting Component and its properties.
- **CMCollectionMembershipEvaluationComponent**: Provides a resource for modifying
  the SCCM Collection Membership Evaluation Component.
- **CMDistributionPointGroupMembers**: Provides a resource for adding Distribution
  Groups to Distribution Points. This resource will not create Distribution Points
  or Distribution Groups.
- **CMSecurityScopes**: Provides a resource for adding and removing Security
  Scopes.  Note: If the Security Scope is currently in use and assigned, DSC will
  not remove the Security Scope.
- **CMUserDiscovery**: Provides a resource to manage the Configuration Manager
  User Discovery method.
- **CMSecurityRoles**: Provides a resource for adding and removing Security
  Roles.  Note: If the Security Role is currently assigned to an administrator,
  DSC will not remove the Security Role.
- **CMClientPushSettings**: Provides a resource for modifying client push
  settings.  Note: EnableSystemTypeConfigurationManager, EnableSystemTypeServer,
  EnableSystemTypeWorkstation can not be configured if client push is disabled.

### xSccmPreReqs

- **[Boolean] InstallADK** : Specifies whether to install ADK.
  Default Value: $true
- **[Boolean] InstallMDT** : Specifies whether to install MDT.
- **[String] AdkSetupExePath** : Specifies the path and filename to
  the ADK Setup.
- **[String] AdkWinPeSetupPath** : Specifies the path and filename
  to the ADK WinPE Setup.
- **[String] MdtMsiPath** : Specifies the path and filename to the
  MDT Setup.
- **[String] InstallWindowsFeatures** : Specifies to install Windows Features
  needed for the SCCM install.
- **[String[]] SccmRole** : Specifies the SCCM Roles that will be on the server.
  Default Value: CASorSiteServer
  - Values{CASorSiteServer | AssetIntelligenceSynchronizationPoint |
    CertificateRegistrationPoint | DistributionPoint | EndpointProtectionPoint |
    EnrollmentPoint | EnrollmentProxyPoint | FallbackServicePoint |
    ManagementPoint | ReportingServicesPoint | ServiceConnectionPoint |
    StateMigrationPoint | SoftwareUpdatePoint}
- **[Boolean] AddWindowsFirewallRule** : Specifies whether to add the Windows
  Firewall Rules needed for the install.
  Default Value: $false
- **[String] WindowsFeatureSource** : Specifies the source that will be used
  to install windows features if the files are not present in the local
  side-by-side store.
- **[String[]] FirewallProfile** : Specifies the Windows Firewall profile for
  the rules to be added.
- **[String[]] FirewallTcpLocalPort** : Specifies the TCP ports to be added to
  the windows firewall as allowed.
  Default Value: @('1433','1434','4022','445','135','139','49154-49157')
- **[String[]] FirewallUdpLocalPort** : Specifies the UDP ports to be added to
  the windows firewall as allowed.
  Default Value: @('137-138','1434','5355')
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

**Note**

If you installed SCCM on version 1906 or earlier, the registry key on the SCCM
server won't change on upgrade and you won't need to change the version here if
you are using apply and auto correct.

- **[String] SetupExePath** _(Required)_: Specifies the path to the setup.exe
  for SCCM.
- **[String] IniFile** _(Required)_: Specifies the path of the ini file, to include
  the filename.
- **[String] SccmServerType** _(Required)_: Specifies the SCCM Server type install,
  CAS or Primary.
  - Values: { CAS | Primary }
- **[PSCredential] SccmInstallAccount** _(Required)_: Specifies the credentials to
  use for the SCCM install.
- **[UInt32] Version** _(Required)_: Specifies the version of SCCM that will be installed.

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
- **[String]** : SQL features to install.
  Default Value: 'SQLENGINE,RS,CONN,BC,SSMS,ADV_SSMS'
- **[String] InstallSharedDir** : Specifies the installation directory for
  64-bit shared components.
  Default Value: 'C:\Program Files\Microsoft SQL Server'
- **[String] InstallSharedWowDir** : Specifies the installation directory for
  32-bit shared components. Supported only on a 64-bit system.
  Default Value: 'C:\Program Files (x86)\Microsoft SQL Server'
- **[String] InstanceDir** : Specifies the installation path for SQL Server
  instance files.
  Default Value: 'C:\Program Files\Microsoft SQL Server'
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
- **[Uint32] SqlTempdbFileCount** : Specficies the count of TempDB Files
  to use. (only sql server 2016 and above)
  Default Value: 1
- **[Uint32] SqlTempdbFileSize** : Specifies the initial size (MB) of
  the TempDb Files. (only sql server 2016 and above)
  Default Value: 8
- **[Uint32] SqlTempdbFileGrowth** : Specifies the size (MB) in which
  the TempDb files growth. (only sql server 2016 and above)
  Default Value: 64
- **[Uint32] SqlTempdbLogFileSize** : Specifies the TempDb Log File
  size (MB). (only sql server 2016 and above)
  Default Value: 8
- **[Uint32] SqlTempdbLogFileGrowth** : Specifies the size (MB) in which
  the TempDb Log File growth. (only sql server 2016 and above)
  Default Value: 64
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
- [SccmSqlSetupandManagemenStudio](Source\Examples\Resources\xSccmSqlSetup\SccmSqlSetupAndManagementStudio.ps1)

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

### CMIniFile

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
- **DistributionPointInstallIis** _(Write)_: Specifies whether to install the
  IIS features when installing the Distribution Point.
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

#### CMIniFile Examples

- [CMIniFile_CAS](Source\Examples\Resources\CMIniFile\CMIniFile_CAS.ps1)
- [CMIniFile_Primary](Source\Examples\Resources\CMIniFile\CMIniFile_Primary.ps1)

### CMCollections

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] CollectionName** _(Key)_: Specifies the name of the collection.
- **[String] CollectionType** _(Key)_: Specifies the type of collection.
  { User | Device }.
- **[String] LimitingCollectionName** _(Write)_: Specifies the name of a
  collection to use as the default scope for this collection.
- **[String] Comment** _(Write)_: Specifies a comment for the collection.
- **[EmbeddedInstance] RefreshSchedule** _(Write)_: Specifies containing refresh
  schedule for Configuration Manager (RecurInterval, RecurCount).
- **[String] RefreshType** _(Key)_: Specifies how the collection is refreshed.
  { Manual | Periodic | Continuous | Both }.
- **[EmbeddedInstance] QueryRules[]** _(Write)_: Specifies the name of the rule
  and the query expression that Configuration Manager uses to update collections.
- **[String] ExcludeMembership[]** _(Write)_: Specifies the collection name to
  exclude members from.
- **[String] DirectMembership[]** _(Write)_: Specifies the resource id for the
  direct membership rule.
- **[String] Ensure** _(Write)_: Specifies status of the collection is to be
  present or absent.
  - Values include: { Present | Absent }

#### CMCollections Examples

- [CMCollections_Absent](Source\Examples\Resources\CMCollections\Collection_Absent.ps1)
- [CMDeviceCollection_Present](Source\Examples\Resources\CMCollections\DeviceCollection_Present.ps1)
- [CMUserCollection_Present](Source\Examples\Resources\CMCollections\UserCollection_Present.ps1)

### CMBoundaries

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] Value** _(Key)_: Specifies the value for the boundary.
- **[String] DisplayName** _(Required)_: Specifies the display name of the boundary.
- **[String] Type** _(Required)_: Specifies the type of boundary.
  - Values include: { ADSite | IPSubnet | IPRange
- **[String] Ensure** _(Write)_: Specifies whether the boundary is present or
  absent.
  - Values include: { Present | Absent }
- **[String] BoundaryID** _(Read)_: Specifies the boundary id.

#### CMBoundaries Examples

- [CMBoundaries_Absent](Source\Examples\Resources\CMBoundaries\CMBoundaries_Absent.ps1)
- [CMBoundaries_Present](Source\Examples\Resources\CMBoundaries\CMBoundaries_Present.ps1)

### CMForestDiscovery

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[Boolean] Enabled** _(Required)_: Specifies the enablement of the forest
  discovery method. If settings is set to $false no other value provided will be
  evaluated for compliance.
- **[Boolean] EnableActiveDirectorySiteBoundaryCreation** _(Write)_: Indicates
  whether Configuration Manager creates Active Directory boundaries from AD DS
  discovery information.
- **[Boolean] EnableSubnetBoundaryCreation** _(Write)_: Indicates whether
  Configuration Manager creates IP address range boundaries from AD DS discovery
  information.
- **[String] ScheduleInterval** _(Write)_: Specifies the time when the scheduled
  event recurs in hours and days.
  - Values include: { Hours | Days }
- **[String] ScheduleCount** _(Write)_: Specifies how often the recur interval
  is run. If hours are specified the max value is 23. Anything over 23 will result
  in 23 to be set. If days are specified the max value is 31. Anything over 31 will
  result in 31 to be set.

#### CMForestDiscovery Examples

- [ForestDiscovery_Disabled](Source\Examples\Resources\CMForestDiscovery\ForestDiscovery_Disabled.ps1)
- [ForestDiscovery_Enabled](Source\Examples\Resources\CMForestDiscovery\ForestDiscovery_Enabled.ps1)

### CMClientStatusSettings

- **[String] IsSingleInstance** _(Key)_:  Specifies the resource is a single
  instance, the value must be 'Yes'.
  { Yes }.
- **[String] SiteCode** _(Required)_: Specifies the Site Code for the Configuration
  Manager site.
- **[UInt32] ClientPolicyDays** _(Write)_: Specifies the data collection
  interval for client policy client monitoring activities.
- **[UInt32] HeartbeatDiscoveryDays** _(Write)_: Specifies the data collection
  interval for heartbeat discovery client monitoring activities.
- **[UInt32] SoftwareInventoryDays** _(Write)_: Specifies the data collection
  interval for software inventory client monitoring activities.
- **[UInt32] HardwareInventoryDays** _(Write)_: Specifies the data collection
  interval for hardware inventory client monitoring activities.
- **[UInt32] StatusMessageDays** _(Write)_: Specifies the data collection
  interval for status message client monitoring activities.
- **[UInt32] HistoryCleanupDays** _(Write)_: Specifies the data collection
  interval for status history cleanup client monitoring activities.

#### CMClientStatusSettings Examples

- [CMClientStatusSettings](Source\Examples\Resources\CMClientStatusSettings\CMClientStatusSettings.ps1)

### CMBoundaryGroups

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] BoundaryGroup** _(Key)_: Specifies the name of the Boundary Group.
- **[EmbeddedInstance] Boundaries** _(Write)_: Specifies an array of Boundaries
  to add or remove from the Boundary Group.
- **[String] BoundaryAction** _(Write)_: Specifies the Boundaries are to match,
  add, or remove Boundaries from the Boundary Group
  - Values include: { Match | Add | Remove }
- **[String] SiteSystems[]** _(Write): Specifies an array of Site Systems to match
  for the Boundary Group.
- **[String] SiteSystemsToInclude[]** _(Write): Specifies an array of Site Systems
  to add to the Boundary Group.
- **[String] SiteSystemsToExclude[]** _(Write): Specifies an array of Site Systems
  to remove from the Boundary Group.
- **[String] SecurityScopes[]** _(Write): Specifies an array of Security Scopes
  to match for the Boundary Group.
- **[String] SecurityScopesToInclude[]** _(Write): Specifies an array of Security
  Scopes to add to the Boundary Group.
- **[String] SecurityScopesToExclude[]** _(Write): Specifies an array of Security
  Scopes to remove from the Boundary Group.
- **[String] Ensure** _(Write)_: Specifies status of the Boundary Group is to be
  present or absent.
  - Values include: { Present | Absent }

#### CMBoundaryGroups Examples

- [CMBoundaryGroups_Absent](Source\Examples\Resources\CMBoundaryGroups\CMBoundaryGroups_Absent.ps1)
- [CMBoundaryGroups_Present](Source\Examples\Resources\CMBoundaryGroups\CMBoundaryGroups_Present.ps1)
- [CMBoundaryGroups_Include](Source\Examples\Resources\CMBoundaryGroups\CMBoundaryGroups_Include.ps1)
- [CMBoundaryGroups_Exclude](Source\Examples\Resources\CMBoundaryGroups\CMBoundaryGroups_Exclude.ps1)

### CMManagementPoint

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SiteServerName** _(Key)_: Specifies the SiteServer to install the
  role on.
- **[String] SqlServerFqdn** _(Write)_: Specifies the SQL server FQDN if using
  a SQL replica.
- **[String] DatabaseName** _(Write)_: Specifies the name of the site
  database\replica that the management point uses.
- **[String] ClientConnectionType** _(Write)_: Specifies the type of the client connection.
  - Values include: { Internet | Intranet | InternetAndIntranet }
- **[Boolean] EnableCloudGateway** _(Write)_: Specifies if a cloud gateway
  is to be used for the management point.
- **[Boolean] EnableSsl** _(Write)_: Specifies whether to enable SSL (HTTPS)
  traffic to the management point.
- **[Boolean] GenerateAlert** _(Write)_: Indicates whether the management point
  generates health alerts.
- **[Boolean] UseSiteDatabase** _(Write)_: Indicates whether the management point
  queries a site database.
- **[Boolean] UseComputerAccount** _(Write)_: Indicates that the management point
  uses its own computer account.
- **[String] SqlServerInstanceName** _(Write)_: Specifies the name of the SQL Server
  instance that clients use to communicate with the site system.
- **[String] Username** _(Write)_: Specifies user account the management point
  uses to access site information.
- **[String] Ensure** _(Write)_: Specifies whether the management point is
  present or absent.
  - Values include: { Present | Absent }

#### CMManagementPoint Examples

- [CMManagementPoint_Absent](Source\Examples\Resources\CMManagementPoint\CMManagementPoint_Absent.ps1)
- [CMManagementPoint_Present](Source\Examples\Resources\CMManagementPoint\CMManagementPoint_Present.ps1)
- [CMManagementPoint_UseDatabase_Present](Source\Examples\Resources\CMManagementPoint\CMManagementPoint_UseDatabase_Present.ps1)

### CMAssetIntelligencePoint

- **[String] IsSingleInstance** _(Key)_:  Specifies the resource is a single
  instance, the value must be 'Yes'.
  { Yes }.
- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SiteServerName** _(Required)_: Specifies the Site Server to install
  or configure the role on. If the role is already installed on another server
  this setting will be ignored.
- **[String] CertificateFile** _(Write)_: Specifies the path to a System Center
  Online authentication certificate (.pfx) file. If used, this must be in UNC
  format. Local paths are not allowed. Mutually exclusive with the
  RemoveCertificate parameter.
- **[EmbeddedInstance] Schedule** _(Write)_: Specifies when the asset
  intelligence catalog is synchronized. (RecurInterval, RecurCount)
- **[Boolean] Enable** _(Write)_: Specifies whether the installed asset
  intelligence role is enabled or disabled.
- **[Boolean] EnableSynchronization** _(Write)_: Specifies whether to
  synchronize the asset intelligence catalog.
- **[Boolean] RemoveCertificate** _(Write)_: Specifies whether to remove a
  configured certificate file. Mutually exclusive with the CertificateFile Parameter.
- **[String] Ensure** _(Write)_: Specifies whether the asset intelligence
  synchronization point is present or absent.
  - Values include: { Present | Absent }

#### CMAssetIntelligencePoint Examples

- [CMAssetIntelligencePoint_Absent](Source\Examples\Resources\CMAssetIntelligencePoint\CMAssetIntelligencePoint_Absent.ps1)
- [CMAssetIntelligencePoint_Present](Source\Examples\Resources\CMAssetIntelligencePoint\CMAssetIntelligencePoint_Present.ps1)

### CMFallbackStatusPoint

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SiteServerName** _(Key)_: Specifies the Site Server to install
  or configure the role on.
- **[UInt32] StateMessageCount** _(Write)_: Specifies the number of state messages
  that a fallback status point can send to Configuration Manager within a throttle
  interval.
- **[UInt32] ThrottleSec** _(Write)_: Specifies the throttle interval in seconds.
- **[String] Ensure** _(Write)_: Specifies whether the fallback status point is
  present or absent.
  - Values include: { Present | Absent }

#### CMFallbackStatusPoint Examples

- [CMFallbackStatusPoint_Absent](Source\Examples\Resources\CMFallbackStatusPoint\CMFallbackStatusPoint_Absent.ps1)
- [CMFallbackStatusPoint_Present](Source\Examples\Resources\CMFallbackStatusPoint\CMFallbackStatusPoint_Present.ps1)

### CMSoftwareUpdatePoint

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SiteServerName** _(Key)_: Specifies the Site Server to install
  or configure the role on.
- **[Boolean] AnonymousWsusAccess** _(Write)_: Indicates that the software update
  point allows anonymous access. Mutually exclusive with WsusAccessAccount.
- **[String] ClientConnectionType** _(Write)_: Specifies the type of the client connection.
  - Values include: { Internet | Intranet | InternetAndIntranet }
- **[Boolean] EnableCloudGateway** _(Write)_: Specifies if a cloud gateway is to
  be used for the software update point. When enabling the cloud gateway, the
  client connectiontype must be either Internet or InterneAndIntranet. When
  enabling the cloud gateway, SSL must be enabled.
- **[Boolean] UseProxy** _(Write)_: Indicates whether a software update point
  uses the proxy configured for the site system server.
- **[Boolean] UseProxyForAutoDeploymentRule** _(Write)_: Indicates whether an
  auto deployment rule can use a proxy.
- **[String] WsusAccessAccount** _(Write)_: Specifies an account used to connect
  to the WSUS server. When not used, specify the AnonymousWsusAccess parameter.
- **[UInt32] WsusIisPort** _(Write)_: Specifies a port to use for unsecured
  access to the Wsus server.
- **[UInt32] WsusIisSslPort** _(Write)_: Specifies a port to use for secured
  access to the Wsus server.
- **[Boolean] WsusSsl** _(Write)_: Specifies whether the software update point
  uses SSL to connect to the Wsus server.
- **[String] Ensure** _(Write)_: Specifies whether the software update point is
  present or absent.
  - Values include: { Present | Absent }

#### CMSoftwareUpdatePoint Examples

- [CMSoftwareUpdatePoint_Absent](Source\Examples\Resources\CMSoftwareUpdatePoint\CMSoftwareUpdatePoint_Absent.ps1)
- [CMSoftwareUpdatePoint_CMG](Source\Examples\Resources\CMSoftwareUpdatePoint\CMSoftwareUpdatePoint_CMG.ps1)
- [CMSoftwareUpdatePoint_Present](Source\Examples\Resources\CMSoftwareUpdatePoint\CMSoftwareUpdatePoint_Present.ps1)

### CMDistributionPoint

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SiteServerName** _(Key)_: Specifies the SiteServer to install the role.
- **[String] Description** _(Write)_: Specifies a description for the
  distribution point.
- **[UInt32] MinimumFreeSpaceMB** _(Write)_: Specifies the amount of free space
  to reserve on each drive used by this distribution point.
  Only used when distribution point is not currently installed.
- **[String] PrimaryContentLibraryLocation** _(Write)_: Specifies the primary
  content location. Configuration Manager copies content to the primary content location
  until the amount of free space reaches the value that you specified.
  Only used when distribution point is not currently installed.
- **[String] SecondaryContentLibraryLocation** _(Write)_: Specifies the
  secondary content location.
  Only used when distribution point is not currently installed.
- **[String] PrimaryPackageShareLocation** _(Write)_: Specifies the primary
  package share location. Configuration Manager copies content to the primary package
  share location until the amount of free space reaches the value that you specified.
  Only used when distribution point is not currently installed.
- **[String] SecondaryPackageShareLocation** _(Write)_: Specifies the secondary
  package share location.
  Only used when distribution point is not currently installed.
- **[DateTime] CertificateExpirationTimeUtc** _(Write)_: Specifies, in UTC format,
  the date and time when the certificate expires.
  Only used when distribution point is not currently installed.
- **[String] ClientCommunicationType** _(Write)_: Specifies protocol clients or devices
  communicate with the distribution point.
  - Values include: { Http | Https }
- **[String] BoundaryGroups[]** _(Write)_: Specifies an array of existing boundary
  groups by name.
- **[String] BoundaryGroupStatus** _(Write)_: Specifies if the boundary group is
  to be added, removed, or match BoundaryGroups.
  - Values include: { Add | Remove | Match }
- **[Boolean] AllowPreStaging** _(Write)_: Indicates whether the distribution point
  is enabled for prestaged content.
- **[Boolean] EnableAnonymous** _(Write)_: Indicates that the distribution point
  permits anonymous connections from Configuration Manager clients
  to the content library.
- **[Boolean] EnableBranchCache** _(Write)_: Indicates that clients that use Windows
  BranchCache are allowed to download content from an on-premises
  distribution point
- **[Boolean] EnableLedbat** _(Write)_: Indicates whether to adjust the download
  speed to use the unused network Bandwidth or Windows LEDBAT.
- **[String] Ensure** _(Write)_: Specifies if the DP is to be present or absent.
  - Values include: { Absent | Present }

#### CMDistributionPoint Examples

- [CMDistributionPoint_Absent](Source\Examples\Resources\CMDistributionPoint\CMDistributionPoint_Absent.ps1)
- [CMDistributionPoint_Present](Source\Examples\Resources\CMDistributionPoint\CMDistributionPoint_Present.ps1)

### CMHeartbeatDiscovery

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[Boolean] Enabled** _(Required)_: Specifies the enablement of the heartbeat
  discovery method. If settings is set to $false no other value provided will be
  evaluated for compliance.
- **[String] ScheduleInterval** _(Write)_: Specifies the time when the scheduled
  event recurs in hours and days.
  - Values include: { Hours | Days }
- **[String] ScheduleCount** _(Write)_: Specifies how often the recur interval
  is run. If hours are specified the max value is 23. Anything over 23 will result
  in 23 to be set. If days are specified the max value is 31. Anything over 31 will
  result in 31 to be set.

#### CMHeartbeatDiscovery Examples

- [CMHeartbeatDiscovery_Disabled](Source\Examples\Resources\CMHeartbeatDiscovery\CMHeartbeatDiscovery_Disabled.ps1)
- [CMHeartbeatDiscovery_Enabled](Source\Examples\Resources\CMHeartbeatDiscovery\CMHeartbeatDiscovery_Enabled.ps1)

### CMNetworkDiscovery

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[Boolean] Enabled** _(Required)_: Specifies the enablement of the network
  discovery method.

#### CMNetworkDiscovery Examples

- [CMNetworkDiscovery_Disabled](Source\Examples\Resources\CMNetworkDiscovery\CMNetworkDiscovery_Disabled.ps1)
- [CMNetworkDiscovery_Enabled](Source\Examples\Resources\CMNetworkDiscovery\CMNetworkDiscovery_Enabled.ps1)

### CMSystemDiscovery

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[Boolean] Enabled** _(Key)_: Specifies the enablement of the system
  discovery method. If settings is set to $false no other value provided will be
  evaluated for compliance.
- **[Boolean] EnableDeltaDiscovery** _(Write)_: Indicates whether Configuration
  Manager discovers resources created or modified in AD DS since the last
  discovery cycle.
- **[UInt32] DeltaDiscoveryMins** _(Write)_: Specifies the number of minutes for
  the delta discovery.
- **[Boolean] EnableFilteringExpiredLogon** _(Write)_: Indicates whether Configuration
  Manager discovers only computers that have logged onto a domain within a specified
  number of days.
- **[UInt32] TimeSinceLastLogonDays** _(Write)_: Specify the number of days for EnableFilteringExpiredLogon.
- **[Boolean] EnableFilteringExpiredPassword** _(Write)_: Indicates whether Configuration
  Manager discovers only computers that have updated their computer account password
  within a specified number of days.
- **[UInt32] TimeSinceLastPasswordUpdateDays** _(Write)_: Specify the number of days
  for EnableFilteringExpiredPassword.
- **[String] ADContainers[]** _(Write)_: Specifies an array of names of Active Directory
  containers to match to the discovery.
- **[String] ADContainersToInclude[]** _(Write)_: Specifies an array of names of
  Active Directory containers to add to the discovery.
- **[String] ADContainersToExclude[]** _(Write)_: Specifies an array of names of
  Active Directory containers to exclude to the discovery.
- **[String] ScheduleInterval** _(Write)_: Specifies the time when the scheduled
  event recurs in hours and days.
  - Values include: { None| Days| Hours | Minutes }
- **[UInt32] ScheduleCount** _(Write)_: Specifies how often the recur interval
  is run. If hours are specified the max value is 23. Anything over 23 will result
  in 23 to be set. If days are specified the max value is 31. Anything over 31 will
  result in 31 to be set.

#### CMSystemDiscovery Examples

- [CMSystemDiscovery_Disabled](Source\Examples\Resources\CMSystemDiscovery\CMSystemDiscovery_Disabled.ps1)
- [CMSystemDiscovery_Enabled](Source\Examples\Resources\CMSystemDiscovery\CMSystemDiscovery_Enabled.ps1)
- [CMSystemDiscovery_Exclude](Source\Examples\Resources\CMSystemDiscovery\CMSystemDiscovery_Exclude.ps1)
- [CMSystemDiscovery_Include](Source\Examples\Resources\CMSystemDiscovery\CMSystemDiscovery_Include.ps1)
- [CMSystemDiscovery_ScheduleNone](Source\Examples\Resources\CMSystemDiscovery\CMSystemDiscovery_ScheduleNone.ps1)

### CMServiceConnectionPoint

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SiteServerName** _(Required)_: Specifies the Site Server to install
  or configure the role on.
- **[String] Mode** _(Write)_: Specifies a mode for the service connection point.
  - Values include: { Online | Offline }
- **[String] Ensure** _(Write)_: Specifies whether the service connection point
  is present or absent.
  - Values include: { Absent | Present }

#### CMServiceConnectionPoint Examples

- [CMServiceConnectionPoint_Absent](Source\Examples\Resources\CMServiceConnectionPoint\CMServiceConnectionPoint_Absent.ps1)
- [CMServiceConnectionPoint_Present](Source\Examples\Resources\CMServiceConnectionPoint\CMServiceConnectionPoint_Present.ps1)

### CMReportingServicePoint

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SiteServerName** _(Key)_: Specifies the Site Server to install
  or configure the role on.
- **[String] DatabaseName** _(Write)_: Specifies the name of the Configuration
  Manager database that you want to use as the data source for reports from Microsoft
  SQL Server Reporting Services.
- **[String] DatabaseServerName** _(Write)_: Specifies the name of the Configuration
  Manager database server that you want to use as the data source for reports from
  Microsoft SQL Server Reporting Services.
  To specify a database instance, use the format Server Name\Instance Name.
- **[String] FolderName** _(Write)_: Specifies the name of the report folder on
  the report server. This parameter can only be used when installing the role.
- **[String] ReportServerInstance** _(Write)_: Specifies the name of an instance
  of Microsoft SQL Server Reporting Services. This parameter can only be used
  when installing the role.
- **[String] Username** _(Write)_: Specifies a Username for an account that
  Configuration Manager uses to connect with Microsoft SQL Server Reporting Services
  and that gives this user access to the site database.
- **[String] Ensure** _(Write)_: Specifies whether the asset reporting
  service point is present or absent.
  - Values include: { Present | Absent }

#### CMReportingServicePoint Examples

- [CMReportingServicePoint_Absent](Source\Examples\Resources\CMReportingServicePoint\CMReportingServicePoint_Absent.ps1)
- [CMReportingServicePoint_Present](Source\Examples\Resources\CMReportingServicePoint\CMReportingServicePoint_Present.ps1)

### CMPxeDistributionPoint

- **[String] SiteCode** _(Key)_:  Specifies the SiteCode for the Configuration
  Manager site.
- **[String] SiteServerName** _(Key)_: Specifies the SiteServer to install the
  role on.
- **[Boolean] EnablePxe** _(Write)_: Indicates whether PXE is enabled on
  the distribution point.
- **[Boolean] EnableNonWdsPxe** _(Write)_: Specifies whether to enable PXE responder
  without Windows Deployment services.
- **[Boolean] EnableUnknownComputerSupport** _(Write)_: Indicates whether support
  for unknown computers is enabled.
- **[Boolean] AllowPxeResponse** _(Write)_: Indicates whether the distribution
  point can respond to PXE requests.
- **[UInt16] PxeServerResponseDelaySec** _(Write)_: Specifies, in seconds, how
  long the distribution point delays before it responds to computer requests.
- **[String] UserDeviceAffinity** _(Write)_: Specifies how you want the distribution
  point to associate users with their devices for PXE deployments.
  - Values include: { DoNotUse | AllowWithManualApproval |
    AllowWithAutomaticApproval }
- **[PSCredential] PxePassword** _(Write)_: Specifies, as a credential, the
  PXE password.
- **[Boolean] IsMulticast** _(Read)_: Specifies if multicast is enabled.
- **[String] DPStatus** _(Read)_: Specifies if the DP role is installed.

#### CMPxeDistributionPoint Examples

- [CMPxeDistributionPoint_Disabled](Source\Examples\Resources\CMPxeDistributionPoint\CMPxeDistributionPoint_Disabled.ps1)
- [CMPxeDistributionPoint_Enabled](Source\Examples\Resources\CMPxeDistributionPoint\CMPxeDistributionPoint_Enabled.ps1)

### CMPullDistributionPoint

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SiteServerName** _(Key)_: Specifies the SiteServer to configure the
  Pull Distribution Point.
- **[Boolean] EnablePullDP** _(Write)_: Specifies if the distribution point is
  to be set to enabled or disabled for pull distribution point.
- **[EmbeddedInstance] SourceDistributionPoint[]** _(Write)_: Specifies the desired
  source distribution points and the DP ranking.
- **[String] DPStatus** _(Read)_: Specifies if the DP role is installed.

#### CMPullDistributionPoint Examples

- [CMPullDistributionPoint_Enabled](Source\Examples\Resources\CMPullDistributionPoint\CMPullDistributionPoint_Enabled.ps1)
- [CMPullDistributionPoint_Disabled](Source\Examples\Resources\CMPullDistributionPoint\CMPullDistributionPoint_Disabled.ps1)

### CMSiteMaintenance

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] TaskName** _(Key)_: Specifies the name of the maintenance task.
  - Values include: { Delete Aged Inventory History | Delete Aged Metering Data |
  Clear Undiscovered Clients | Delete Obsolete Alerts | Delete Aged Replication Data
  | Delete Aged Device Wipe Record | Delete Aged Enrolled Devices | Delete Aged User
  Device Affinity Data | Delete Duplicate System Discovery Data | Delete Aged
  Unknown Computers | Delete Expired MDM Bulk Enroll Package Records | Backup SMS
  Site Server | Delete Aged Status Messages | Delete Aged Metering Summary Data |
  Delete Inactive Client Discovery Data | Delete Aged Application Revisions |
  Delete Aged Replication Summary Data | Delete Obsolete Forest Discovery Sites
  And Subnets | Delete Aged Threat Data | Delete Aged Delete Detection Data |
  Delete Aged Distribution Point Usage Stats | Delete Orphaned Client Deployment
  State Records | Rebuild Indexes | Delete Aged Discovery Data | Summarize File
  Usage Metering Data | Delete Obsolete Client Discovery Data | Delete Aged Log
  Data | Delete Aged Application Request Data | Check Application Title with
  Inventory Information | Delete Aged EP Health Status History Data | Delete
  Aged Notification Task History | Delete Aged Passcode Records | Delete Aged
  Console Connection Data | Monitor Keys | Delete Aged Collected Files |
  Summarize Monthly Usage Metering Data | Delete Aged Computer Association Data
  | Delete Aged Client Download History | Delete Aged Exchange Partnership |
  Summarize Installed Software Data | Delete Aged Client Operations | Delete Aged
  Notification Server History | Update Application Available Targeting | Delete
  Aged Cloud Management Gateway Traffic Data | Update Application Catalog
  Tables }
- **[Boolean] Enabled** _(Required)_: Specifies if the task is enabled or disabled.
- **[String] DaysOfWeek[]** _(Write)_: Specifies an array of day names that
  determine the days of each week on which the maintenance task runs.
- **[String] BeginTime** _(Write)_: Specifies the time at which a maintenance
  task starts.
- **[String] LatestBeginTime** _(Write)_: Specifies the latest start time at
  which the maintenance task runs.
- **[UInt32] DeleteOlderThanDays** _(Write)_: Specifies how many days to delete
  data that has been inactive for.
- **[String] BackupLocation** _(Write)_: Specifies the backup location for Backup
  Site Server.
- **[UInt32] RunInterval** _(Write)_: Species the run interval in minutes for
  Application Catalog Tables task only.
- **[UInt32] TaskType** _(Read)_: Specifies the type of task.
- **[UInt32] SiteType** _(Read)_: Specifies the a numeric value for the site type.

#### CMSiteMaintenance Examples

- [CMSiteMaintenance_BackupTask_Enabled](Source\Examples\Resources\CMSiteMaintenance\CMSiteMaintenance_BackupTask_Enabled.ps1)
- [CMSiteMaintenance_Disabled](Source\Examples\Resources\CMSiteMaintenance\CMSiteMaintenance_Disabled.ps1)
- [CMSiteMaintenance_MaintenanceTask_Enabled](Source\Examples\Resources\CMSiteMaintenance\CMSiteMaintenance_MaintenanceTask_Enabled.ps1)
- [CMSiteMaintenance_SummaryTask_Enabled](Source\Examples\Resources\CMSiteMaintenance\CMSiteMaintenance_SummaryTask_Enabled.ps1)
- [CMSiteMaintenance_UpdateAppCatTablesTask_Enabled](Source\Examples\Resources\CMSiteMaintenance\CMSiteMaintenance_UpdateAppCatTablesTask_Enabled.ps1)

### CMAdministrativeUser

- **[String] AdminName** _(Key)_: Specifies the name of the administrator account.
- **[String] SiteCode** _(Required)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] Roles[]** _(Write)_: Specifies an array of names for the roles
  desired to be assigned to an administrative user.
- **[String] RolesToInclude[]** _(Write)_: Specifies an array of names for the
  roles desired to be added to an administrative user.
- **[String] RolesToExclude[]** _(Write)_: Specifies an array of names for the
  roles desired to be removed from an administrative user.
- **[String] Scopes[]** _(Write)_: Specifies an array of names for the scopes
  desired to be assigned to an administrative user.
- **[String] ScopesToInclude[]** _(Write)_: Specifies an array of names for the
  scopes desired to be added to an administrative user.
- **[String] ScopesToExclude[]** _(Write)_: Specifies an array of names for the
  scopes desired to be removed from an administrative user.
- **[String] Collections[]** _(Write)_: Specifies an array of names for the
  collections desired to be assigned to an administrative user.
- **[String] CollectionsToInclude[]** _(Write)_: Specifies an array of names for
  the collections desired to be added to an administrative user.
- **[String] CollectionsToExclude[]** _(Write)_: Specifies an array of names for
  the collections desired to be removed from an administrative user.
- **[String] Ensure** _(Write)_: Specifies whether the administrative user
  is present or absent.
  - Values include: { Present | Absent }

#### CMAdministrativeUser Examples

- [CMAdministrativeUser_Absent](Source\Examples\Resources\CMAdministrativeUser\CMAdministrativeUser_Absent.ps1)
- [CMAdministrativeUser_Present](Source\Examples\Resources\CMAdministrativeUser\CMAdministrativeUser_Present.ps1)

### CMDistributionGroup

- **[String] DistributionGroup** _(Key)_: Specifies the Distribution Group name.
- **[String] SiteCode** _(Required)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] DistributionPoints[]** _(Write)_: Specifies an array of Distribution
  Points to match to the Distribution Group.
- **[String] DistributionPointsToInclude[]** _(Write)_: Specifies an array of
  Distribution Points to add to the Distribution Group.
- **[String] DistributionPointsToExclude[]** _(Write)_: Specifies an array of
  Distribution Points to remove from the Distribution Group.
- **[String] SecurityScopes[]** _(Write)_: Specifies an array of Security Scopes
  to match to the Distribution Group.
- **[String] SecurityScopesToInclude[]** _(Write)_: Specifies an array of
  Security Scopes to add to the Distribution Group.
- **[String] SecurityScopesToExclude[]** _(Write)_: Specifies an array of
  Security Scopes to remove from the Distribution Group.
- **[String] Ensure** _(Write)_: Specifies whether the Distribution Group
  is present or absent.
  - Values include: { Present | Absent }

#### CMDistributionGroup Examples

- [CMDistributionGroup_Present](Source\Examples\Resources\CMDistributionGroup\CMDistributionGroup_Present.ps1)
- [CMDistributionGroup_Absent](Source\Examples\Resources\CMDistributionGroup\CMDistributionGroup_Absent.ps1)

### CMSiteSystemServer

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SiteSystemServer** _(Key)_: Specifies the name of the site system server.
- **[String] PublicFqdn** _(Write)_: Specifies the public FQDN of the site server.
  Setting PublicFqdn = '' will disable the PublicFqdn setting.
- **[Boolean] FdmOperation** _(Write)_: Indicates whether the site system server
  is required to initiate connections to this site system.
- **[Boolean] UseSiteServerAccount** _(Write)_: Indicates that the install uses
  the site server's computer account to install the site system.
- **[String] AccountName** _(Write)_: Specifies the account name for installing
  the site system.
- **[Boolean] EnableProxy** _(Write)_: Indicates whether to enable a proxy server
  to use when the server synchronizes information from the Internet.
- **[String] ProxyServerName** _(Write)_: Specifies the name of a proxy server.
  Use a fully qualified domain name FQDN, short name, or IPv4/IPv6 address.
- **[UInt32] ProxyServerPort** _(Write)_: Specifies the proxy server port number
  to use when connecting to the Internet.
- **[String] ProxyAccessAccount** _(Write)_: Specifies the credentials to use
  to authenticate with the proxy server.
  Setting ProxyAccessAccount = '' will reset the proxy to use system account.
- **[String] Ensure** _(Write)_: Specifies whether the system site
  server is present or absent.
  - Values include: { Present | Absent }

#### CMSiteSystemServer Examples

- [CMSiteSystemServer_Present](Source\Examples\Resources\CMSiteSystemServer\CMSiteSystemServer_Present.ps1)
- [CMSiteSystemServer_Absent](Source\Examples\Resources\CMSiteSystemServer\CMSiteSystemServer_Absent.ps1)

### CMStatusReportingComponent

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[Boolean] ClientLogChecked** _(Write)_: Indicates whether a client log is checked.
- **[Boolean] ClientLogFailureChecked** _(Write)_: Indicates whether a client log
  failure is checked.
- **[String] ClientLogType** _(Write)_: Specifies a client log type.
  - Values include: { AllMilestones | AllMilestonesAndAllDetails |
  ErrorAndWarningMilestones | ErrorMilestones }
- **[Boolean] ClientReportChecked** _(Write)_: Indicates whether a client report
  is checked.
- **[Boolean] ClientReportFailureChecked** _(Write)_: Indicates whether a client
  failure is checked.
- **[String] ClientReportType** _(Write)_: Specifies a client report type.
  - Values include: { AllMilestones | AllMilestonesAndAllDetails |
  ErrorAndWarningMilestones | ErrorMilestones }
- **[Boolean] ServerLogChecked** _(Write)_: Indicates whether a server log is checked.
- **[Boolean] ServerLogFailureChecked** _(Write)_: Indicates whether a server log
  failure is checked.
- **[String] ServerLogType** _(Write)_: Specifies a server log type.
  - Values include: { AllMilestones | AllMilestonesAndAllDetails |
  ErrorAndWarningMilestones | ErrorMilestones }
- **[Boolean] ServerReportChecked** _(Write)_: Indicates whether a server report
  is checked.
- **[Boolean] ServerReportFailureChecked** _(Write)_: Indicates whether a server
  report failure is checked.
- **[String] ServerReportType** _(Write)_: Specifies a server report type.
  - Values include: { AllMilestones | AllMilestonesAndAllDetails |
  ErrorAndWarningMilestones | ErrorMilestones }

#### CMStatusReportingComponent Examples

- [CMStatusReportingComponent_Example](Source\Examples\Resources\CMStatusReportingComponent\CMStatusReportingComponent_Example.ps1)

### CMCollectionMembershipEvaluationComponent

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[UInt32] EvaluationMins** _(Required)_: Indicates the CM Collection Membership
  Evaluation Component interval in minutes.

#### CMCollectionMembershipEvaluationComponent Examples

- [CMCollectionMembershipEvaluationComponent_Example](Source\Examples\Resources\CMCollectionMembershipEvaluationComponent\CMCollectionMembershipEvaluationComponent_Example.ps1)

### CMDistributionPointGroupMembers

- **[String] DistributionPoint** _(Key)_: Specifies the Distribution Point to modify
  Distribution Point Group membership.
- **[String] SiteCode** _(Required)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] DistributionGroups[]** _(Write)_: Specifies an array of Distribution
  Groups to match on the Distribution Point.
- **[String] DistributionGroupsToInclude[]** _(Write)_: Specifies an array of
  Distribution Groups to add to the Distribution Point.
- **[String] DistributionGroupsToExclude[]** _(Write)_: Specifies an array of
  Distribution Groups to remove from the Distribution Point.
- **[String] DPStatus** _(Read)_: Specifies if the DP role is installed.

#### CMDistributionPointGroupMembers Example

- [CMDistributionPointGroupMembers](Source\Examples\Resources\CMDistributionPointGroupMembers\CMDistributionPointGroupMembers.ps1)

### CMSecurityScopes

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SecurityScopeName** _(Key)_: Specifies the Security Scope name.
- **[String] Description** _(Write)_: Specifies the description of the Security Scope.
- **[String] Ensure** _(Write)_: Specifies whether the Security Scope
  is present or absent.
  - Values include: { Present | Absent }
- **[Boolean] InUse** _(Read)_: Specifies if the Security Scope is
  currently in use.

#### CMSecurityScopes Examples

- [CMSecurityScopes_Present](Source\Examples\Resources\CMSecurityScopes\CMSecurityScopes_Present.ps1)
- [CMSecurityScopes_Absent](Source\Examples\Resources\CMSecurityScopes\CMSecurityScopes_Absent.ps1)

### CMUserDiscovery

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[Boolean] Enabled** _(Key)_: Specifies the enablement of the User
  Discovery method. If settings is set to $false no other value provided will be
  evaluated for compliance.
- **[Boolean] EnableDeltaDiscovery** _(Write)_: Indicates whether Configuration
  Manager discovers resources created or modified in AD DS since the last
  discovery cycle.
- **[UInt32] DeltaDiscoveryMins** _(Write)_: Specifies the number of minutes for
  the delta discovery.
- **[String] ADContainers[]** _(Write)_: Specifies an array of names of Active Directory
  containers to match to the discovery.
- **[String] ADContainersToInclude[]** _(Write)_: Specifies an array of names of
  Active Directory containers to add to the discovery.
- **[String] ADContainersToExclude[]** _(Write)_: Specifies an array of names of
  Active Directory containers to exclude to the discovery.
- **[String] ScheduleInterval** _(Write)_: Specifies the time when the scheduled
  event recurs in hours and days.
  - Values include: { None| Days| Hours | Minutes }
- **[UInt32] ScheduleCount** _(Write)_: Specifies how often the recur interval
  is run. If hours are specified the max value is 23. Anything over 23 will result
  in 23 to be set. If days are specified the max value is 31. Anything over 31 will
  result in 31 being set.

#### CMUserDiscovery Examples

- [CMUserDiscovery_Disabled](Source\Examples\Resources\CMUserDiscovery\CMUserDiscovery_Disabled.ps1)
- [CMUserDiscovery_Enabled](Source\Examples\Resources\CMUserDiscovery\CMUserDiscovery_Enabled.ps1)
- [CMUserDiscovery_Exclude](Source\Examples\Resources\CMUserDiscovery\CMUserDiscovery_Exclude.ps1)
- [CMUserDiscovery_Include](Source\Examples\Resources\CMUserDiscovery\CMUserDiscovery_Include.ps1)
- [CMUserDiscovery_ScheduleNone](Source\Examples\Resources\CMUserDiscovery\CMUserDiscovery_ScheduleNone.ps1)

### CMSecurityRoles

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[String] SecurityRoleName** _(Key)_: Specifies the Security Role name.
- **[String] Description** _(Write)_: Specifies the description of the Security Role.
- **[String] XmlPath** _(Write)_: Specifies the path the Security Role xml file
  to evaluate and import.
- **[Boolean] OverWrite** _(Write)_: Specifies if the Security Roles does not match
  the xml this will overwrite the policy.
- **[Boolean] Append** _(Write)_: Specifies additional settings in the xml will
  be appended to the current Security Role. If append is used a new xml file will
  be created merging current settings with the additional settings in the xml. Any
  settings that are currently configured and in the xml will match the settings specified
  in the xml file. The original XML file will be renamed and be updated with a date
  time stamp and renamed to .old.
- **[String] Ensure** _(Write)_: Specifies whether the Security Role
  is present or absent.
  - Values include: { Present | Absent }
- **[String] Operation** _(Read)_: Specifies the configurations of the Security Role.
- **[String] UsersAssigned[]** _(Read)_: Specifies the accounts associated with the
  Security Role.

#### CMSecurityRoles Examples

- [CMSecurityRoles_Present](Source\Examples\Resources\CMSecurityRoles\CMSecurityRoles_Present.ps1)
- [CMSecurityRoles_Absent](Source\Examples\Resources\CMSecurityRoles\CMSecurityRoles_Absent.ps1)

### CMClientPushSettings

- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
  Manager site.
- **[Boolean] EnableAutomaticClientPushInstallation** _(Write)_: Specifies whether
  Configuration Manager automatically uses client push for discovered computers.
- **[Boolean] EnableSystemTypeConfigurationManager** _(Write)_: Specifies whether
  Configuration Manager pushes the client software to Configuration Manager site
  system servers.
- **[Boolean] EnableSystemTypeServer** _(Write)_: Specifies whether Configuration
  Manager pushes the client software to servers.
- **[Boolean] EnableSystemTypeWorkstation** _(Write)_: Specifies whether Configuration
  Manager pushes the client software to workstations.
- **[Boolean] InstallClientToDomainController** _(Write)_: Specifies whether to use
  automatic site-wide client push installation to install the Configuration Manager
  client software on domain controllers.
- **[String] InstallationProperty** _(Write)_: Specifies any installation properties
  to use when installing the Configuration Manager client. Note: No validation is
  performed on the string of text entered and will import as specified.
- **[String] Accounts[]** _(Write)_: Specifies an array of accounts to exactly match
  for use with client push.
- **[String] AccountsToInclude[]** _(Write)_: Specifies an array of accounts to
  add for use with client push.
- **[String] AccountsToExclude[]** _(Write)_: Specifies an array of accounts to
  remove for use with client push.

#### CMSecurityRoles Examples

- [CMClientPushSettings_Disabled](Source\Examples\Resources\CMClientPushSettings\CMClientPushSettings_Disabled.ps1)
- [CMClientPushSettings_Enabled](Source\Examples\Resources\CMClientPushSettings\CMClientPushSettings_Enabled.ps1)
- [CMClientPushSettings_Include](Source\Examples\Resources\CMClientPushSettings\CMClientPushSettings_Include.ps1)
