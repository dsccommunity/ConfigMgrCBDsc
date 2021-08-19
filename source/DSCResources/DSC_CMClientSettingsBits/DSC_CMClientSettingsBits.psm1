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

    .PARAMETER EnableBitsMaxBandwidth
        Specifies if limit the maximum network bandwidth for BITS background transfers is enabled or disabled.
        Not used in GET.
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
        $ClientSettingName,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $EnableBitsMaxBandwidth
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $clientSetting = Get-CMClientSetting -Name $ClientSettingName

    if ($clientSetting)
    {
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting BackgroundIntelligentTransfer

        if ($settings)
        {
            $bitsEnabled = [System.Convert]::ToBoolean($settings.EnableBitsMaxBandwidth)
            $beginHour = $settings.MaxBandwidthValidFrom
            $endHour = $settings.MaxBandwidthValidTo
            $transOnSchedule = $settings.MaxTransferRateOnSchedule
            $transOffSchedule = $settings.MaxTransferRateOffSchedule
            $enableOfSchedule = [System.Convert]::ToBoolean($settings.EnableDownloadOffSchedule)
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                   = $SiteCode
        ClientSettingName          = $ClientSettingName
        EnableBitsMaxBandwidth     = $bitsEnabled
        MaxBandwidthBeginHr        = $beginHour
        MaxBandwidthEndHr          = $endHour
        MaxTransferRateOnSchedule  = $transOnSchedule
        EnableDownloadOffSchedule  = $enableOfSchedule
        MaxTransferRateOffSchedule = $transOffSchedule
        ClientSettingStatus        = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER EnableBitsMaxBandwidth
        Specifies if limit the maximum network bandwidth for BITS background transfers is enabled or disabled.

    .PARAMETER MaxBandwidthBeginHr
        Specifies the throttling window start time, use 0 for 12 a.m. and 23 for 11 p.m..

    .PARAMETER MaxBandwidthEndHr
        Specifies the throttling window end time, use 0 for 12 a.m. and 23 for 11 p.m..

    .PARAMETER MaxTransferRateOnSchedule
        Specifies the maximum transfer rate during throttling window in Kbps.

    .PARAMETER EnableDownloadOffSchedule
        Specifies if BITS downloads are allowed outside the throttling window.

    .PARAMETER MaxTransferRateOffSchedule
        Specifies the maximum transfer rate outside the throttling window in Kbps.
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

        [Parameter(Mandatory = $true)]
        [Boolean]
        $EnableBitsMaxBandwidth,

        [Parameter()]
        [ValidateRange(0,23)]
        [UInt32]
        $MaxBandwidthBeginHr,

        [Parameter()]
        [ValidateRange(0,23)]
        [UInt32]
        $MaxBandwidthEndHr,

        [Parameter()]
        [ValidateRange(1,9999)]
        [UInt32]
        $MaxTransferRateOnSchedule,

        [Parameter()]
        [Boolean]
        $EnableDownloadOffSchedule,

        [Parameter()]
        [ValidateRange(1,999999)]
        [UInt32]
        $MaxTransferRateOffSchedule
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName -EnableBitsMaxBandwidth $EnableBitsMaxBandwidth

    try
    {
        if ($state.ClientSettingStatus -eq 'Absent')
        {
            throw ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        }

        if ($EnableBitsMaxBandwidth -eq $true)
        {
            $defaultValues = @('EnableBitsMaxBandwidth','MaxBandwidthBeginHr','MaxBandwidthEndHr','MaxTransferRateOnSchedule',
                'EnableDownloadOffSchedule','MaxTransferRateOffSchedule')

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
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.SettingEnable -f $state.EnableBitsMaxBandwidth, $EnableBitsMaxBandwidth)

            $buildingParams = @{
                EnableBitsMaxBandwidth = $false
            }
        }

        if ($buildingParams)
        {
            if ($ClientSettingName -eq 'Default Client Agent Settings')
            {
                Set-CMClientSettingBackgroundIntelligentTransfer -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingBackgroundIntelligentTransfer -Name $ClientSettingName @buildingParams
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

    .PARAMETER EnableBitsMaxBandwidth
        Specifies if limit the maximum network bandwidth for BITS background transfers is enabled or disabled.

    .PARAMETER MaxBandwidthBeginHr
        Specifies the throttling window start time, in 2 digit form.

    .PARAMETER MaxBandwidthEndHr
        Specifies the throttling window end time, in 2 digit form.

    .PARAMETER MaxTransferRateOnSchedule
        Specifies the maximum transfer rate during throttling window in Kbps.

    .PARAMETER EnableDownloadOffSchedule
        Specifies if BITS downloads are allowed outside the throttling window.

    .PARAMETER MaxTransferRateOffSchedule
        Specifies the maximum transfer rate outside the throttling window in Kbps.
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

        [Parameter(Mandatory = $true)]
        [Boolean]
        $EnableBitsMaxBandwidth,

        [Parameter()]
        [ValidateRange(0,23)]
        [UInt32]
        $MaxBandwidthBeginHr,

        [Parameter()]
        [ValidateRange(0,23)]
        [UInt32]
        $MaxBandwidthEndHr,

        [Parameter()]
        [ValidateRange(1,9999)]
        [UInt32]
        $MaxTransferRateOnSchedule,

        [Parameter()]
        [Boolean]
        $EnableDownloadOffSchedule,

        [Parameter()]
        [ValidateRange(1,999999)]
        [UInt32]
        $MaxTransferRateOffSchedule
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName -EnableBitsMaxBandwidth $EnableBitsMaxBandwidth
    $result = $true

    if ($state.ClientSettingStatus -eq 'Absent')
    {
        Write-Warning -Message ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        $result = $false
    }
    else
    {
        if ($EnableBitsMaxBandwidth -eq $true)
        {
            $defaultValues = @('EnableBitsMaxBandwidth','MaxBandwidthBeginHr','MaxBandwidthEndHr','MaxTransferRateOnSchedule',
                'EnableDownloadOffSchedule','MaxTransferRateOffSchedule')

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = $defaultValues
            }

            $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose
        }
        elseif ([string]::IsNullOrEmpty($state.EnableBitsMaxBandwidth) -or $state.EnableBitsMaxBandwidth -eq $true)
        {
            Write-Verbose -Message ($script:localizedData.SettingEnable -f $state.EnableBitsMaxBandwidth, $EnableBitsMaxBandwidth)
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
