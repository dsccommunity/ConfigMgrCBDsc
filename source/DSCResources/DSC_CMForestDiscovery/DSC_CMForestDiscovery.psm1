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

    .PARAMETER Enabled
        Specifies the enablement of the forest discovery method. If settings is set to $false no other value provided will be
        evaluated for compliance.

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

    $forestDiscovery = (Get-CMDiscoveryMethod -Name ActiveDirectoryForestDiscovery -SiteCode $SiteCode).Props
    $enabledStatus = (($forestDiscovery | Where-Object -FilterScript {$_.PropertyName -eq 'Settings'}).Value1 -eq 'Active')
    $forestSchedule = ($forestDiscovery | Where-Object -FilterScript {$_.PropertyName -eq 'Startup Schedule'}).Value1
    $subnetBoundary = ($forestDiscovery | Where-Object -FilterScript {$_.PropertyName -eq 'Enable Subnet Boundary Creation'}).Value
    $siteBoundary = ($forestDiscovery | Where-Object -FilterScript {$_.PropertyName -eq 'Enable AD Site Boundary Creation'}).Value
    $scheduleConvert = ConvertTo-ScheduleInterval -ScheduleString $forestSchedule

    return @{
        SiteCode                                  = $SiteCode
        Enabled                                   = $enabledStatus
        EnableActiveDirectorySiteBoundaryCreation = $siteBoundary
        EnableSubnetBoundaryCreation              = $subnetBoundary
        ScheduleInterval                          = $scheduleConvert.Interval
        ScheduleCount                             = $scheduleConvert.Count
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER Enabled
        Specifies the enablement of the forest discovery method. If settings is set to $false no other value provided will be
        evaluated for compliance.

    .PARAMETER EnableActiveDirectorySiteBoundaryCreation
        Indicates whether Configuration Manager creates Active Directory boundaries from AD DS discovery information.

    .PARAMETER EnableSubnetBoundaryCreation
        Indicates whether Configuration Manager creates IP address range boundaries from AD DS discovery information.

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
        [Boolean]
        $EnableActiveDirectorySiteBoundaryCreation,

        [Parameter()]
        [Boolean]
        $EnableSubnetBoundaryCreation,

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
        if ($Enabled -eq $true)
        {
            if (($PSBoundParameters.ContainsKey('ScheduleInterval') -and -not $PSBoundParameters.ContainsKey('ScheduleCount')) -or
                ($PSBoundParameters.ContainsKey('ScheduleCount') -and -not $PSBoundParameters.ContainsKey('ScheduleInterval')))
            {
                throw $script:localizedData.IntervalCount
            }

            $includeList = @('Enabled','EnableActiveDirectorySiteBoundaryCreation','EnableSubnetBoundaryCreation')
            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($includeList -contains $param.key)
                {
                    if ($param.Value -ne $state[$param.key])
                    {
                        Write-Verbose -Message ($script:localizedData.SettingSettings -f $param.Key, $param.Value)
                        $buildingParams += @{
                            $param.Key = $param.Value
                        }
                    }
                }
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

            if ($buildingParams)
            {
                Set-CMDiscoveryMethod -ActiveDirectoryForestDiscovery -SiteCode $SiteCode @buildingParams
            }
        }
        elseif ($Enabled -eq $false -and $state.Enabled -eq $true)
        {
            Set-CMDiscoveryMethod -ActiveDirectoryForestDiscovery -SiteCode $SiteCode -Enabled $false
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
        Specifies the enablement of the forest discovery method. If settings is set to $false no other value provided will be
        evaluated for compliance.

    .PARAMETER EnableActiveDirectorySiteBoundaryCreation
        Indicates whether Configuration Manager creates Active Directory boundaries from AD DS discovery information.

    .PARAMETER EnableSubnetBoundaryCreation
        Indicates whether Configuration Manager creates IP address range boundaries from AD DS discovery information.

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
        [Boolean]
        $EnableActiveDirectorySiteBoundaryCreation,

        [Parameter()]
        [Boolean]
        $EnableSubnetBoundaryCreation,

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

    if ($Enabled -eq $true)
    {
        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = @('Enabled','EnableActiveDirectorySiteBoundaryCreation','EnableSubnetBoundaryCreation',
                            'EnableFilteringExpiredLogon')
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

        if (($PSBoundParameters.ContainsKey('ScheduleInterval') -and -not $PSBoundParameters.ContainsKey('ScheduleCount')) -or
            ($PSBoundParameters.ContainsKey('ScheduleCount') -and -not $PSBoundParameters.ContainsKey('ScheduleInterval')))
        {
            Write-Warning -Message $script:localizedData.IntervalCountTest
            $result = $false
        }
        elseif ($PSBoundParameters.ContainsKey('ScheduleInterval') -and $PSBoundParameters.ContainsKey('ScheduleCount'))
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
    }
    elseif ($state.Enabled -eq $true)
    {
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
