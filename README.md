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

The following resources are available in this resource.

* **ClientSettings**: Provides a resource to perform configuration of client settings.
* **CMAccounts**: Provides a resource to manage Configuration Manager accounts.
* **Collections**: Provides a resource to manage Configuration Manager collections.

### ClientSettings

* **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
Manager site.
* **[String] Name** _(Key)_: Specifies the display name of the client setting package.
* **[String] DeviceSettingName** _(Key)_: Specifies the parent setting category.
{BackgroundIntelligentTransfer|ClientCache|ClientPolicy|Cloud|ComplianceSettings|ComputerAgent|ComputerRestart|DeliveryOptimization|EndpointProtection|HardwareInventory|MeteredNetwork|MobileDevice|NetworkAccessProtection|PowerManagement|RemoteTools|SoftwareCenter|SoftwareDeployment|SoftwareInventory|SoftwareMetering|SoftwareUpdates|StateMessaging|UserAndDeviceAffinity|WindowsAnalytics}.
* **[String] Setting** _(Key)_: Specifies the client setting to validate.
* **[String] SettingValue** _(Required)_: Specifies the value for the setting.

#### ClientSettings Examples

* [ProvisionedPackages_Present](Source\Examples\Resources\ClientSettings\ClientSettings.ps1)

### CMAccounts

* **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
Manager site.
* **[String] Account** _(Key)_: Specifies the Configuration Manager account name.
* **[PSCredential] AccountPassword** _(Write)_: Specifies the password of the
account being added to Configuration Manager.
* **[String] Ensure** _(Write)_: Specifies whether the account is present or
absent. { *Present* | Absent }.

#### CMAccounts Examples

* [CMAccounts_Absent](Source\Examples\Resources\CMAccounts\CMAccounts_Absent.ps1)
* [CMAccounts_Present](Source\Examples\Resources\CMAccounts\CMAccounts_Present.ps1)

### Collections

* **[String] SiteCode** _(Key)_: Specifies the Site Code for the Configuration
Manager site.
* **[String] CollectionName** _(Key)_: Specifies the name of the collection.
* **[String] CollectionType** _(Key)_: Specifies the type of collection.
{ User | Device }.
* **[String] LimitingCollectionName** _(Write)_: Specifies the name of a
collection to use as the default scope for this collection.
* **[String] Comment** _(Write)_: Specifies a comment for the collection.
* **[EmbeddedInstance] RefreshSchedule** _(Write)_: Specifies containing refresh
schedule for Configuration Manager (RecurInterval, RecurCount).
* **[EmbeddedInstance] QueryRules[]** _(Write)_: Specifies the name of the Rule
and the query expression that Configuration Manager uses to update collections.
* **[String] ExcludeMembership[]** _(Write)_: Specifies the collection name to
exclude members from.
* **[String] DirectMembership[]** _(Write)_: Specifies the resource id for the
direct membership rule.
* **[String] Ensure** _(Write)_: Specifies if the collection is to be present or
absent. { *Present* | Absent }.

#### Collections Examples

* [Collections_Absent](Source\Examples\Resources\Collections\Collection_Absent.ps1)
* [DeviceCollection_Present](Source\Examples\Resources\Collections\DeviceCollection_Present.ps1)
* [UserCollection_Present](Source\Examples\Resources\Collections\UserCollection_Present.ps1)
