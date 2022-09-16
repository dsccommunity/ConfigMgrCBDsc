$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $currentSetting = Get-CMHierarchySetting
    $preprodSetting = $currentSetting | Where-Object PropertyNames -contains TargetCollectionID
    $upgradeSetting = $currentSetting | Where-Object PropertyNames -contains AdvertisementDuration
    $allProperties = Get-CimInstance -Namespace "ROOT\SMS\Site_$SiteCode" -ClassName SMS_SCI_SCProperty
    [string] $excludeCollectionId = $upgradeSetting.ExcludedCollectionID
    [string] $targetCollectionId = $preprodSetting.TargetCollectionID

    if (-not [string]::IsNullOrWhiteSpace($excludeCollectionId))
    {
        $excludeCollectionName = (Get-CMCollection -Id $excludeCollectionId -ErrorAction SilentlyContinue).Name
    }

    if (-not [string]::IsNullOrWhiteSpace($targetCollectionId))
    {
        $targetCollectionName = (Get-CMCollection -Id $targetCollectionId -ErrorAction SilentlyContinue).Name
    }

    return @{
        SiteCode                           = $SiteCode
        AllowPrestage                      = $upgradeSetting.AllowPrestage
        ApprovalMethod                     = @("ManuallyApproveEachComputer", "AutomaticallyApproveComputersInTrustedDomains", "AutomaticallyApproveAllComputers")[$allProperties.Where({ $_.PropertyName -eq 'Auto Approval' }).Value]
        AutoResolveClientConflict          = -not ($allProperties.Where({ $_.PropertyName -eq 'Registration HardwareID Conflict Resolution' }).Value -as [bool])
        EnableAutoClientUpgrade            = $upgradeSetting.IsProgramEnabled
        EnableExclusionCollection          = $upgradeSetting.IsUpgradeExclusionEnabled
        EnablePreProduction                = $preprodSetting.IsAccepted -and $preprodSetting.IsEnabled
        EnablePrereleaseFeature            = $allProperties.Where({ $_.PropertyName -eq 'AcceptedBeta' }).Value -as [bool]
        ExcludeServer                      = $upgradeSetting.ExcludeServers
        PreferBoundaryGroupManagementPoint = $allProperties.Where({ $_.PropertyName -eq 'PreferMPInBoundaryWithFastNetwork' }).Value -as [bool]
        UseFallbackSite                    = -not [string]::IsNullOrWhiteSpace($allProperties.Where({ $_.PropertyName -eq 'SiteAssignmentSiteCode' }).Value1)
        AutoUpgradeDays                    = $upgradeSetting.AdvertisementDuration
        ExclusionCollectionName            = $excludeCollectionName
        FallbackSiteCode                   = $allProperties.Where({ $_.PropertyName -eq 'SiteAssignmentSiteCode' }).Value1
        TargetCollectionName               = $targetCollectionName
        TelemetryLevel                     = @("Basic", "Enhanced", "Full")[$allProperties.Where({ $_.PropertyName -eq 'TelemetryLevel' }).Value - 1]
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.
    .PARAMETER AllowPrestage
        Indicates that prestaging should be allowed.
    .PARAMETER ApprovalMethod
        Approval method to use.
    .PARAMETER AutoResolveClientConflict
        Indicates that client conflicts should automatically be resolved.
    .PARAMETER EnableAutoClientUpgrade
        Indicates that automatic client upgrades should be enabled.
    .PARAMETER EnableExclusionCollection
        Indicates that an exclusion collection should be enabled.
    .PARAMETER EnablePreProduction
        Indicates that a preproduction collection should be enabled.
    .PARAMETER EnablePrereleaseFeature
        Indicates that pre-release features should be enabled.
    .PARAMETER ExcludeServer
        Indicates that servers are excluded from auto upgrade.
    .PARAMETER PreferBoundaryGroupManagementPoint
        Indicates that the boundary group management point should be preferred.
    .PARAMETER UseFallbackSite
        Indicates that fallback site should be used, which needs to be added using the FallbackSiteCode property.
    .PARAMETER AutoUpgradeDays
        Days interval for Auto Upgrade.
    .PARAMETER ExclusionCollectionName
        Exclusion collection name.
    .PARAMETER FallbackSiteCode
        Site code of fallback site.
    .PARAMETER TargetCollectionName
        Target collection name.
    .PARAMETER TelemetryLevel
        Level of telemetry to send.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter()]
        [bool]
        $AllowPrestage,

        [Parameter()]
        [ValidateSet( "ManuallyApproveEachComputer", "AutomaticallyApproveComputersInTrustedDomains", "AutomaticallyApproveAllComputers")]
        [string]
        $ApprovalMethod,

        [Parameter()]
        [bool]
        $AutoResolveClientConflict,

        [Parameter()]
        [bool]
        $EnableAutoClientUpgrade,

        [Parameter()]
        [bool]
        $EnableExclusionCollection,

        [Parameter()]
        [bool]
        $EnablePreProduction,

        [Parameter()]
        [bool]
        $EnablePrereleaseFeature,

        [Parameter()]
        [bool]
        $ExcludeServer,

        [Parameter()]
        [bool]
        $PreferBoundaryGroupManagementPoint,

        [Parameter()]
        [bool]
        $UseFallbackSite,

        [Parameter()]
        [uint32]
        $AutoUpgradeDays,

        [Parameter()]
        [string]
        $ExclusionCollectionName,

        [Parameter()]
        [string]
        $FallbackSiteCode,

        [Parameter()]
        [string]
        $TargetCollectionName,

        [Parameter()]
        [ValidateSet("Basic", "Enhanced", "Full")]
        [string]
        $TelemetryLevel
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $PSBoundParameters.Remove('SiteCode')

    try
    {
        if ($UseFallbackSite -xor -not [string]::IsNullOrWhiteSpace($FallbackSiteCode))
        {
            throw ($script:localizedData.SettingPairMismatch -f 'UseFallbackSite', 'FallbackSiteCode')
        }

        if ($EnablePreProduction -xor -not [string]::IsNullOrWhiteSpace( $TargetCollectionName))
        {
            throw ($script:localizedData.SettingPairMismatch -f 'EnablePreProduction', 'TargetCollectionName')
        }

        if ($EnableExclusionCollection -xor -not [string]::IsNullOrWhiteSpace($ExclusionCollectionName))
        {
            throw ($script:localizedData.SettingPairMismatch -f 'EnableExclusionCollection', 'ExclusionCollectionName')
        }

        if ($ExcludeServer -and -not $EnableAutoClientUpgrade)
        {
            $PSBoundParameters.Remove('ExcludeServer')
            Write-Verbose -Message ($script:localizedData.IgnoreAutoUpgrade -f 'ExcludeServer')
        }

        if ($AutoUpgradeDays -gt 0 -and -not $EnableAutoClientUpgrade)
        {
            $PSBoundParameters.Remove('AutoUpgradeDays')
            Write-Verbose -Message ($script:localizedData.IgnoreAutoUpgrade -f 'AutoUpgradeDays')
        }

        Set-CMHierarchySetting @PSBoundParameters
    }
    catch
    {
        throw $_
    }
    finally
    {
        Set-Location -Path "$env:temp"
    }
}

