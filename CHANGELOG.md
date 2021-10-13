# Change log for ConfigMgrCBDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added ConfigMgrCBDsc.ReverseDsc module
- Added CMEmailNotificationComponent
- Added CMGroupDiscovery Resource
- Added CMSoftwareUpdatePointComponent resource

### Fixed

- Fixed issue with CMAccounts with Get returning a string when only one account exists.
- Fixed issue with Boundary groups containing VPN type boundaries.

### Changed

- Added support for VPN and IPv6Prefix boundaries to the CMBoundaries resource.
- Updated module versions for SqlServerDsc, NetworkingDsc, ComputerManagementDsc

## [1.0.2] - 2021-05-12

### Added

 -Added fixed Bug in CMCollections for Schedule Types

## [1.0.1] - 2021-05-12

### Added

- Added SccmIniFile resource
- Added xSccmInstall examples
- Added xSccmSql examples
- Added xSccmPreReq examples
- Added CMCollections Resource
- Added Set-ConfigMgrCert to the ResourceHelper
- Added CMBoundaries resource
- Added Convert-CidrToIP to the ResourceHelper
- Added CMForestDiscovery resource
- Added ConvertTo-CimCMScheduleString to the ResourceHelper
- Added CMClientStatusSettings Resource
- Added CMBoundaryGroups Resource
- Added ConvertTo-CimBoundaries to the ResourceHelper
- Added Convert-BoundariesIPSubnets to the ResourceHelper
- Added Get-BoundaryInfo to the ResourceHelper
- Added CMManagementPoint Resource
- Added psd1 for ResourceHelper
- Added CMAssetIntelligencePoint Resource
- Added VSCode Project Settings and PS Script Analyzer rules
- Added Issue and PR template.
- Added CMFallbackStatusPoint Resource
- Added CMSoftwareUpdatePoint Resource
- Added CMDistributionPoint Resource
- Added CMHeartbeatDiscovery module
- Added ConvertTo-ScheduleInterval to ResourceHelper
- Added CMServiceConnectionPoint Resource
- Added CMNetworkDiscovery Resource
- Added CMReportingServicePoint Resource
- Added CMSystemDiscovery Resource
- Added CMPxeDistributionPoint Resource
- Added CMPullDistributionPoint Resource
- Added ConvertTo-AnyCimInstance to the ResourceHelper
- Added CMSiteMaintenance Resource
- Added CMAdministrativeUser Resource
- Added Compare-MultipleCompares to the ResourceHelper
- Added CMDistributionGroup Resource
- Added CMSiteSystemServer Resource
- Added CMStatusReportingComponent Resource
- Added CMCMCollectionMembershipEvaluationComponent Resource
- Added CMDistributionPointGroupMembers Resource
- Added CMSecurityScopes Resource
- Added CMUserDiscovery Resource
- Added CMSecurityRoles Resource
- Added Add-DPToDPGroup to the ResourceHelper
- Added CMClientPushSettings Resource
- Added CMSoftwareDistributionComponent Resource
- Added Get-CMSchedule to the ResourceHelper
- Added Test-CMSchedule to the ResourceHelper
- Added Set-CMSchedule to the ResourceHelper
- Added CMMaintenanceWindows Resource
- Added CMFileReplication Resource

### Changed

- Update ConfigMgrCBDsc.ResourceHelper Import-ConfigMgrPowerShellModule
- Updated current DSCResources in module that use Import-ConfigMgrPowerShellModule
  adding SiteCode
- Updated ConfigMgrCBDscStub, removing line for polling schedule type
- Updated current DSCResources helper in module Import-ConfigMgrPowerShellModule
  adding fixing registry settings
- Renamed CMAccounts resource to DSC_CMAccounts
- Renamed MSFT_SCCMIniFile resource to DSC_CMIniFile
- Updated Readme with additional information
- Updated GitVersion to reflect a release has not been completed.
- Updated ModuleBuilder to latest
- Updated pipeline to run on merges to master only when something in source changes
- Added UDP 1434 to the defaults for the xSCCMPreReqs.
- Fixed newline in the CMIniFile resource.
- Removed WSUS top level feature.
- Added Security Scopes to CMDistributionGroup Resource
- Added SiteSystems, SiteSystemsToInclude, and SiteSystemsToExclude and SecurityScopes,
  SecurityScopesToInclude, SecurityScopesToExclude to CMBoundaryGroup resource.
- Updated CMSystemDiscovery Resource to add needed throw and warn messages.
- Added InstanceDir parameter to SQL composite.
- Updated the xSCCMInstall resource accounting for the product name change on versions
  1910 and greater.
- Updated ReadMe with latest versions of ConfigMgr that the module has been
  tested on.
- Added DistributionPointInstallIis parameter to CmIniFile #62
- Added an example for a Standalone Primary Site Server and updated required modules
  to support.
- Updated CMForestDiscovery to remove the unneeded CimInstance for schedule. Also
  added warning messages when exceeding max allowed hours or days and setting the
  value to the default highest available value.
- Updated CMHeartbeatDiscovery to warn when exceeding max allowed hours or days.
- Updated CMUserDiscovery to warn when exceeding max allowed hours or days or minutes
  and when specifying under the minimum allowed minutes.
- Removed CimInstance for the CMCollections schedule.  Added support IncludeMembership
  for collections.  Added support for adding DirectMembershipRules for users and
  devices using resource name or ResourceId.
- Added additional schedule types for CMCollections schedules.
- Updated CMSystemDiscovery to warn when exceeding max allowed hours or days or minutes
  and when specifying under the minimum allowed minutes.
- Updated CMAssetIntelligencePoint to use the helper function for scheduling.

### Removed

- Removed ClientSettings resource
- Removed Historic Changelog

### Fixed

- Fixed issue when adding a Distribution Point to Distribution Group immediately
  after adding the Distribution Point would error saying invalid Distribution Point.
- Updated Build.yaml and RequiredModules.ps1 to allow for GitHub builds.
- Updated PrimaryInstall.ps1 to remove module version.
