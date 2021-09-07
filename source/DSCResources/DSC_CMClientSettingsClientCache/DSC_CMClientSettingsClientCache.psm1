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

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $ClientSettingName
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $clientSetting = Get-CMClientSetting -Name $ClientSettingName

    if ($clientSetting)
    {
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting ClientCache

        if ($settings)
        {
            $configBranchCache = [System.Convert]::ToBoolean($settings.ConfigureBranchCache)
            $branchCache = [System.Convert]::ToBoolean($settings.BranchCacheEnabled)
            $cacheSize = $settings.MaxBranchCacheSizePercent
            $configCacheSize = [System.Convert]::ToBoolean($settings.ConfigureCacheSize)
            $maxCacheSize = $settings.MaxCacheSizeMB
            $maxCacheSizePer = $settings.MaxCacheSizePercent
            $superPeer = [System.Convert]::ToBoolean($settings.CanBeSuperPeer)
            $broadPort = $settings.BroadcastPort
            $httpPort = $settings.HttpPort
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                  = $SiteCode
        ClientSettingName         = $ClientSettingName
        ConfigureBranchCache      = $configBranchCache
        EnableBranchCache         = $branchCache
        MaxBranchCacheSizePercent = $cacheSize
        ConfigureCacheSize        = $configCacheSize
        MaxCacheSize              = $maxCacheSize
        MaxCacheSizePercent       = $maxCacheSizePer
        EnableSuperPeer           = $superPeer
        BroadcastPort             = $broadPort
        DownloadPort              = $httpPort
        ClientSettingStatus       = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER ConfigureBranchCache
        Specifies if configure branch cache policy is enabled or disabled.

    .PARAMETER EnableBranchCache
        Specifies if branch cache is enabled or disabled.

    .PARAMETER MaxBranchCacheSizePercent
        Specifies the percentage of disk size maximum branch cache size.

    .PARAMETER ConfigureCacheSize
        Specifies if client cache size is enabled or disabled.

    .PARAMETER MaxCacheSize
        Specifies the maximum cache size by MB.

    .PARAMETER MaxCacheSizePercent
        Specifies the maximum cache size percentage.

    .PARAMETER EnableSuperPeer
        Specifies is peer cache source is enabled or disabled.

    .PARAMETER BroadcastPort
        Specifies the port for initial network broadcast.

    .PARAMETER DownloadPort
        Specifies the port for content download from peers.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $ClientSettingName,

        [Parameter()]
        [Boolean]
        $ConfigureBranchCache,

        [Parameter()]
        [Boolean]
        $EnableBranchCache,

        [Parameter()]
        [ValidateRange(1,100)]
        [UInt32]
        $MaxBranchCacheSizePercent,

        [Parameter()]
        [Boolean]
        $ConfigureCacheSize,

        [Parameter()]
        [ValidateRange(1,1048576)]
        [UInt32]
        $MaxCacheSize,

        [Parameter()]
        [ValidateRange(1,100)]
        [UInt32]
        $MaxCacheSizePercent,

        [Parameter()]
        [Boolean]
        $EnableSuperPeer,

        [Parameter()]
        [UInt32]
        $BroadcastPort,

        [Parameter()]
        [UInt32]
        $DownloadPort
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName

    try
    {
        if ($state.ClientSettingStatus -eq 'Absent')
        {
            throw ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        }

        if (($ConfigureBranchCache -eq $false) -and ($PSBoundParameters.ContainsKey('EnableBranchCache') -or $PSBoundParameters.ContainsKey('MaxBranchCacheSizePercent')))
        {
            throw $script:localizedData.DisabledBranchwithMax
        }

        if (($ConfigureCacheSize -eq $false) -and ($PSBoundParameters.ContainsKey('MaxCacheSize') -or $PSBoundParameters.ContainsKey('MaxCacheSizePercent')))
        {
            throw $script:localizedData.ConfigCacheFalseSize
        }

        if (($EnableSuperPeer -eq $false) -and ($PSBoundParameters.ContainsKey('BroadcastPort') -or $PSBoundParameters.ContainsKey('DownloadPort')))
        {
            throw $script:localizedData.DisableSuperBroad
        }

        if ($PSBoundParameters.ContainsKey('MaxCacheSizePercent') -and $ConfigureBranchCache -ne $true)
        {
            throw $script:localizedData.BranchMaxCache
        }

        $defaultValues = @('ConfigureBranchCache','ConfigureCacheSize','EnableSuperPeer','EnableBranchCache','MaxBranchCacheSizePercent','MaxCacheSize','MaxCacheSizePercent',
            'BroadcastPort','DownloadPort')

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($defaultValues -contains $param.Key)
            {
                if ($param.Value -ne $state[$param.Key])
                {
                    Write-Verbose -Message ($script:localizedData.SettingValue -f $param.Key, $param.Value)
                    $buildingParams += @{
                        $param.Key = $param.Value
                    }
                }
            }
        }

        if ($buildingParams)
        {
            if ($ClientSettingName -eq 'Default Client Agent Settings')
            {
                Set-CMClientSettingClientCache -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingClientCache -Name $ClientSettingName @buildingParams
            }
        }
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
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER ConfigureBranchCache
        Specifies if configure branch cache policy is enabled or disabled.

    .PARAMETER EnableBranchCache
        Specifies if branch cache is enabled or disabled.

    .PARAMETER MaxBranchCacheSizePercent
        Specifies the percentage of disk size maximum branch cache size.

    .PARAMETER ConfigureCacheSize
        Specifies if client cache size is enabled or disabled.

    .PARAMETER MaxCacheSize
        Specifies the maximum cache size by MB.

    .PARAMETER MaxCacheSizePercent
        Specifies the maximum cache size percentage.

    .PARAMETER EnableSuperPeer
        Specifies is peer cache source is enabled or disabled.

    .PARAMETER BroadcastPort
        Specifies the port for initial network broadcast.

    .PARAMETER DownloadPort
        Specifies the port for content download from peers.
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

        [Parameter(Mandatory = $true)]
        [String]
        $ClientSettingName,

        [Parameter()]
        [Boolean]
        $ConfigureBranchCache,

        [Parameter()]
        [Boolean]
        $EnableBranchCache,

        [Parameter()]
        [ValidateRange(1,100)]
        [UInt32]
        $MaxBranchCacheSizePercent,

        [Parameter()]
        [Boolean]
        $ConfigureCacheSize,

        [Parameter()]
        [ValidateRange(1,1048576)]
        [UInt32]
        $MaxCacheSize,

        [Parameter()]
        [ValidateRange(1,100)]
        [UInt32]
        $MaxCacheSizePercent,

        [Parameter()]
        [Boolean]
        $EnableSuperPeer,

        [Parameter()]
        [UInt32]
        $BroadcastPort,

        [Parameter()]
        [UInt32]
        $DownloadPort
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName
    $result = $true

    if ($state.ClientSettingStatus -eq 'Absent')
    {
        Write-Warning -Message ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        $result = $false
    }
    else
    {
        $defaultValues = @('ConfigureBranchCache','ConfigureCacheSize','EnableSuperPeer','EnableBranchCache','MaxBranchCacheSizePercent','MaxCacheSize','MaxCacheSizePercent',
            'BroadcastPort','DownloadPort')

        if (($ConfigureBranchCache -eq $false) -and ($PSBoundParameters.ContainsKey('EnableBranchCache') -or $PSBoundParameters.ContainsKey('MaxBranchCacheSizePercent')))
        {
            Write-Warning -Message $script:localizedData.DisabledBranchwithMax
            $badInput = $true
        }

        if (($ConfigureCacheSize -eq $false) -and ($PSBoundParameters.ContainsKey('MaxCacheSize') -or $PSBoundParameters.ContainsKey('MaxCacheSizePercent')))
        {
            Write-Warning -Message $script:localizedData.ConfigCacheFalseSize
            $badInput = $true
        }

        if (($EnableSuperPeer -eq $false) -and ($PSBoundParameters.ContainsKey('BroadcastPort') -or $PSBoundParameters.ContainsKey('DownloadPort')))
        {
            Write-Warning -Message $script:localizedData.DisableSuperBroad
            $badInput = $true
        }

        if ($PSBoundParameters.ContainsKey('MaxCacheSizePercent') -and $ConfigureBranchCache -ne $true)
        {
            Write-Warning -Message $script:localizedData.BranchMaxCache
            $badInput = $true
        }

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = $defaultValues
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose
    }

    if ($result -eq $false -or $badInput -eq $true)
    {
        $result = $false
    }
    else
    {
        $result = $true
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