<#
    .SYNOPSIS
        This will test the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.
    .PARAMETER AllowPrestage
        Indicates that prestaging should be allowed.
    .PARAMETER ApprovalMethod
        Approval method to use.
    .PARAMETER AutoResolveClientConflict
        Indicates that client conflicts should automatically be resolved.
    .PARAMETER EnableAutoClientUpgrade
        Indicates that automatic client upgrades should be enabled.
    .PARAMETER EnableExclusionCollection
        Indicates that an exclusion collection should be enabled.
    .PARAMETER EnablePreProduction
        Indicates that a preproduction collection should be enabled.
    .PARAMETER EnablePrereleaseFeature
        Indicates that pre-release features should be enabled.
    .PARAMETER ExcludeServer
        Indicates that servers are excluded from auto upgrade.
    .PARAMETER PreferBoundaryGroupManagementPoint
        Indicates that the boundary group management point should be preferred.
    .PARAMETER UseFallbackSite
        Indicates that fallback site should be used, which needs to be added using the FallbackSiteCode property.
    .PARAMETER AutoUpgradeDays
        Days interval for Auto Upgrade.
    .PARAMETER ExclusionCollectionName
        Exclusion collection name.
    .PARAMETER FallbackSiteCode
        Site code of fallback site.
    .PARAMETER TargetCollectionName
        Target collection name.
    .PARAMETER TelemetryLevel
        Level of telemetry to send.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter()]
        [bool]
        $AllowPrestage,

        [Parameter()]
        [ValidateSet( "ManuallyApproveEachComputer", "AutomaticallyApproveComputersInTrustedDomains", "AutomaticallyApproveAllComputers")]
        [string]
        $ApprovalMethod,

        [Parameter()]
        [bool]
        $AutoResolveClientConflict,

        [Parameter()]
        [bool]
        $EnableAutoClientUpgrade,

        [Parameter()]
        [bool]
        $EnableExclusionCollection,

        [Parameter()]
        [bool]
        $EnablePreProduction,

        [Parameter()]
        [bool]
        $EnablePrereleaseFeature,

        [Parameter()]
        [bool]
        $ExcludeServer,

        [Parameter()]
        [bool]
        $PreferBoundaryGroupManagementPoint,

        [Parameter()]
        [bool]
        $UseFallbackSite,

        [Parameter()]
        [uint32]
        $AutoUpgradeDays,

        [Parameter()]
        [string]
        $ExclusionCollectionName,

        [Parameter()]
        [string]
        $FallbackSiteCode,

        [Parameter()]
        [string]
        $TargetCollectionName,

        [Parameter()]
        [ValidateSet("Basic", "Enhanced", "Full")]
        [string]
        $TelemetryLevel
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode
    $eval = 'AllowPrestage', 'ApprovalMethod', 'AutoResolveClientConflict', 'EnableAutoClientUpgrade', 'EnableExclusionCollection', 'EnablePreProduction', 'EnablePrereleaseFeature', 'ExcludeServer', 'PreferBoundaryGroupManagementPoint', 'UseFallbackSite', 'AutoUpgradeDays', 'ExclusionCollectionName', 'FallbackSiteCode', 'TargetCollectionName', 'TelemetryLevel'
    $result = $true

    foreach ($property in $PSBoundParameters.GetEnumerator())
    {
        if ($eval -notcontains $property.Key)
        {
            continue
        }

        if ($property.Value -ne $state[$property.Key])
        {
            Write-Verbose -Message ($script:localizedData.TestSetting `
                    -f $property.Key, $property.Value, $state[$property.key])
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource

