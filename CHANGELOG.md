# Change log for ConfigMgrCBDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).

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

### Removed

- Removed ClientSettings resource

### Fixed
