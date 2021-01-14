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

- **[xSccmPreReqs](https://github.com/CCWT/ConfigMgrCBDsc/wiki/xSccmPreReqs)**: Provides a composite resource to install ADK, ADK WinPE, MDT,
  required Windows Features, modify Local Administrators group, and create the
  no_sms_on_drive files.
- **[xSccmSqlSetup](https://github.com/CCWT/ConfigMgrCBDsc/wiki/xSccmSqlSetup)**: Provides a composite resource to install SQL for SCCM.
- **[xSccmInstall](https://github.com/CCWT/ConfigMgrCBDsc/wiki/xSccmSqlSetup)**: Provides a composite reosurce to install SCCM.
- ~~**ClientSettings**: Provides a resource to perform configuration of client settings.~~
- **[CMAccounts](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMAccounts)**: Provides a resource to manage Configuration Manager accounts.
- **[CMIniFile](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMIniFile)** This resource allows for the creation of the ini file
  used during the SCCM install, for CAS and Primary.
- **[CMCollections](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMCollections)**: Provides a resource for creating collections and collection
  queries, direct, and exclude membership rules.
- **[CMBoundaries](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMBoundaries)**: Provides a resource for creating and removing boundaries.
- **[CMForestDiscovery](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMForestDiscovery)**: Provides a resource to manage the Configuration Manager
  AD Forest Discovery method.
- **[CMClientStatusSettings](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMClientStatusSettings)**: Provides a resource for modifying configuration
  manager client status settings.
- **[CMBoundariesGroup](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMBoundariesGroup)**: Provides a resource for creating boundary groups and
  adding boundaries to the groups.
- **[CMManagementPoint](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMManagementPoint)**: Provides a resource for creating and removing
  management points.
- **[CMAssetIntelligencePoint](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMAssetIntelligencePoint)**: Provides a resource for creating and managing
  the SCCM Asset Intelligence Synchronization Point role.
- **[CMFallbackStatusPoint](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMFallbackStatusPoint)**: Provides a resource for creating and managing
  the SCCM Fallback Status Point role.
- **[CMSoftwareUpdatePoint](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMSoftwareUpdatePoint)**: Provides a resource for creating and managing
  the SCCM Software Update Point role.
- **[CMDistributionPoint](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMDistributionPoint)**: Provides a resource for creating and managing
  the distribution point role.
- **[CMHeartbeatDiscovery](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMHeartbeatDiscovery)**: Provides a resource to manage the Configuration Manager
  Heartbeat Discovery method.
- **[CMSystemDiscovery](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMSystemDiscovery)**: Provides a resource to manage the Configuration Manager
  System Discovery method.
- **[CMNetworkDiscovery](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMNetworkDiscovery)**: Provides a resource to manage the Configuration Manager
  Network Discovery method.
- **[CMServiceConnectionPoint](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMServiceConnectionPoint)**: Provides a resource for creating and managing
  the SCCM Service Connection Point role.
- **[CMReportingServicePoint](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMReportingServicePoint)**: Provides a resource for creating and managing
  the SCCM Reporting Service Point role.
- **[CMPxeDistributionPoint](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMPxeDistributionPoint)**: Provides a resource for modifying a distribution point
  to changing to a PXE enabled distribution point.
- **[CMPullDistributionPoint](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMPullDistributionPoint)**: Provides a resource for modifying a distribution point
  and making the distribution point a Pull Distribution Point.
- **[CMSiteMaintenance](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMSiteMaintenance)**: Provides a resource for modifying the Site Maintenance tasks.
- **[CMAdministrativeUser](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMAdministrativeUser)**:  Provides a resource for adding, removing, and configuring
  administrative users.
- **[CMDistributionGroup](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMDistributionGroup)**: Provides a resource for creating Distribution Point
  Groups and adding Distribution Points to the group.
- **[CMSiteSystemServer](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMSiteSystemServer)**: Provides a resource for adding and modifying a Site
  System Server and its properties.
- **[CMStatusReportingComponent](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMStatusReportingComponent)**: Provides a resource for modifying the Status
  Reporting Component and its properties.
- **[CMCollectionMembershipEvaluationComponent](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMCollectionMembershipEvaluationComponent)**: Provides a resource for modifying
  the SCCM Collection Membership Evaluation Component.
- **[CMDistributionPointGroupMembers](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMDistributionPointGroupMembers)**: Provides a resource for adding Distribution
  Groups to Distribution Points. This resource will not create Distribution Points
  or Distribution Groups.
- **[CMSecurityScopes](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMSecurityScopes)**: Provides a resource for adding and removing Security
  Scopes.  Note: If the Security Scope is currently in use and assigned, DSC will
  not remove the Security Scope.
- **[CMUserDiscovery](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMUserDiscovery)**: Provides a resource to manage the Configuration Manager
  User Discovery method.
- **[CMSecurityRoles](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMSecurityRoles)**: Provides a resource for adding and removing Security
  Roles.  Note: If the Security Role is currently assigned to an administrator,
  DSC will not remove the Security Role.
- **[CMClientPushSettings](https://github.com/CCWT/ConfigMgrCBDsc/wiki/CMClientPushSettings)**: Provides a resource for modifying client push
  settings.  Note: EnableSystemTypeConfigurationManager, EnableSystemTypeServer,
  EnableSystemTypeWorkstation can not be configured if client push is disabled.
