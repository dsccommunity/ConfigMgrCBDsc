$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site that manages the system role for the asset intelligence point.

    .Notes
        This role must only be installed on top-level site of the hierarchy.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $apProps = Get-CMAssetIntelligenceProxy

    if ($apProps)
    {
        $cert         = $apProps.ProxyCertPath
        $serverName   = (Get-CMAssetIntelligenceSynchronizationPoint).NetworkOSPath.SubString(2)
        $apEnabled    = $apProps.ProxyEnabled
        $syncEnabled  = $apProps.PeriodicCatalogUpdateEnabled
        $syncSchedule = $apProps.PeriodicCatalogUpdateSchedule
        $status       = 'Present'

        $schedule = Get-CMSchedule -ScheduleString $syncSchedule
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteServerName        = $serverName
        IsSingleInstance      = $IsSingleInstance
        SiteCode              = $SiteCode
        CertificateFile       = $cert
        Enable                = $apEnabled
        EnableSynchronization = $syncEnabled
        Start                 = $schedule.Start
        ScheduleType          = $schedule.ScheduleType
        DayOfWeek             = $schedule.DayofWeek
        MonthlyWeekOrder      = $schedule.WeekOrder
        DayofMonth            = $schedule.MonthDay
        RecurInterval         = $schedule.RecurInterval
        Ensure                = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site that manages the system role for the asset intelligence point.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.
        If the role is already installed on another server this setting will be ignored.

    .PARAMETER CertificateFile
        Specifies the path to a System Center Online authentication certificate (.pfx) file.
        If used, this must be in UNC format. Local paths are not allowed.
        Mutually exclusive with the CertificateFile Parameter.

    .PARAMETER Start
        Specifies the start date and start time for the synchronization schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the synchronization schedule.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyByWeek
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .PARAMETER Enable
        Specifies whether the installed asset intelligence role is enabled or disabled.

    .PARAMETER EnableSynchronization
        Specifies whether to synchronize the asset intelligence catalog.

    .PARAMETER RemoveCertificate
        Specifies whether to remove a configured certificate file.
        Mutually exclusive with the CertificateFile Parameter.

    .PARAMETER Ensure
        Specifies whether the asset intelligence synchronization point is present or absent.

    .Notes
        This role must only be installed on top-level site of the hierarchy.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter()]
        [String]
        $SiteServerName,

        [Parameter()]
        [String]
        $CertificateFile,

        [Parameter()]
        [String]
        $Start,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','None')]
        [String]
        $ScheduleType,

        [Parameter()]
        [ValidateRange(1,31)]
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
        [Boolean]
        $Enable,

        [Parameter()]
        [Boolean]
        $EnableSynchronization,

        [Parameter()]
        [Boolean]
        $RemoveCertificate,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -IsSingleInstance $IsSingleInstance

    try
    {
        if (($ScheduleType) -and ($EnableSynchronization -eq $false))
        {
            throw $script:localizedData.ScheduleNoSync
        }

        if (($CertificateFile) -and ($RemoveCertificate -eq $true))
        {
            throw $script:localizedData.CertMismatch
        }

        if ($Ensure -eq 'Present')
        {
            if ($state.Ensure -eq 'Absent')
            {
                if (-not $PsBoundParameters.ContainsKey('SiteServerName'))
                {
                    throw $script:localizedData.ServerNameAdd
                }

                if ($null -eq (Get-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName))
                {
                    Write-Verbose -Message ($script:localizedData.SiteServerRole -f $SiteServerName)
                    New-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName
                }

                Write-Verbose -Message ($script:localizedData.AddAPRole -f $SiteServerName)
                Add-CMAssetIntelligenceSynchronizationPoint -SiteSystemServerName $SiteServerName
            }

            $evalList = @('CertificateFile','Enable','EnableSynchronization')

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($evalList -contains $param.key)
                {
                    if ($param.Value -ne $state[$param.key])
                    {
                        Write-Verbose -Message ($script:localizedData.SettingValue -f $param.Key, $param.Value)
                        $buildingParams += @{
                            $param.Key = $param.Value
                        }
                    }
                }
            }

            if (($RemoveCertificate) -and (-not [string]::IsNullOrEmpty($state.CertificateFile)))
            {
                Write-Verbose -Message ($script:localizedData.RemoveCert -f $SiteServerName)
                $buildingParams += @{
                    CertificateFile = ''
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

            if ($buildingParams)
            {
                Set-CMAssetIntelligenceSynchronizationPoint @buildingParams
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            if (-not $PsBoundParameters.ContainsKey('SiteServerName'))
            {
                throw $script:localizedData.ServerNameRemove
            }

            Write-Verbose -Message ($script:localizedData.RemoveAPRole -f $SiteServerName)
            Remove-CMAssetIntelligenceSynchronizationPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode
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

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site that manages the system role for the asset intelligence point.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.
        If the role is already installed on another server this setting will be ignored.

    .PARAMETER CertificateFile
        Specifies the path to a System Center Online authentication certificate (.pfx) file.
        If used, this must be in UNC format. Local paths are not allowed.
        Mutually exclusive with the CertificateFile Parameter.

    .PARAMETER Start
        Specifies the start date and start time for the synchronization schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the synchronization schedule.

    .PARAMETER RecurInterval
        Specifies how often the ScheduleType is run.

    .PARAMETER MonthlyByWeek
        Specifies week order for MonthlyByWeek schedule type.

    .PARAMETER DayOfWeek
        Specifies the day of week name for MonthlyByWeek and Weekly schedules.

    .PARAMETER DayOfMonth
        Specifies the day number for MonthlyByDay schedules.
        Note specifying 0 sets the schedule to run the last day of the month.

    .PARAMETER Enable
        Specifies whether the installed asset intelligence role is enabled or disabled.

    .PARAMETER EnableSynchronization
        Specifies whether to synchronize the asset intelligence catalog.

    .PARAMETER RemoveCertificate
        Specifies whether to remove a configured certificate file.
        Mutually exclusive with the CertificateFile Parameter.

    .PARAMETER Ensure
        Specifies whether the asset intelligence synchronization point is present or absent.

    .Notes
        This role must only be installed on top-level site of the hierarchy.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter()]
        [String]
        $SiteServerName,

        [Parameter()]
        [String]
        $CertificateFile,

        [Parameter()]
        [String]
        $Start,

        [Parameter()]
        [ValidateSet('MonthlyByDay','MonthlyByWeek','Weekly','Days','None')]
        [String]
        $ScheduleType,

        [Parameter()]
        [ValidateRange(1,31)]
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
        [Boolean]
        $Enable,

        [Parameter()]
        [Boolean]
        $EnableSynchronization,

        [Parameter()]
        [Boolean]
        $RemoveCertificate,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -IsSingleInstance $IsSingleInstance
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.APNotInstalled -f $SiteServerName)
            $result = $false
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.RoleInstalled)

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = @('CertificateFile','Enable','EnableSynchronization')
            }

            $mainState = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

            if (-not [string]::IsNullOrEmpty($mainState) -and $mainState -eq $false)
            {
                $result = $false
            }

            if (($RemoveCertificate) -and (-not [string]::IsNullOrEmpty($state.CertificateFile)))
            {
                Write-Verbose -Message ($script:localizedData.NullCertCheck -f $SiteServerName)
                $result = $false
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

                if ($schedResult -ne $true)
                {
                    $result = $false
                }
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.APAbsent -f $SiteServerName)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
