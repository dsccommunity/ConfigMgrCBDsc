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

    .Parameter Enable
        Specifies if compliance evaluation on clients is enabled or disabled.
        Not used in Get
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
        $Enable
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $clientSetting = Get-CMClientSetting -Name $ClientSettingName

    if ($clientSetting)
    {
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting HardwareInventory

        if ($settings)
        {
            $enabled = [System.Convert]::ToBoolean($settings.Enabled)
            $randomDelay = $settings.MaxRandomDelayMinutes
            $schedule = Get-CMSchedule -ScheduleString $settings.Schedule

            if ($ClientSettingName -eq 'Default Client Agent Settings')
            {
                $thirdParty = $settings.Max3rdPartyMIFSize
                $mifFile = switch ($settings.MIFCollection)
                {
                    '0'  { 'None' }
                    '4'  { 'CollectNoIdMifFile' }
                    '8'  { 'CollectIdMifFile' }
                    '12' { 'CollectIdMifAndNoIdMifFile' }
                }
            }
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                 = $SiteCode
        ClientSettingName        = $ClientSettingName
        Enable                   = $enabled
        Start                    = $schedule.Start
        ScheduleType             = $schedule.ScheduleType
        DayOfWeek                = $schedule.DayofWeek
        MonthlyWeekOrder         = $schedule.WeekOrder
        DayofMonth               = $schedule.MonthDay
        RecurInterval            = $schedule.RecurInterval
        MaxRandomDelayMins       = $randomDelay
        CollectMifFile           = $mifFile
        MaxThirdPartyMifSize     = $thirdParty
        ClientSettingStatus      = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .Parameter Enable
        Specifies if hardware inventory for clients is enabled or disabled.

    .Parameter MaxRandomDelayMins
        Specifies the maximum random delay in minutes.

    .PARAMETER Start
        Specifies the start date and start time for the hardware inventory schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the hardware inventory schedule.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyByWeek
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .Parameter CollectMifFile
        Specifies the collected MIF files.

    .Parameter MaxThirdPartyMifSize
        Specifies the maximum custom MIF file size in KB.
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
        $Enable,

        [Parameter()]
        [ValidateRange(0,480)]
        [UInt32]
        $MaxRandomDelayMins,

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
        $DayOfMonth,

        [Parameter()]
        [ValidateSet('None','CollectNoIdMifFile','CollectIdMifFile','CollectIdMifAndNoIdMifFile')]
        [String]
        $CollectMifFile,

        [Parameter()]
        [ValidateRange(1,5120)]
        [UInt32]
        $MaxThirdPartyMifSize
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName -Enable $Enable

    try
    {
        if ($state.ClientSettingStatus -eq 'Absent')
        {
            throw ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        }

        if ($Enable -eq $true)
        {
            if ((-not $PSBoundParameters.ContainsKey('ScheduleType')) -and ($PSBoundParameters.ContainsKey('Start') -or
                $PSBoundParameters.ContainsKey('RecurInterval') -or $PSBoundParameters.ContainsKey('MonthlyWeekOrder') -or
                $PSBoundParameters.ContainsKey('DayOfWeek') -or $PSBoundParameters.ContainsKey('DayOfMonth')))
            {
                throw 'In order to create a schedule you must specify ScheduleType'
            }

            if ($ClientSettingName -eq 'Default Client Agent Settings')
            {
                $defaultValues = @('Enable','MaxRandomDelayMins','CollectMifFile','MaxThirdPartyMifSize')
            }
            else
            {
                if ($PSBoundParameters.ContainsKey('CollectMifFile') -or $PSBoundParameters.ContainsKey('MaxThirdPartyMifSize'))
                {
                    Write-Warning -Message 'You can only specify these settings if configuring the Default Client Agent Settings, ignoring CollectMifFile and MaxThirdPartyMifSize'
                }

                $defaultValues = @('Enable','MaxRandomDelayMins')
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
        }
        elseif ($state.Enable -eq $true)
        {
            if ($PSBoundParameters.ContainsKey('MaxRandomDelayMins') -or $PSBoundParameters.ContainsKey('Start') -or
                $PSBoundParameters.ContainsKey('ScheduleType') -or $PSBoundParameters.ContainsKey('RecurInterval') -or
                $PSBoundParameters.ContainsKey('MonthlyWeekOrder') -or $PSBoundParameters.ContainsKey('DayOfWeek') -or
                $PSBoundParameters.ContainsKey('DayOfMonth') -or $PSBoundParameters.ContainsKey('CollectMifFile') -or
                $PSBoundParameters.ContainsKey('MaxThirdPartyMifSize'))
            {
                Write-Warning -Message 'In order to set a schedule, MaxRandomDelayMins CollectMifFile, or MaxThirdPartyMifSize, Enable must be set to true, ignoring settings'
            }

            $buildingParams = @{
                Enable = $false
            }
        }

        if ($buildingParams)
        {
            if ($ClientSettingName -eq 'Default Client Agent Settings')
            {
                Set-CMClientSettingHardwareInventory -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingHardwareInventory -Name $ClientSettingName @buildingParams
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

    .Parameter Enable
        Specifies if hardware inventory for clients is enabled or disabled.

    .Parameter MaxRandomDelayMins
        Specifies the maximum random delay in minutes.

    .PARAMETER Start
        Specifies the start date and start time for the hardware inventory schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the hardware inventory schedule.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyByWeek
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .Parameter CollectMifFile
        Specifies the collected MIF files.

    .Parameter MaxThirdPartyMifSize
        Specifies the maximum custom MIF file size in KB.
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
        $Enable,

        [Parameter()]
        [ValidateRange(0,480)]
        [UInt32]
        $MaxRandomDelayMins,

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
        $DayOfMonth,

        [Parameter()]
        [ValidateSet('None','CollectNoIdMifFile','CollectIdMifFile','CollectIdMifAndNoIdMifFile')]
        [String]
        $CollectMifFile,

        [Parameter()]
        [ValidateRange(1,5120)]
        [UInt32]
        $MaxThirdPartyMifSize
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName -Enable $Enable
    $result = $true
    $schedResult = $true

    if ($state.ClientSettingStatus -eq 'Absent')
    {
        Write-Warning -Message ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        $result = $false
    }
    else
    {
        if ($Enable -eq $true)
        {
            if ((-not $PSBoundParameters.ContainsKey('ScheduleType')) -and ($PSBoundParameters.ContainsKey('Start') -or
                $PSBoundParameters.ContainsKey('RecurInterval') -or $PSBoundParameters.ContainsKey('MonthlyWeekOrder') -or
                $PSBoundParameters.ContainsKey('DayOfWeek') -or $PSBoundParameters.ContainsKey('DayOfMonth')))
            {
                Write-Warning -Message 'In order to create a schedule you must specify ScheduleType'
                $badInput = $true
            }

            if ($ClientSettingName -eq 'Default Client Agent Settings')
            {
                $defaultValues = @('Enable','MaxRandomDelayMins','CollectMifFile','MaxThirdPartyMifSize')
            }
            else
            {
                if ($PSBoundParameters.ContainsKey('CollectMifFile') -or $PSBoundParameters.ContainsKey('MaxThirdPartyMifSize'))
                {
                    Write-Warning -Message 'You can only specify these settings if configuring the Default Client Agent Settings, ignoring CollectMifFile and MaxThirdPartyMifSize'
                }

                $defaultValues = @('Enable','MaxRandomDelayMins')
            }

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = $defaultValues
            }

            $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

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

        }
        else
        {
            if ($PSBoundParameters.ContainsKey('MaxRandomDelayMins') -or $PSBoundParameters.ContainsKey('Start') -or
                $PSBoundParameters.ContainsKey('ScheduleType') -or $PSBoundParameters.ContainsKey('RecurInterval') -or
                $PSBoundParameters.ContainsKey('MonthlyWeekOrder') -or $PSBoundParameters.ContainsKey('DayOfWeek') -or
                $PSBoundParameters.ContainsKey('DayOfMonth') -or $PSBoundParameters.ContainsKey('CollectMifFile') -or
                $PSBoundParameters.ContainsKey('MaxThirdPartyMifSize'))
            {
                Write-Warning -Message 'In order to set a schedule, MaxRandomDelayMins CollectMifFile, or MaxThirdPartyMifSize, Enable must be set to true, ignoring settings'
            }

            if ($state.Enable -eq $true)
            {
                Write-Verbose -Message $script:localizedData.TestDisabled
                $result = $false
            }
        }
    }

    if ($result -eq $false -or $schedResult -eq $false -or $badInput -eq $true)
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
