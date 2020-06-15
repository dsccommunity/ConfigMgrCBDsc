# Change log for ConfigMgrCBDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added SccmIniFile resource
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
- Added CMDsitributionPoint Resource

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

### Removed

- Removed ClientSettings resource
- Removed Historic Changelog

### Fixed
