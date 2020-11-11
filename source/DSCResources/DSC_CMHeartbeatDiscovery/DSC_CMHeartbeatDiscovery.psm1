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

    .PARAMETER Enabled
        Specifies the enablement of the Heatbeat discovery method.

        Not used in Get-TargetResource.
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
        [Boolean]
        $Enabled
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $heartbeat = (Get-CMDiscoveryMethod -Name HeartbeatDiscovery -SiteCode $SiteCode).Props
    $state = ($heartbeat | Where-Object -FilterScript {$_.PropertyName -eq 'Enable Heartbeat DDR'}).Value
    $heartbeatSchedule = ($heartbeat | Where-Object -FilterScript {$_.PropertyName -eq 'DDR Refresh Interval'}).Value2

    $scheduleConvert = ConvertTo-ScheduleInterval -ScheduleString $heartbeatSchedule

    return @{
        SiteCode         = $SiteCode
        Enabled          = $state
        ScheduleInterval = $scheduleConvert.Interval
        ScheduleCount    = $scheduleConvert.Count
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER Enabled
        Specifies the enablement of the Heatbeat discovery method.

    .PARAMETER ScheduleInterval
        Specifies the time when the scheduled event recurs in hours and days.

    .PARAMETER ScheduleCount
        Specifies how often the recur interval is run. If hours are specified the max value
        is 23. Anything over 23 will result in 23 to be set. If days are specified the max value
        is 31. Anything over 31 will result in 31 to be set.
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
        [Boolean]
        $Enabled,

        [Parameter()]
        [ValidateSet('Hours','Days')]
        [String]
        $ScheduleInterval,

        [Parameter()]
        [UInt32]
        $ScheduleCount
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode -Enabled $Enabled

        if ($Enabled -ne $state.Enabled)
        {
            Write-Verbose -Message ($script:localizedData.SettingEnable -f $state.Enabled, $Enabled)
            $buildingParams = @{
                Enabled = $Enabled
            }
        }

        if ($Enabled -eq $true)
        {
            if (($PSBoundParameters.ContainsKey('ScheduleInterval') -and -not $PSBoundParameters.ContainsKey('ScheduleCount')) -or
                ($PSBoundParameters.ContainsKey('ScheduleCount') -and -not $PSBoundParameters.ContainsKey('ScheduleInterval')))
            {
                throw $script:localizedData.IntervalCount
            }

            if ($PSBoundParameters.ContainsKey('ScheduleInterval') -and $PSBoundParameters.ContainsKey('ScheduleCount'))
            {

                if ($ScheduleInterval -eq 'Days' -and $ScheduleCount -ge 32)
                {
                    Write-Warning -Message ($script:localizedData.MaxIntervalDays -f $ScheduleCount)
                    $scheduleCheck = 31
                }
                elseif ($ScheduleInterval -eq 'Hours' -and $ScheduleCount -ge 24)
                {
                    Write-Warning -Message ($script:localizedData.MaxIntervalHours -f $ScheduleCount)
                    $scheduleCheck = 23
                }
                else
                {
                    $scheduleCheck = $ScheduleCount
                }

                if ($ScheduleInterval -ne $state.ScheduleInterval)
                {
                    Write-Verbose -Message ($script:localizedData.SIntervalSet -f $ScheduleInterval)
                    $setSchedule = $true
                }

                if ($scheduleCheck -ne $state.ScheduleCount)
                {
                    Write-Verbose -Message ($script:localizedData.SCountSet -f $ScheduleCount)
                    $setSchedule = $true
                }

                if ($setSchedule -eq $true)
                {
                    $pScheduleSet = @{
                        RecurInterval = $ScheduleInterval
                        RecurCount    = $ScheduleCount
                    }

                    $pschedule = New-CMSchedule @pScheduleSet

                    $buildingParams += @{
                        PollingSchedule = $pSchedule
                    }
                }
            }
        }

        if ($buildingParams)
        {
            Set-CMDiscoveryMethod -Heartbeat -SiteCode $SiteCode @buildingParams
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
        Specifies the site code for Configuration Manager site.

    .PARAMETER Enabled
        Specifies the enablement of the Heatbeat discovery method.

    .PARAMETER ScheduleInterval
        Specifies the time when the scheduled event recurs in hours and days.

    .PARAMETER ScheduleCount
        Specifies how often the recur interval is run. If hours are specified the max value
        is 23. Anything over 23 will result in 23 to be set. If days are specified the max value
        is 31. Anything over 31 will result in 31 to be set.
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
        [Boolean]
        $Enabled,

        [Parameter()]
        [ValidateSet('Hours','Days')]
        [String]
        $ScheduleInterval,

        [Parameter()]
        [UInt32]
        $ScheduleCount
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -Enabled $Enabled
    $result = $true

    if ($Enabled -ne $state.Enabled)
    {
        Write-Verbose -Message ($script:localizedData.EnableStatus -f $Enabled, $state.Enabled)
        $result = $false
    }

    if (($PSBoundParameters.ContainsKey('ScheduleInterval') -and -not $PSBoundParameters.ContainsKey('ScheduleCount')) -or
        ($PSBoundParameters.ContainsKey('ScheduleCount') -and -not $PSBoundParameters.ContainsKey('ScheduleInterval')))
    {
        Write-Verbose -Message $script:localizedData.IntervalCountTest
        $result = $false
    }

    if ($PSBoundParameters.ContainsKey('ScheduleInterval') -and $PSBoundParameters.ContainsKey('ScheduleCount'))
    {
        if ($ScheduleInterval -eq 'Days' -and $ScheduleCount -ge 32)
        {
            Write-Warning -Message ($script:localizedData.MaxIntervalDays -f $ScheduleCount)
            $scheduleCheck = 31
        }
        elseif ($ScheduleInterval -eq 'Hours' -and $ScheduleCount -ge 24)
        {
            Write-Warning -Message ($script:localizedData.MaxIntervalHours -f $ScheduleCount)
            $scheduleCheck = 23
        }
        else
        {
            $scheduleCheck = $ScheduleCount
        }

        if ($ScheduleInterval -ne $state.ScheduleInterval)
        {
            Write-Verbose -Message ($script:localizedData.SIntervalTest -f $ScheduleInterval, $State.ScheduleInterval)
            $result = $false
        }

        if ($scheduleCheck -ne $state.ScheduleCount)
        {
            Write-Verbose -Message ($script:localizedData.SCountTest -f $scheduleCheck, $State.ScheduleCount)
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource
