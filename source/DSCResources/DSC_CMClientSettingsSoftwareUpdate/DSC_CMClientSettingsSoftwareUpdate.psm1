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
        Specifies if software update policy is enabled or disabled.
        Not Used in Get.
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
        $type = @('Default','Device','User')[$clientSetting.Type]
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting SoftwareUpdates

        if ($settings)
        {
            $enabled = [System.Convert]::ToBoolean($settings.Enabled)

            if ($enabled -eq $true)
            {
                $scanSchedule = Get-CMSchedule -ScheduleString $settings.ScanSchedule
                $evalSchedule = Get-CMSchedule -ScheduleString $settings.EvaluationSchedule

                if ([UInt32]$settings.AssignmentBatchingTimeout -eq 0)
                {
                    $enforce = $false
                }
                elseif ([UInt32]$settings.AssignmentBatchingTimeout -ge 86400)
                {
                    $enforce = $true
                    $unitTime = 'Days'
                    $finalValue = $($settings.AssignmentBatchingTimeout)/86400
                }
                else
                {
                    $enforce = $true
                    $unitTime = 'Hours'
                    $finalValue = $settings.AssignmentBatchingTimeout/3600
                }

                $express = [System.Convert]::ToBoolean($settings.EnableExpressUpdates)
                $expressPort = [UInt32]$settings.ExpressUpdatesPort
                $office = [System.Convert]::ToBoolean([UInt32]$settings.O365Management)
                $thirdParty = [System.Convert]::ToBoolean($settings.EnableThirdPartyUpdates)
            }
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                = $SiteCode
        ClientSettingName       = $ClientSettingName
        Enable                  = $enabled
        ScanStart               = $scanSchedule.Start
        ScanScheduleType        = $scanSchedule.ScheduleType
        ScanDayOfWeek           = $scanSchedule.DayofWeek
        ScanMonthlyWeekOrder    = $scanSchedule.WeekOrder
        ScanDayofMonth          = $scanSchedule.MonthDay
        ScanRecurInterval       = $scanSchedule.RecurInterval
        EvalStart               = $evalSchedule.Start
        EvalScheduleType        = $evalSchedule.ScheduleType
        EvalDayOfWeek           = $evalSchedule.DayofWeek
        EvalMonthlyWeekOrder    = $evalSchedule.WeekOrder
        EvalDayofMonth          = $evalSchedule.MonthDay
        EvalRecurInterval       = $evalSchedule.RecurInterval
        EnforceMandatory        = $enforce
        TimeUnit                = $unitTime
        BatchingTimeout         = $finalValue
        EnableDeltaDownload     = $express
        DeltaDownloadPort       = $expressPort
        Office365ManagementType = $office
        EnableThirdPartyUpdates = $thirdParty
        ClientSettingStatus     = $status
        ClientType              = $type
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
        Specifies if software update for clients is enabled or disabled.

    .PARAMETER ScanStart
        Specifies the start date and start time for the software update scan schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScanScheduleType
        Specifies the schedule type for the software update scan schedule.

    .PARAMETER ScanRecurInterval
        Specifies how often the ScanScheduleType is run.

    .PARAMETER ScanMonthlyByWeek
        Specifies week order for MonthlyByWeek scan schedule type.

    .PARAMETER ScanDayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly scan schedules.

    .PARAMETER ScanDayOfMonth
        Specifies the day number for MonthlyByDay scan schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .PARAMETER EvalStart
        Specifies the start date and start time for the software update eval schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER EvalScheduleType
        Specifies the schedule type for the software update eval schedule.

    .PARAMETER EvalRecurInterval
        Specifies how often the EvalScheduleType is run.

    .PARAMETER EvalMonthlyByWeek
        Specifies week order for MonthlyByWeek eval schedule type.

    .PARAMETER EvalDayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly eval schedules.

    .PARAMETER EvalDayOfMonth
        Specifies the day number for MonthlyByDay eval schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .Parameter EnforceMandatory
        Specifies if any software update deployment deadline is
        reached to install all deployments with dealing coming within a specific time period.

    .Parameter TimeUnit
        Specifies the unit of time, hours or days time frame to install pending software updates.

    .Parameter BatchingTimeOut
        Specifies the time within TimeUnit to install the depending updates.

    .Parameter EnableDeltaDownload
        Specifies if client are allowed to download delta content when available.

    .Parameter DeltaDownloadPort
        Specifies the port that clients will use to receive requests for delta content.

    .Parameter Office365ManagementType
        Specifies if management of the Office 365 client is enabled.

    .Parameter EnableThirdPartyUpdates
        Specifies if third party updates is enabled or disabled.
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
        [String]
        $ScanStart,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','Hours','Minutes','None')]
        [String]
        $ScanScheduleType,

        [Parameter()]
        [UInt32]
        $ScanRecurInterval,

        [Parameter()]
        [ValidateSet('First','Second','Third','Fourth','Last')]
        [String]
        $ScanMonthlyWeekOrder,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String]
        $ScanDayOfWeek,

        [Parameter()]
        [ValidateRange(0,31)]
        [UInt32]
        $ScanDayOfMonth,

        [Parameter()]
        [String]
        $EvalStart,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','Hours','Minutes','None')]
        [String]
        $EvalScheduleType,

        [Parameter()]
        [UInt32]
        $EvalRecurInterval,

        [Parameter()]
        [ValidateSet('First','Second','Third','Fourth','Last')]
        [String]
        $EvalMonthlyWeekOrder,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String]
        $EvalDayOfWeek,

        [Parameter()]
        [ValidateRange(0,31)]
        [UInt32]
        $EvalDayOfMonth,

        [Parameter()]
        [Boolean]
        $EnforceMandatory,

        [Parameter()]
        [ValidateSet('Hours','Days')]
        [String]
        $TimeUnit,

        [Parameter()]
        [ValidateRange(1,365)]
        [UInt32]
        $BatchingTimeOut,

        [Parameter()]
        [Boolean]
        $EnableDeltaDownload,

        [Parameter()]
        [UInt32]
        $DeltaDownloadPort,

        [Parameter()]
        [Boolean]
        $Office365ManagementType,

        [Parameter()]
        [Boolean]
        $EnableThirdPartyUpdates
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName -Enable $Enable
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

        if ($Enable -eq $true)
        {
            if ((-not $PSBoundParameters.ContainsKey('ScanScheduleType')) -and ($PSBoundParameters.ContainsKey('ScanStart') -or
                $PSBoundParameters.ContainsKey('ScanRecurInterval') -or $PSBoundParameters.ContainsKey('ScanMonthlyWeekOrder') -or
                $PSBoundParameters.ContainsKey('ScanDayOfWeek') -or $PSBoundParameters.ContainsKey('ScanDayOfMonth')))
            {
                throw $script:localizedData.RequiredSchedule
            }

            if ((-not $PSBoundParameters.ContainsKey('EvalScheduleType')) -and ($PSBoundParameters.ContainsKey('EvalStart') -or
                $PSBoundParameters.ContainsKey('EvalRecurInterval') -or $PSBoundParameters.ContainsKey('EvalMonthlyWeekOrder') -or
                $PSBoundParameters.ContainsKey('EvalDayOfWeek') -or $PSBoundParameters.ContainsKey('EvalDayOfMonth')))
            {
                throw $script:localizedData.RequiredSchedule
            }

            $defaultValues = @('Enable','EnforceMandatory','EnableDeltaDownload','Office365ManagementType',
                'EnableThirdPartyUpdates')

            if ($EnableDeltaDownload -eq $false -and $PSBoundParameters.ContainsKey('DeltaDownloadPort'))
            {
                Write-Warning -Message $script:localizedData.DeltaPortIgnore
            }
            else
            {
                $defaultValues += 'DeltaDownloadPort'
            }

            if ($EnforceMandatory -eq $true)
            {
                $defaultValues += ('TimeUnit','BatchingTimeOut')
                if (-not $PSBoundParameters.ContainsKey('TimeUnit') -or -not $PSBoundParameters.ContainsKey('BatchingTimeOut'))
                {
                    throw $script:localizedData.MissingEnforce
                }

                if ($TimeUnit -eq 'Hours' -and $BatchingTimeOut -gt 23)
                {
                    Write-Warning -Message $script:localizedData.MaxBatchHours
                    $PSBoundParameters.Remove('BatchingTimeOut') | Out-Null
                    $PSBoundParameters.Add('BatchingTimeOut',23)
                }
            }
            elseif ($PSBoundParameters.ContainsKey('TimeUnit') -or $PSBoundParameters.ContainsKey('BatchingTimeOut'))
            {
                Write-Warning -Message $script:localizedData.TimeBatchIgnore
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

            if ($ScanScheduleType)
            {
                $valuesToValidate = @('ScanScheduleType','ScanRecurInterval','ScanMonthlyWeekOrder',
                    'ScanDayOfWeek','ScanDayOfMonth','ScanStart')
                foreach ($item in $valuesToValidate)
                {
                    if ($PSBoundParameters.ContainsKey($item))
                    {
                        $scanScheduleCheck += @{
                            $item.Substring(4) = $PSBoundParameters[$item]
                        }
                    }
                }

                foreach ($scan in $state.Keys)
                {
                    if ($valuesToValidate -contains $scan)
                    {
                        $scanState += @{
                            $scan.SubString(4) = $state[$scan]
                        }
                    }
                }

                $scanResult = Test-CMSchedule @scanScheduleCheck -State $scanState
            }

            if ($scanResult -eq $false)
            {
                $sched = Set-CMSchedule @scanScheduleCheck
                $newSchedule = New-CMSchedule @sched

                Write-Verbose -Message $script:localizedData.NewSchedule
                $buildingParams += @{
                    ScanSchedule = $newSchedule
                }
            }

            if ($EvalScheduleType)
            {
                $valuesToValidate = @('EvalScheduleType','EvalRecurInterval','EvalMonthlyWeekOrder',
                    'EvalDayOfWeek','EvalDayOfMonth','EvalStart')

                foreach ($item in $valuesToValidate)
                {
                    if ($PSBoundParameters.ContainsKey($item))
                    {
                        $evalScheduleCheck += @{
                            $item.Substring(4) = $PSBoundParameters[$item]
                        }
                    }
                }

                foreach ($eval in $state.Keys)
                {
                    if ($valuesToValidate -contains $eval)
                    {
                        $evalState += @{
                            $eval.SubString(4) = $state[$eval]
                        }
                    }
                }

                $evalResult = Test-CMSchedule @evalScheduleCheck -State $evalState
            }

            if ($evalResult -eq $false)
            {
                $sched = Set-CMSchedule @evalScheduleCheck
                $newSchedule = New-CMSchedule @sched

                Write-Verbose -Message $script:localizedData.NewSchedule
                $buildingParams += @{
                    DeploymentEvaluationSchedule = $newSchedule
                }
            }
        }
        elseif ($state.Enable -eq $true)
        {
            if ($PSBoundParameters.Keys.Count -ge 4)
            {
                Write-Warning -Message $script:localizedData.DisableIgnore
            }

            $buildingParams = @{
                Enable = $false
            }
        }

        if ($buildingParams)
        {
            if ($state.ClientType -eq 'Default')
            {
                Set-CMClientSettingSoftwareUpdate -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingSoftwareUpdate -Name $ClientSettingName @buildingParams
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
        Specifies if software update for clients is enabled or disabled.

    .PARAMETER ScanStart
        Specifies the start date and start time for the software update scan schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScanScheduleType
        Specifies the schedule type for the software update scan schedule.

    .PARAMETER ScanRecurInterval
        Specifies how often the ScanScheduleType is run.

    .PARAMETER ScanMonthlyByWeek
        Specifies week order for MonthlyByWeek scan schedule type.

    .PARAMETER ScanDayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly scan schedules.

    .PARAMETER ScanDayOfMonth
        Specifies the day number for MonthlyByDay scan schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .PARAMETER EvalStart
        Specifies the start date and start time for the software update eval schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER EvalScheduleType
        Specifies the schedule type for the software update eval schedule.

    .PARAMETER EvalRecurInterval
        Specifies how often the EvalScheduleType is run.

    .PARAMETER EvalMonthlyByWeek
        Specifies week order for MonthlyByWeek eval schedule type.

    .PARAMETER EvalDayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly eval schedules.

    .PARAMETER EvalDayOfMonth
        Specifies the day number for MonthlyByDay eval schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .Parameter EnforceMandatory
        Specifies if any software update deployment deadline is
        reached to install all deployments with dealing coming within a specific time period.

    .Parameter TimeUnit
        Specifies the unit of time, hours or days time frame to install pending software updates.

    .Parameter BatchingTimeOut
        Specifies the time within TimeUnit to install the depending updates.

    .Parameter EnableDeltaDownload
        Specifies if client are allowed to download delta content when available.

    .Parameter DeltaDownloadPort
        Specifies the port that clients will use to receive requests for delta content.

    .Parameter Office365ManagementType
        Specifies if management of the Office 365 client is enabled.

    .Parameter EnableThirdPartyUpdates
        Specifies if third party updates is enabled or disabled.
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
        [String]
        $ScanStart,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','Hours','Minutes','None')]
        [String]
        $ScanScheduleType,

        [Parameter()]
        [UInt32]
        $ScanRecurInterval,

        [Parameter()]
        [ValidateSet('First','Second','Third','Fourth','Last')]
        [String]
        $ScanMonthlyWeekOrder,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String]
        $ScanDayOfWeek,

        [Parameter()]
        [ValidateRange(0,31)]
        [UInt32]
        $ScanDayOfMonth,

        [Parameter()]
        [String]
        $EvalStart,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','Hours','Minutes','None')]
        [String]
        $EvalScheduleType,

        [Parameter()]
        [UInt32]
        $EvalRecurInterval,

        [Parameter()]
        [ValidateSet('First','Second','Third','Fourth','Last')]
        [String]
        $EvalMonthlyWeekOrder,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String]
        $EvalDayOfWeek,

        [Parameter()]
        [ValidateRange(0,31)]
        [UInt32]
        $EvalDayOfMonth,

        [Parameter()]
        [Boolean]
        $EnforceMandatory,

        [Parameter()]
        [ValidateSet('Hours','Days')]
        [String]
        $TimeUnit,

        [Parameter()]
        [ValidateRange(1,365)]
        [UInt32]
        $BatchingTimeOut,

        [Parameter()]
        [Boolean]
        $EnableDeltaDownload,

        [Parameter()]
        [UInt32]
        $DeltaDownloadPort,

        [Parameter()]
        [Boolean]
        $Office365ManagementType,

        [Parameter()]
        [Boolean]
        $EnableThirdPartyUpdates
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
    elseif ($state.ClientType -eq 'User')
    {
        Write-Warning -Message $script:localizedData.WrongClientType
        $result = $false
    }
    else
    {
        if ($Enable -eq $true)
        {
            if ((-not $PSBoundParameters.ContainsKey('ScanScheduleType')) -and ($PSBoundParameters.ContainsKey('ScanStart') -or
                $PSBoundParameters.ContainsKey('ScanRecurInterval') -or $PSBoundParameters.ContainsKey('ScanMonthlyWeekOrder') -or
                $PSBoundParameters.ContainsKey('ScanDayOfWeek') -or $PSBoundParameters.ContainsKey('ScanDayOfMonth')))
            {
                Write-Warning -Message $script:localizedData.RequiredSchedule
                $badInput = $true
            }

            if ((-not $PSBoundParameters.ContainsKey('EvalScheduleType')) -and ($PSBoundParameters.ContainsKey('EvalStart') -or
                $PSBoundParameters.ContainsKey('EvalRecurInterval') -or $PSBoundParameters.ContainsKey('EvalMonthlyWeekOrder') -or
                $PSBoundParameters.ContainsKey('EvalDayOfWeek') -or $PSBoundParameters.ContainsKey('EvalDayOfMonth')))
            {
                Write-Warning -Message $script:localizedData.RequiredSchedule
                $badInput = $true
            }

            $defaultValues = @('Enable','EnforceMandatory','EnableDeltaDownload','Office365ManagementType',
                'EnableThirdPartyUpdates')

            if ($EnableDeltaDownload -eq $false -and $PSBoundParameters.ContainsKey('DeltaDownloadPort'))
            {
                Write-Warning -Message $script:localizedData.DeltaPortIgnore
            }
            else
            {
                $defaultValues += 'DeltaDownloadPort'
            }

            if ($EnforceMandatory -eq $true)
            {
                $defaultValues += ('TimeUnit','BatchingTimeOut')
                if (-not $PSBoundParameters.ContainsKey('TimeUnit') -or -not $PSBoundParameters.ContainsKey('BatchingTimeOut'))
                {
                    Write-Warning -Message $script:localizedData.MissingEnforce
                    $badInput = $true
                }

                if ($TimeUnit -eq 'Hours' -and $BatchingTimeOut -gt 23)
                {
                    Write-Warning -Message $script:localizedData.MaxBatchHours
                    $PSBoundParameters.Remove('BatchingTimeOut') | Out-Null
                    $PSBoundParameters.Add('BatchingTimeOut',23)
                }
            }
            elseif ($PSBoundParameters.ContainsKey('TimeUnit') -or $PSBoundParameters.ContainsKey('BatchingTimeOut'))
            {
                Write-Warning -Message $script:localizedData.TimeBatchIgnore
            }

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = $defaultValues
            }

            $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

            if ($ScanScheduleType)
            {
                $valuesToValidate = @('ScanScheduleType','ScanRecurInterval','ScanMonthlyWeekOrder',
                    'ScanDayOfWeek','ScanDayOfMonth','ScanStart')
                foreach ($item in $valuesToValidate)
                {
                    if ($PSBoundParameters.ContainsKey($item))
                    {
                        $scanScheduleCheck += @{
                            $item.Substring(4) = $PSBoundParameters[$item]
                        }
                    }
                }

                foreach ($scan in $state.Keys)
                {
                    if ($valuesToValidate -contains $scan)
                    {
                        $scanState += @{
                            $scan.SubString(4) = $state[$scan]
                        }
                    }
                }

                $scanResult = Test-CMSchedule @scanScheduleCheck -State $scanState
            }

            if ($EvalScheduleType)
            {
                $valuesToValidate = @('EvalScheduleType','EvalRecurInterval','EvalMonthlyWeekOrder',
                    'EvalDayOfWeek','EvalDayOfMonth','EvalStart')
                foreach ($item in $valuesToValidate)
                {
                    if ($PSBoundParameters.ContainsKey($item))
                    {
                        $evalScheduleCheck += @{
                            $item.Substring(4) = $PSBoundParameters[$item]
                        }
                    }
                }

                foreach ($eval in $state.Keys)
                {
                    if ($valuesToValidate -contains $eval)
                    {
                        $evalState += @{
                            $eval.SubString(4) = $state[$eval]
                        }
                    }
                }

                $evalResult = Test-CMSchedule @evalScheduleCheck -State $evalState
            }
        }
        else
        {
            if ($PSBoundParameters.Keys.Count -ge 4)
            {
                Write-Warning -Message $script:localizedData.DisableIgnore
            }

            if ($state.Enable -eq $true)
            {
                Write-Verbose -Message $script:localizedData.TestDisabled
                $result = $false
            }
        }
    }

    if ($result -eq $false -or $scanResult -eq $false -or $badInput -eq $true -or $evalResult -eq $false)
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
