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
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting SoftwareDeployment

        if ($settings)
        {
            $schedule = Get-CMSchedule -ScheduleString $settings.EvaluationSchedule
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
        Start               = $schedule.Start
        ScheduleType        = $schedule.ScheduleType
        DayOfWeek           = $schedule.DayofWeek
        MonthlyWeekOrder    = $schedule.WeekOrder
        DayofMonth          = $schedule.MonthDay
        RecurInterval       = $schedule.RecurInterval
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

    .PARAMETER Start
        Specifies the start date and start time for the software deployment schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the software deployment schedule.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyByWeek
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.
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
        [String]
        $Start,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','Hours','Minutes','None')]
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
        $DayOfMonth
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName
    $schedResult = $true

    try
    {
        if ($state.ClientSettingStatus -eq 'Absent')
        {
            throw ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        }

        if ($state.ClientType -eq 'User')
        {
            throw $script:localizedData.WrongClientType
        }

        if ((-not $PSBoundParameters.ContainsKey('ScheduleType')) -and ($PSBoundParameters.ContainsKey('Start') -or
            $PSBoundParameters.ContainsKey('RecurInterval') -or $PSBoundParameters.ContainsKey('MonthlyWeekOrder') -or
            $PSBoundParameters.ContainsKey('DayOfWeek') -or $PSBoundParameters.ContainsKey('DayOfMonth')))
        {
            throw $script:localizedData.RequiredSchedule
        }

        if ($ScheduleType)
        {
            $valuesToValidate = @('ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth','Start')
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

        if ($buildingParams)
        {
            if ($state.ClientType -eq 'Default')
            {
                Set-CMClientSettingSoftwareDeployment -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingSoftwareDeployment -Name $ClientSettingName @buildingParams
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

    .PARAMETER Start
        Specifies the start date and start time for the software deployment schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the software deployment schedule.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyByWeek
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.
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
        [String]
        $Start,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','Hours','Minutes','None')]
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
        $DayOfMonth
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
    elseif ($state.ClientType -eq 'User')
    {
        Write-Warning -Message $script:localizedData.WrongClientType
        $result = $false
    }
    else
    {
        if ((-not $PSBoundParameters.ContainsKey('ScheduleType')) -and ($PSBoundParameters.ContainsKey('Start') -or
            $PSBoundParameters.ContainsKey('RecurInterval') -or $PSBoundParameters.ContainsKey('MonthlyWeekOrder') -or
            $PSBoundParameters.ContainsKey('DayOfWeek') -or $PSBoundParameters.ContainsKey('DayOfMonth')))
        {
            Write-Warning -Message $script:localizedData.RequiredSchedule
            $badInput = $true
        }

        if ($ScheduleType)
        {
            $valuesToValidate = @('ScheduleType','RecurInterval','MonthlyWeekOrder','DayOfWeek','DayOfMonth','Start')
            foreach ($item in $valuesToValidate)
            {
                if ($PSBoundParameters.ContainsKey($item))
                {
                    $scheduleCheck += @{
                        $item = $PSBoundParameters[$item]
                    }
                }
            }

            $result = Test-CMSchedule @scheduleCheck -State $state
        }
    }

    if ($result -eq $false -or $badInput -eq $true)
    {
        $return = $false
    }
    else
    {
        $return = $true
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $return)
    Set-Location -Path "$env:temp"
    return $return
}

Export-ModuleMember -Function *-TargetResource
