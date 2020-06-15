# ConfigMgrCBDsc

This module contains DSC resources for the management and
configuration of Microsoft System Center Configuration Manager Current Branch (ConfigMgrCB).

Current Branch starts after System Center 2012 with version 1511 [Configuration Manager CurrentBranch](https://docs.microsoft.com/en-us/mem/configmgr/core/plan-design/changes/what-has-changed-from-configuration-manager-2012).

Starting with version 1910 Configuration Manager is now part of [Microsoft Endpoint Manager](https://docs.microsoft.com/en-us/mem/configmgr/core/understand/introduction).

This module has been tested on the following versions:

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
- **[EmbeddedInstance] PollingSchedule** _(Write)_: Contains the polling
  schedule for Configuration Manager (RecurInterval, RecurCount).
- **[Boolean] EnableActiveDirectorySiteBoundaryCreation** _(Write)_: Indicates
  whether Configuration Manager creates Active Directory boundaries from AD DS
  discovery information.
- **[Boolean] EnableSubnetBoundaryCreation** _(Write)_: Indicates whether
  Configuration Manager creates IP address range boundaries from AD DS discovery
  information.

#### CMForestDiscovery Examples

- [ForestDiscovery_Disabled](Source\Examples\Resources\CMForestDiscovery\ForestDiscovery_Disabled.ps1)
- [ForestDiscovery_Enabled](Source\Examples\Resources\CMForestDiscovery\ForestDiscovery_Enabled.ps1)

### CMClientStatusSettings

- **[String] IsSingleInstance** _(Key)_:  Specifies the resource is a single
  instance, the value must be 'Yes'.
  { Yes }.
- **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
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
- **[String] BoundaryGroup** _(Key)_: Specifies the name of the boundary group.
- **[EmbeddedInstance] Boundaries** _(Write)_: Specifies an array of boundaries
  to add or remove from the boundary group.
- **[String] BoundaryAction** _(Write)_: Specifies the boundaries are to match,
  add, or remove Boundaries from the boundary group
  - Values include: { Match | Add | Remove }
- **[String] Ensure** _(Write)_: Specifies status of the collection is to be
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
