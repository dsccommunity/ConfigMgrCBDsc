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

- **SccmIniFile** This resource allows for the creation of the ini file
  used during the SCCM install, for CAS and Primary.

### SCCMIniFile

- **IniFileName**: Specifies the ini file name.
- **IniFilePath**: Specifies the path of the ini file.
- **Action**: Specifies whether to install a CAS or Primary.
- **CDLatest**: This value informs setup that you're using media from
  CD.Latest.
- **ProductID**: Specifies the Configuration Manager installation product
  key, including the dashes.
- **SiteCode**: Specifies three alphanumeric characters that uniquely
  identify the site in your hierarchy.
- **SiteName**: Specifies the name for this site.
- **SMSInstallDir**: Specifies the installation folder for the Configuration
  Manager program files.
- **SDKServer**: Specifies the FQDN for the server that will host the SMS
  Provider.
- **PreRequisiteComp**: Specifies whether setup prerequisite files have already
  been downloaded.
- **PreRequisitePath**: Specifies the path to the setup prerequisite files.
- **AdminConsole**: Specifies whether to install the Configuration Manager console.
- **JoinCeip**: Specifies whether to join the Customer Experience Improvement
  Program (CEIP).
- **MobileDeviceLanguage**: Specifies whether the mobile device client languages
  are installed.
- **RoleCommunicationProtocol**: Specifies whether to configure all site systems to
  accept only HTTPS communication from clients, or to configure the communication
  method for each site system role.
- **ClientsUsePKICertificate**: Specifies whether clients will use a client PKI
  certificate to communicate with site system roles.
- **ManagementPoint**: Specifies the FQDN of the server that will host the management
  point site system role.
- **ManagementPointProtocol**: Specifies the protocol to use for the management point.
- **DistributionPoint**: Specifies the FQDN of the server that will host the
  distribution point site system role.
- **DistributionPointProtocol**: Specifies the protocol to use for the
  distribution point.
- **AddServerLanguages**: Specifies the server languages that will be available
  for the Configuration Manager console, reports, and Configuration Manager objects.
- **AddClientLanguages**: Specifies the languages that will be available to
  client computers.
- **DeleteServerLanguages**: Modifies a site after it's installed. Specifies
  the languages to remove, and which will no longer be available for the
  Configuration Manager console, reports, and Configuration Manager objects.
- **SQLServerName**: Specifies the name of the server or clustered instance
  that's running SQL Server to host the site database.
- **DatabaseName**: Specifies the name of the SQL Server database to create, or
  the SQL Server database to use, when setup installs the CAS database. This
  can also include the instance, instance\<databasename>.
- **SqlSsbPort**: Specifies the SQL Server Service Broker (SSB) port that SQL
  Server uses.
- **SQLDataFilePath**: Specifies an alternate location to create the database
  .mdb file.
- **SQLLogFilePath**: Specifies an alternate location to create the database
  .ldf file.
- **CCARSiteServer**: Specifies the CAS that a primary site attaches to when it
  joins the Configuration Manager hierarchy.
- **CasRetryInterval**: Specifies the retry interval in minutes to attempt a
  connection to the CAS after the connection fails.
- **WaitForCasTimeout**: Specifies the maximum timeout value in minutes for a
  primary site to connect to the CAS.
- **CloudConnector**: Specifies the FQDN of the server that will host the
  service connection point site system role.
- **CloudConnectorServer**: Specifies the FQDN of the server that will host the
  service connection point site system role.
- **UseProxy**: Specifies whether the service connection point uses a proxy server.
- **ProxyName**: Specifies the FQDN of the proxy server that the service
  connection point uses.
- **ProxyPort**: Specifies the port number to use for the proxy port.
- **SAActive**: Specify if you have active Software Assurance.
- **CurrentBranch**: Specify whether to use Configuration Manager current
  branch or long-term servicing branch (LTSB).
