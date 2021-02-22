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
        Specifies the enablement of the User Discovery method.
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

    $userDiscovery = Get-CMDiscoveryMethod -Name ActiveDirectoryUserDiscovery -SiteCode $SiteCode

    foreach ($prop in $userDiscovery.Props)
    {
        switch ($prop.PropertyName)
        {
            'Settings'                { $enabledStatus = ($prop.Value1 -eq 'Active') }
            'Full Sync Schedule'      { $userSchedule = $prop.Value1 }
            'Enable Incremental Sync' { $deltaEnabled = $prop.Value }
            'Startup Schedule'        { $userDelta = $prop.Value1 }
        }
    }

    $adContainersList = ($userDiscovery.Proplists | Where-Object -FilterScript {$_.PropertyListName -eq 'AD Containers'}).Values
    foreach ($line in $adContainersList)
    {
        if ($line -match 'LDAP://')
        {
            [array]$adContainerArray += $line
        }
    }

    if ($deltaEnabled -eq 0)
    {
        $userSchedule = $userDelta
        $userDelta = $null
    }

    $scheduleConvert = ConvertTo-ScheduleInterval -ScheduleString $userSchedule

    if (-not [string]::IsNullOrEmpty($userDelta))
    {
        $uDelta = Convert-CMSchedule -ScheduleString $userDelta

        if ($uDelta.HourSpan -eq 1)
        {
            $syncDelta = 60
        }
        else
        {
            $syncDelta = $uDelta.MinuteSpan
        }
    }

    return @{
        SiteCode             = $SiteCode
        Enabled              = $enabledStatus
        ScheduleInterval     = $scheduleConvert.Interval
        ScheduleCount        = $scheduleConvert.Count
        EnableDeltaDiscovery = $deltaEnabled
        DeltaDiscoveryMins   = $syncDelta
        ADContainers         = $adContainerArray
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER Enabled
        Specifies the enablement of the User Discovery method.

    .PARAMETER EnableDeltaDiscovery
        Indicates whether Configuration Manager discovers resources created or modified in AD DS
        since the last discovery cycle. If you specify a value of $True for this parameter,
        specify a value for the DeltaDiscoveryMins parameter.

    .PARAMETER DeltaDiscoveryMins
        Specifies the number of minutes for the delta discovery.

    .PARAMETER ADContainers
        Specifies an array of names of Active Directory containers to match to the discovery.

    .PARAMETER ADContainersToInclude
        Specifies an array of names of Active Directory containers to add to the discovery.

    .PARAMETER ADContainersToExclude
        Specifies an array of names of Active Directory containers to exclude to the discovery.

    .PARAMETER ScheduleInterval
        Specifies the time when the scheduled event recurs.

    .PARAMETER ScheduleCount
        Specifies how often the recur interval is run.
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
        $EnableDeltaDiscovery,

        [Parameter()]
        [ValidateRange(5,60)]
        [UInt32]
        $DeltaDiscoveryMins,

        [Parameter()]
        [String[]]
        $ADContainers,

        [Parameter()]
        [String[]]
        $ADContainersToInclude,

        [Parameter()]
        [String[]]
        $ADContainersToExclude,

        [Parameter()]
        [ValidateSet('None','Days','Hours','Minutes')]
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
            if (($PSBoundParameters.DeltaDiscoveryMins) -and ($PSBoundParameters.EnableDeltaDiscovery -eq $false -or
                ($state.EnableDeltaDiscovery -eq $false -and
                [string]::IsNullOrEmpty($PSBoundParameters.EnableDeltaDiscovery))))
            {
                throw $script:localizedData.MissingDeltaDiscovery
            }

            if (($PSBoundParameters.ContainsKey('ScheduleInterval') -and $PSBoundParameters.ScheduleInterval -ne 'None') -and
                (-not $PSBoundParameters.ContainsKey('ScheduleCount')))
            {
                throw $script:localizedData.IntervalCount
            }

            if (($EnableDeltaDiscovery -eq $true -and $state.EnableDeltaDiscovery -eq $false) -and
                (-not $PSBoundParameters.ContainsKey('DeltaDiscoveryMins')))
            {
                throw $script:localizedData.DeltaNoInterval
            }

            if ($ADContainersToInclude -and $ADContainersToExclude)
            {
                foreach ($item in $ADContainersToInclude)
                {
                    if ($ADContainersToExclude -contains $item)
                    {
                        throw ($script:localizedData.ContainersInEx -f $item)
                    }
                }
            }

            $paramsToCheck = @('Enabled','EnableDeltaDiscovery','DeltaDiscoveryMins')

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($paramsToCheck -contains $param.Key)
                {
                    if ($param.Value -ne $state[$param.Key])
                    {
                        Write-Verbose -Message ($script:localizedData.SetCommonSettings -f $param.Key, $param.Value)
                        $buildingParams += @{
                            $param.Key = $param.Value
                        }
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($ScheduleInterval))
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
                elseif (($ScheduleInterval -eq 'Minutes' -and $ScheduleCount -ge 60) -or ($ScheduleInterval -eq 'Minutes' -and $ScheduleCount -le 4))
                {
                    if ($ScheduleCount -ge 60)
                    {
                        Write-Warning -Message ($script:localizedData.MaxIntervalMins -f $ScheduleCount)
                        $scheduleCheck = 59
                    }
                    else
                    {
                        Write-Warning -Message ($script:localizedData.MinIntervalMins -f $ScheduleCount)
                        $scheduleCheck = 5
                    }
                }
                else
                {
                    $scheduleCheck = $ScheduleCount
                }

                if ($ScheduleInterval -ne $state.ScheduleInterval)
                {
                    Write-Verbose -Message ($script:localizedData.UIntervalSet -f $ScheduleInterval)
                    $setSchedule = $true
                }

                if (($ScheduleInterval -ne 'None') -and ($scheduleCheck -ne $state.ScheduleCount))
                {
                    Write-Verbose -Message ($script:localizedData.UCountSet -f $ScheduleCheck)
                    $setSchedule = $true
                }

                if ($setSchedule -eq $true)
                {
                    if ($ScheduleInterval -eq 'None')
                    {
                        $pschedule = New-CMSchedule -Nonrecurring
                    }
                    else
                    {
                        $pScheduleSet = @{
                            RecurInterval = $ScheduleInterval
                            RecurCount    = $ScheduleCheck
                        }

                        $pschedule = New-CMSchedule @pScheduleSet
                    }

                    $buildingParams += @{
                        PollingSchedule = $pSchedule
                    }
                }
            }

            if (($ADContainers) -or ($ADContainersToInclude))
            {
                if ($ADContainers)
                {
                    $includes = $ADContainers
                }
                else
                {
                    $includes = $ADContainersToInclude
                }

                foreach ($adContainer in $includes)
                {
                    if ($state.ADContainers -notcontains $adContainer)
                    {
                        Write-Verbose -Message ($script:localizedData.AddADContainer -f $adContainer)
                        [array]$addAdContainers += $adContainer
                    }
                }

                if (-not [string]::IsNullOrEmpty($addAdContainers))
                {
                    $buildingParams += @{
                        AddActiveDirectoryContainer = $addAdContainers
                    }
                }
            }

            if (($ADContainers) -or ($ADContainersToExclude))
            {
                if (-not [string]::IsNullOrEmpty($state.ADContainers))
                {
                    if ($ADContainers)
                    {
                        $excludes = $ADContainers
                    }
                    else
                    {
                        $excludes = $ADContainersToExclude
                    }

                    $compares = Compare-Object -ReferenceObject $state.ADContainers -DifferenceObject $excludes -IncludeEqual
                    foreach ($compare in $compares)
                    {
                        if ($ADContainers)
                        {
                            if ($compare.SideIndicator -eq '<=')
                            {
                                Write-Verbose -Message ($script:localizedData.RemoveADContainer -f $compare.InputObject)
                                [array]$removeADContainers += $compare.InputObject
                            }
                        }
                        else
                        {
                            if ($compare.SideIndicator -eq '==')
                            {
                                Write-Verbose -Message ($script:localizedData.RemoveADContainer -f $compare.InputObject)
                                [array]$removeADContainers += $compare.InputObject
                            }
                        }
                    }

                    if (-not [string]::IsNullOrEmpty($removeADContainers))
                    {
                        $buildingParams += @{
                            RemoveActiveDirectoryContainer = $removeADContainers
                        }
                    }
                }
            }

            if ($buildingParams)
            {
                Set-CMDiscoveryMethod -ActiveDirectoryUserDiscovery -SiteCode $SiteCode @buildingParams
            }
        }
        elseif ($state.Enabled -eq $true)
        {
            Write-Verbose -Message $script:localizedData.SetDisabled
            Set-CMDiscoveryMethod -ActiveDirectoryUserDiscovery -Enabled $false -SiteCode $SiteCode
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
        Specifies the enablement of the User Discovery method.

    .PARAMETER EnableDeltaDiscovery
        Indicates whether Configuration Manager discovers resources created or modified in AD DS
        since the last discovery cycle. If you specify a value of $True for this parameter,
        specify a value for the DeltaDiscoveryMins parameter.

    .PARAMETER DeltaDiscoveryMins
        Specifies the number of minutes for the delta discovery.

    .PARAMETER ADContainers
        Specifies an array of names of Active Directory containers to match to the discovery.

    .PARAMETER ADContainersToInclude
        Specifies an array of names of Active Directory containers to add to the discovery.

    .PARAMETER ADContainersToExclude
        Specifies an array of names of Active Directory containers to exclude to the discovery.

    .PARAMETER ScheduleInterval
        Specifies the time when the scheduled event recurs.

    .PARAMETER ScheduleCount
        Specifies how often the recur interval is run.
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
        $EnableDeltaDiscovery,

        [Parameter()]
        [ValidateRange(5,60)]
        [UInt32]
        $DeltaDiscoveryMins,

        [Parameter()]
        [String[]]
        $ADContainers,

        [Parameter()]
        [String[]]
        $ADContainersToInclude,

        [Parameter()]
        [String[]]
        $ADContainersToExclude,

        [Parameter()]
        [ValidateSet('None','Days','Hours','Minutes')]
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
            ValuesToCheck = @('Enabled','EnableDeltaDiscovery','DeltaDiscoveryMins')
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

        if ($PSBoundParameters.ContainsKey('ScheduleInterval'))
        {
            if ($ScheduleInterval -ne 'None' -and -not $PSBoundParameters.ContainsKey('ScheduleCount'))
            {
                Write-Verbose -Message $script:localizedData.IntervalCount
                $result = $false
            }
            else
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
                elseif (($ScheduleInterval -eq 'Minutes' -and $ScheduleCount -ge 60) -or ($ScheduleInterval -eq 'Minutes' -and $ScheduleCount -le 4))
                {
                    if ($ScheduleCount -ge 60)
                    {
                        Write-Warning -Message ($script:localizedData.MaxIntervalMins -f $ScheduleCount)
                        $scheduleCheck = 59
                    }
                    else
                    {
                        Write-Warning -Message ($script:localizedData.MinIntervalMins -f $ScheduleCount)
                        $scheduleCheck = 5
                    }
                }
                else
                {
                    $scheduleCheck = $ScheduleCount
                }

                if ($ScheduleInterval -ne $state.ScheduleInterval)
                {
                    Write-Verbose -Message ($script:localizedData.UIntervalTest -f $ScheduleInterval, $State.ScheduleInterval)
                    $result = $false
                }

                if (($ScheduleInterval -ne 'None') -and ($ScheduleCheck -ne $state.ScheduleCount))
                {
                    Write-Verbose -Message ($script:localizedData.UCountTest -f $scheduleCheck, $State.ScheduleCount)
                    $result = $false
                }
            }
        }

        if (($EnableDeltaDiscovery -eq $true -and $state.EnableDeltaDiscovery -eq $false) -and
                (-not $PSBoundParameters.ContainsKey('DeltaDiscoveryMins')))
        {
            Write-Warning -Message $script:localizedData.DeltaNoInterval
        }

        if ($ADContainersToInclude -and $ADContainersToExclude)
        {
            foreach ($item in $ADContainersToInclude)
            {
                if ($ADContainersToExclude -contains $item)
                {
                    Write-Warning -Message ($script:localizedData.ContainersInEx -f $item)
                }
            }
        }

        if (($ADContainers) -or ($ADContainersToInclude))
        {
            if ($ADContainers)
            {
                if ($PSBoundParameters.ContainsKey('ADContainersToInclude') -or
                   $PSBoundParameters.ContainsKey('ADContainersToExclude'))
                {
                    Write-Warning -Message $script:localizedData.ADIgnore
                }
                $includes = $ADContainers
            }
            else
            {
                $includes = $ADContainersToInclude
            }

            foreach ($adContainer in $includes)
            {
                if ($state.ADContainers -notcontains $adContainer)
                {
                    Write-Verbose -Message ($script:localizedData.ExpectedADContainer -f $adContainer)
                    $result = $false
                }
            }
        }

        if (($ADContainers) -or ($ADContainersToExclude))
        {
            if (-not [string]::IsNullOrEmpty($state.ADContainers))
            {
                if ($ADContainers)
                {
                    $excludes = $ADContainers
                }
                else
                {
                    $excludes = $ADContainersToExclude
                }

                $compares = Compare-Object -ReferenceObject $state.ADContainers -DifferenceObject $excludes -IncludeEqual
                foreach ($compare in $compares)
                {
                    if ($ADContainers)
                    {
                        if ($compare.SideIndicator -eq '<=')
                        {
                            Write-Verbose -Message ($script:localizedData.ExcludeADContainer -f $compare.InputObject)
                            $result = $false
                        }
                    }
                    else
                    {
                        if ($compare.SideIndicator -eq '==')
                        {
                            Write-Verbose -Message ($script:localizedData.ExcludeADContainer -f $compare.InputObject)
                            $result = $false
                        }
                    }
                }
            }
        }
    }
    elseif ($state.Enabled -eq $true)
    {
        Write-Verbose -Message $script:localizedData.TestDisabled
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource
