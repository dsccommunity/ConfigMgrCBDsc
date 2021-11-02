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
        $type = @('Default','Device','User')[$clientSetting.Type]
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting UserAndDeviceAffinity

        if ($settings)
        {
            if ($type -eq 'Default' -or $type -eq 'Device')
            {
                $console = $settings.ConsoleMinutes
                $intDays = $settings.IntervalDays
                $allowUser = [System.Convert]::ToBoolean([UInt32]$settings.AutoApproveAffinity)
            }

            if ($type -eq 'Default' -or $type -eq 'User')
            {
                $auto = [System.Convert]::ToBoolean([UInt32]$settings.AllowUserAffinity)
            }
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode            = $SiteCode
        ClientSettingName   = $ClientSettingName
        LogOnThresholdMins  = $console
        UsageThresholdDays  = $intDays
        AutoApproveAffinity = $allowUser
        AllowUserAffinity   = $auto
        ClientSettingStatus = $status
        ClientType          = $type
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER LogOnThresholdMins
        Specifies if user device affinity usage threshold in minutes.

    .PARAMETER UsageThresholdDays
        Specifies if user device affinity usage threshold in days.

    .PARAMETER AutoApproveAffinity
        Specifies allowing automatic configure user device affinity from usage data.

    .PARAMETER AllowUserAffinity
        Specifies allowing users to define their primary device.
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
        [ValidateRange(1,999999)]
        [UInt32]
        $LogOnThresholdMins,

        [Parameter()]
        [ValidateRange(1,99999)]
        [UInt32]
        $UsageThresholdDays,

        [Parameter()]
        [Boolean]
        $AutoApproveAffinity,

        [Parameter()]
        [Boolean]
        $AllowUserAffinity
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

        if ($state.ClientType -eq 'Default')
        {
            $defaultValues = @('LogOnThresholdMins','UsageThresholdDays','AutoApproveAffinity','AllowUserAffinity')
        }
        elseif ($state.ClientType -eq 'Device')
        {
            if ($PSBoundParameters.ContainsKey('AllowUserAffinity'))
            {
                Write-Warning -Message $script:localizedData.NonDefaultClient
            }

            $defaultValues = @('LogOnThresholdMins','UsageThresholdDays','AutoApproveAffinity')

        }
        elseif ($state.ClientType -eq 'User')
        {
            if ($PSBoundParameters.ContainsKey('LogOnThresholdMins') -or $PSBoundParameters.ContainsKey('UsageThresholdDays') -or
                $PSBoundParameters.ContainsKey('AutoApproveAffinity'))
            {
                Write-Warning -message $script:localizedData.NonUserSettings
            }

            $defaultValues = @('AllowUserAffinity')
        }

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
            if ($state.ClientType -eq 'Default')
            {
                Set-CMClientSettingUserAndDeviceAffinity -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingUserAndDeviceAffinity -Name $ClientSettingName @buildingParams
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

    .PARAMETER LogOnThresholdMins
        Specifies if user device affinity usage threshold in minutes.

    .PARAMETER UsageThresholdDays
        Specifies if user device affinity usage threshold in days.

    .PARAMETER AutoApproveAffinity
        Specifies allowing automatic configure user device affinity from usage data.

    .PARAMETER AllowUserAffinity
        Specifies allowing users to define their primary device.
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
        [ValidateRange(1,999999)]
        [UInt32]
        $LogOnThresholdMins,

        [Parameter()]
        [ValidateRange(1,99999)]
        [UInt32]
        $UsageThresholdDays,

        [Parameter()]
        [Boolean]
        $AutoApproveAffinity,

        [Parameter()]
        [Boolean]
        $AllowUserAffinity
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
        if ($state.ClientType -eq 'Default')
        {
            $defaultValues = @('LogOnThresholdMins','UsageThresholdDays','AutoApproveAffinity','AllowUserAffinity')
        }
        elseif ($state.ClientType -eq 'Device')
        {
            if ($PSBoundParameters.ContainsKey('AllowUserAffinity'))
            {
                Write-Warning -Message $script:localizedData.NonDefaultClient
            }

            $defaultValues = @('LogOnThresholdMins','UsageThresholdDays','AutoApproveAffinity')

        }
        elseif ($state.ClientType -eq 'User')
        {
            if ($PSBoundParameters.ContainsKey('LogOnThresholdMins') -or $PSBoundParameters.ContainsKey('UsageThresholdDays') -or
                $PSBoundParameters.ContainsKey('AutoApproveAffinity'))
            {
                Write-Warning -message $script:localizedData.NonUserSettings
            }

            $defaultValues = @('AllowUserAffinity')
        }

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = $defaultValues
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
