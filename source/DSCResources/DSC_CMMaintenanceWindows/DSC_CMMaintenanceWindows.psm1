$script:dscResourceCommonPath = Join-Path (Join-Path -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $PsScriptRoot)) -ChildPath Modules) -ChildPath DscResource.Common
$script:configMgrResourcehelper = Join-Path (Join-Path -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $PsScriptRoot)) -ChildPath Modules) -ChildPath ConfigMgrCBDsc.ResourceHelper

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER CollectionName
        Specifies the collection name for the maintenance window.

    .PARAMETER Name
        Specifies the name for the maintenance window.
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
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [String]
        $Name
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    if (Get-CMCollection -Name $CollectionName)
    {
        $collect = 'Present'
    }
    else
    {
        $collect = 'Absent'
    }

    $exWindows = Get-CMMaintenanceWindow -CollectionName $CollectionName -MaintenanceWindowName $Name
    $windows = $exWindows | where-Object -FilterScript {$_.Name -eq $Name}

    if ($windows)
    {
        $type = switch ($windows.ServiceWindowType)
        {
            1 { 'Any' }
            4 { 'SoftwareUpdatesOnly' }
            5 { 'TaskSequencesOnly' }
        }

        if ($windows.ServiceWindowSchedules)
        {
            $schedule = Get-CMSchedule -ScheduleString $windows.ServiceWindowSchedules
        }

        $sure = 'Present'
    }
    else
    {
        $sure = 'Absent'
    }

    return @{
        SiteCode           = $SiteCode
        CollectionName     = $CollectionName
        Name               = $Name
        ServiceWindowsType = $type
        IsEnabled          = $windows.IsEnabled
        Ensure             = $sure
        HourDuration       = $schedule.HourDuration
        MinuteDuration     = $schedule.MinuteDuration
        Start              = $schedule.Start
        ScheduleType       = $schedule.ScheduleType
        DayOfWeek          = $schedule.DayOfWeek
        MonthlyWeekOrder   = $schedule.WeekOrder
        DayOfMonth         = $schedule.MonthDay
        RecurInterval      = $schedule.RecurInterval
        Description        = $windows.Description
        CollectionStatus   = $collect
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER CollectionName
        Specifies the collection name for the maintenance window.

    .PARAMETER Name
        Specifies the name for the maintenance window.

    .PARAMETER ServiceWindowsType
        Specifies what the maintenance window will apply to.

    .PARAMETER Start
        Specifies the start date and start time for the maintenance window Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the maintenance window.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyByWeek
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .PARAMETER HourDuration
        Specifies the duration for the maintenance window in hours, max value 23.

    .PARAMETER MinuteDuration
        Specifies the duration for the maintenance window in minutes, max value 59.

    .PARAMETER IsEnabled
        Specifies if the maintenance window is enabled, default value is enabled.

    .PARAMETER Ensure
        Specifies whether the maintenance window is present or absent.
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
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [ValidateSet('Any','SoftwareUpdatesOnly','TaskSequencesOnly')]
        [String]
        $ServiceWindowsType,

        [Parameter()]
        [String]
        $Start,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','None')]
        [String]
        $ScheduleType,

        [Parameter()]
        [UInt32]
        $RecurInterval,

        [Parameter()]
        [ValidateSet('First','Second','Third','Fourth','Last')]
        [String]
        $MonthlyWeekOrder,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String]
        $DayOfWeek,

        [Parameter()]
        [ValidateRange(0,31)]
        [UInt32]
        $DayOfMonth,

        [Parameter()]
        [ValidateRange(1,23)]
        [UInt32]
        $HourDuration,

        [Parameter()]
        [ValidateRange(5,59)]
        [UInt32]
        $MinuteDuration,

        [Parameter()]
        [Boolean]
        $IsEnabled = $true,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -CollectionName $CollectionName -Name $Name -SiteCode $SiteCode

        if ($Ensure -eq 'Present')
        {
            if ($state.CollectionStatus -eq 'Absent')
            {
                throw ($script:localizedData.MissingCollection -f $CollectionName)
            }

            if ((-not $PSBoundParameters.ContainsKey('ScheduleType')) -or
                (($PSBoundParameters.ContainsKey('ScheduleType')) -and
                (-not $PSBoundParameters.ContainsKey('MinuteDuration') -and
                -not $PSBoundParameters.ContainsKey('HourDuration'))))
            {
                throw ($script:localizedData.MissingWindowParam -f $Name)
            }

            if ($PSBoundParameters.ContainsKey('HourDuration') -and $PSBoundParameters.ContainsKey('MinuteDuration'))
            {
                throw $script:localizedData.MixedDuration
            }

            if ($PSBoundParameters.ContainsKey('ServiceWindowsType') -and $state.ServiceWindowsType -ne $ServiceWindowsType)
            {
                Write-Verbose -Message ($script:localizedData.ChangingApplyTo -f $state.ServiceWindowsType, $ServiceWindowsType)
                $buildingParams += @{
                    ApplyTo = $ServiceWindowsType
                }
            }

            if ($state.IsEnabled -ne $IsEnabled)
            {
                Write-Verbose -Message ($script:localizedData.ChangingIsEnabled -f $state.IsEnabled, $IsEnabled)
                $buildingParams += @{
                    IsEnabled = $IsEnabled
                }
            }

            if ($ScheduleType)
            {
                $valuesToValidate = @('ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth','Start',
                                      'HourDuration','MinuteDuration')
                foreach ($item in $valuesToValidate)
                {
                    if ($PSBoundParameters.ContainsKey($item))
                    {
                        $scheduleCheck += @{
                            $item = $PSBoundParameters[$item]
                        }
                    }
                }

                $schedResult = Test-CMSchedule @scheduleCheck -State $state
            }

            if ($schedResult -eq $false)
            {
                $sched = Set-CMSchedule @scheduleCheck
                $newSchedule = New-CMSchedule @sched

                Write-Verbose -Message $script:localizedData.NewSchedule
                $buildingParams += @{
                    Schedule = $newSchedule
                }
            }

            if ($state.Ensure -eq 'Absent')
            {
                $buildingParams += @{
                    CollectionName = $CollectionName
                    Name           = $Name
                }

                Write-Verbose -Message $script:localizedData.NewWindow
                New-CMMaintenanceWindow @buildingParams
            }
            else
            {
                $buildingParams += @{
                    CollectionName        = $CollectionName
                    MaintenanceWindowName = $Name
                }

                Write-Verbose -Message $script:localizedData.ModifyWindow
                Set-CMMaintenanceWindow @buildingParams
            }
        }
        elseif ($Ensure -eq 'Absent' -and $state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveMW -f $Name)
            Remove-CMMaintenanceWindow -CollectionName $CollectionName -MaintenanceWindowName $Name
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

    .PARAMETER CollectionName
        Specifies the collection name for the maintenance window.

    .PARAMETER Name
        Specifies the name for the maintenance window.

    .PARAMETER ServiceWindowsType
        Specifies what the maintenance window will apply to.

    .PARAMETER Start
        Specifies the start date and start time for the maintenance window Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the maintenance window.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyByWeek
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .PARAMETER HourDuration
        Specifies the duration for the maintenance window in hours, max value 23.

    .PARAMETER MinuteDuration
        Specifies the duration for the maintenance window in minutes, max value 59.

    .PARAMETER IsEnabled
        Specifies if the maintenance window is enabled, default value is enabled.

    .PARAMETER Ensure
        Specifies whether the maintenance window is present or absent.
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
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [ValidateSet('Any','SoftwareUpdatesOnly','TaskSequencesOnly')]
        [String]
        $ServiceWindowsType,

        [Parameter()]
        [String]
        $Start,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','None')]
        [String]
        $ScheduleType,

        [Parameter()]
        [UInt32]
        $RecurInterval,

        [Parameter()]
        [ValidateSet('First','Second','Third','Fourth','Last')]
        [String]
        $MonthlyWeekOrder,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String]
        $DayOfWeek,

        [Parameter()]
        [ValidateRange(0,31)]
        [UInt32]
        $DayOfMonth,

        [Parameter()]
        [ValidateRange(1,23)]
        [UInt32]
        $HourDuration,

        [Parameter()]
        [ValidateRange(5,59)]
        [UInt32]
        $MinuteDuration,

        [Parameter()]
        [Boolean]
        $IsEnabled = $true,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -CollectionName $CollectionName -Name $Name
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($PSBoundParameters.ContainsKey('HourDuration') -and $PSBoundParameters.ContainsKey('MinuteDuration'))
        {
            Write-Warning -Message $script:localizedData.MixedDuration
        }

        if ($state.CollectionStatus -eq 'Absent')
        {
            Write-Warning -Message ($script:localizedData.MissingCollection -f $CollectionName)
            $result = $false
        }
        elseif ($state.Ensure -eq 'Absent')
        {
            if ((-not $PSBoundParameters.ContainsKey('ScheduleType')) -or
                (($PSBoundParameters.ContainsKey('ScheduleType')) -and
                (-not $PSBoundParameters.ContainsKey('MinuteDuration') -and
                -not $PSBoundParameters.ContainsKey('HourDuration'))))
            {
                Write-Warning -Message ($script:localizedData.MissingWindowParam -f $Name)
            }

            Write-Verbose -Message ($script:localizedData.MissingWindow -f $Name)
            $result = $false
        }
        else
        {
            $valuesToCheck = @('CollectionName','Name','IsEnabled','Ensure','ServiceWindowsType')

            if (-not $PSBoundParameters.ContainsKey('IsEnabled'))
            {
                $PSBoundParameters.Add('IsEnabled',$true)
            }

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = $valuesToCheck
            }

            $mainState = Test-DscParameterState @testParams -Verbose

            if ($ScheduleType)
            {
                $valuesToValidate = @('ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth','Start',
                                      'HourDuration','MinuteDuration')
                foreach ($item in $valuesToValidate)
                {
                    if ($PSBoundParameters.ContainsKey($item))
                    {
                        $scheduleCheck += @{
                            $item = $PSBoundParameters[$item]
                        }
                    }
                }

                $schedResult = Test-CMSchedule @scheduleCheck -State $state
            }

            if ($mainState -ne $true -or $schedResult -ne $true -or $result -ne $true)
            {
                $result = $false
            }
            else
            {
                $result = $true
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message $script:localizedData.Absent
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
