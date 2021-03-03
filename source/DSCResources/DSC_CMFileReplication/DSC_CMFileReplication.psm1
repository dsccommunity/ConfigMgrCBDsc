$script:dscResourceCommonPath = Join-Path (Join-Path -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $PsScriptRoot)) -ChildPath Modules) -ChildPath DscResource.Common
$script:configMgrResourcehelper = Join-Path (Join-Path -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $PsScriptRoot)) -ChildPath Modules) -ChildPath ConfigMgrCBDsc.ResourceHelper

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site that is the source for the file replication route.

    .PARAMETER DestinationSiteCode
        Specifies the destination site for the file replication route by using a site code.
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
        $DestinationSiteCode
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $replRoute = Get-CMFileReplicationRoute -SourceSiteCode $SiteCode -DestinationSiteCode $DestinationSiteCode

    if ($replRoute)
    {
        $replSite = 'Present'
        $login = ($replRoute.props | Where-Object -FilterScript {$_.PropertyName -eq 'Lan Login'}).value2
        if ([string]::IsNullOrEmpty($login))
        {
            $account = $true
        }
        else
        {
            $account = $false
        }

        $noLimit = $replRoute.UnlimitedRateForAll
        $pulse = $replRoute.propLists.values[0]
        $blockSize = $replRoute.propLists.values[1]
        $dataDelay = $replRoute.propLists.values[2]
        $rateSchedule = $replRoute.RateLimitingSchedule

        if ($rateSchedule)
        {
            $count = 0
            $next = $count + 1
            $rateLimites = @()

            do
            {
                if ($rateSchedule[$count] -eq $rateSchedule[$next])
                {
                    $next ++
                    $match = $null
                }
                else
                {
                    if ($next -eq 24)
                    {
                        $rateLimites += @{
                            LimitedBeginHour               = $count
                            LimitedEndHour                 = 0
                            LimitAvailableBandwidthPercent = $rateSchedule[$count]
                        }
                    }
                    else
                    {
                        $rateLimites += @{
                            LimitedBeginHour               = $count
                            LimitedEndHour                 = $next
                            LimitAvailableBandwidthPercent = $rateSchedule[$count]
                        }
                    }
                    $count = $next
                }
            }
            until ($count -eq 24)

            $cimRateLimit = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'
            foreach ($item in $rateLimites)
            {
                $cimRateLimit += (New-CimInstance -ClassName DSC_CMRateLimitingSchedule -Property @{
                    LimitedBeginHour = [UInt32]$item.LimitedBeginHour
                    LimitedEndHour   = [UInt32]$item.LimitedEndHour
                    LimitAvailableBandwidthPercent = [UInt32]$item.LimitAvailableBandwidthPercent
                } -ClientOnly -Namespace 'root/microsoft/Windows/DesiredStateConfiguration')
            }
        }

        if ($pulse -eq '1')
        {
            $pulseEnabled = $true
        }
        else
        {
            $pulseEnabled = $false
        }

        if (($noLimit -eq $false) -and ($pulseEnabled -eq $false))
        {
            $limitedBW = $true
        }
        else
        {
            $limitedBW = $false
        }

        $usageSched = $replRoute.UsageSchedule
        $days = @('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')
        $priorityTypes = @('Null','All','MediumHigh','High','Closed')
        $dayCount = 0

        $scheduleLimits = @()
        foreach ($item in $usageSched)
        {
            $usage = $item.HourUsage
            $hourCount = 0
            $nextHourCount = $hourCount + 1

            do
            {
                if ($usage[$nextHourCount] -and $usage[$hourCount] -eq $usage[$nextHourCount])
                {
                    $nextHourCount ++
                }
                else
                {
                    if ($nextHourCount -eq 24)
                    {
                        $scheduleLimits += @{
                            BeginHour = $hourCount
                            EndHour   = 0
                            Type      = $priorityTypes[$usage[$hourCount]]
                            Day       = $days[$dayCount]
                        }
                    }
                    else
                    {
                        $scheduleLimits += @{
                            BeginHour = $hourCount
                            EndHour   = $nextHourCount
                            Type      = $priorityTypes[$usage[$hourCount]]
                            Day       = $days[$dayCount]
                        }
                    }

                    $hourCount = $nextHourCount
                }
            }
            until ($HourCount -eq 24)

            $dayCount ++
        }

        if ($scheduleLimits)
        {
            $cimLimit = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'
            foreach ($scheduleLimit in $scheduleLimits)
            {
                $cimLimit += (New-CimInstance -ClassName DSC_CMReplicationNetworkLoadSchedule -Property @{
                    BeginHour = [UInt32]$scheduleLimit.BeginHour
                    EndHour   = [UInt32]$scheduleLimit.EndHour
                    Type      = $scheduleLimit.Type
                    Day       = $scheduleLimit.Day
                } -ClientOnly -Namespace 'root/microsoft/Windows/DesiredStateConfiguration')
            }
        }
    }
    else
    {
        $replSite = 'Absent'
    }

    return @{
        SiteCode                   = $SiteCode
        DestinationSiteCode        = $DestinationSiteCode
        DataBlockSizeKB            = $blockSize
        DelayBetweenDataBlockSec   = $dataDelay
        FileReplicationAccountName = $login
        UseSystemAccount           = $account
        Limited                    = $limitedBW
        PulseMode                  = $pulseEnabled
        RateLimitingSchedule       = $cimRateLimit
        Unlimited                  = $noLimit
        NetworkLoadSchedule        = $cimLimit
        Ensure                     = $replSite
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site that is the source for the file replication route.

    .PARAMETER DestinationSiteCode
        Specifies the destination site for the file replication route by using a site code.

    .PARAMETER DataBlockSizeKB
        Specifies a data block size, in kilobytes. Used in conjunction with the PulseMode parameter.

    .PARAMETER DelayBetweenDataBlockSec
        Delay, in seconds, between sending data blocks when PulseMode is enabled.

    .PARAMETER FileReplicationAccountName
        Specifies the account that Configuration Manager uses for file replication.
        If specifying an account the account must already exist in Configuration Manager.

    .PARAMETER UseSystemAccount
        Specifies if the replication service will use the site system account.

    .PARAMETER Limited
        Indicates that bandwidth for a file replication route is limited.
        Mutually exclusive with the PulseMode and Unlimited parameters.

    .PARAMETER RateLimitingSchedule
        Specifies, as an array of CimInstances, hour ranges and bandwidth percentages for limiting file replication.
        Used in conjunction with the Limited parameter.

    .PARAMETER PulseMode
        Indicates that file replication uses data block size and delays between transmissions.
        Mutually exclusive with the Unlimited and Limited parameters.

    .PARAMETER Unlimited
        Indicates that bandwidth for a file replication route is unlimited.
        Mutually exclusive with the PulseMode and Limited parameters.

    .PARAMETER NetworkLoadSchedule
        Specifies, as an array of CimInstances, hour ranges and bandwidth percentages for network load balancing schedule.
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
        $DestinationSiteCode,

        [Parameter()]
        [ValidateRange(1,256)]
        [UInt32]
        $DataBlockSizeKB,

        [Parameter()]
        [ValidateRange(1,30)]
        [UInt32]
        $DelayBetweenDataBlockSec,

        [Parameter()]
        [String]
        $FileReplicationAccountName,

        [Parameter()]
        [Boolean]
        $UseSystemAccount,

        [Parameter()]
        [Boolean]
        $Limited,

        [Parameter()]
        [Boolean]
        $PulseMode,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $RateLimitingSchedule,

        [Parameter()]
        [Boolean]
        $Unlimited,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $NetworkLoadSchedule,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode -DestinationSiteCode $DestinationSiteCode

        if ($Ensure -eq 'Present')
        {
            if (($PulseMode -eq $true -and ($Limited -eq $true -or $Unlimited -eq $true)) -or ($Limited -eq $true -and $Unlimited -eq $true))
            {
                throw $script:localizedData.MultipleTypes
            }

            if ($UseSystemAccount -eq $true -and $PSBoundParameters.ContainsKey('FileReplicationAccountName'))
            {
                throw $script:localizedData.AccountsError
            }

            if ($PulseMode -eq $true)
            {
                if ($PSBoundParameters.ContainsKey('DataBlockSizeKB') -and $PSBoundParameters.ContainsKey('DelayBetweenDataBlockSec'))
                {
                    $valuesToCheck = @('PulseMode','DataBlockSizeKB','DelayBetweenDataBlockSec')
                }
                else
                {
                    throw $script:localizedData.PulseModeError
                }
            }

            if ($Limited -eq $true)
            {
                if ($PSBoundParameters.ContainsKey('RateLimitingSchedule'))
                {
                    $valuesToCheck = @('Limited')
                    $checkSchedule = $true
                }
                else
                {
                    throw $script:localizedData.LimitedError
                }
            }

            if ($Unlimited -eq $true)
            {
                $valuesToCheck = @('Unlimited')
            }

            if ($null -eq ($state.NetworkLoadSchedule))
            {
                Write-Verbose -Message ($script:localizedData.FileRepCreate -f $SiteCode, $DestinationSiteCode)
                New-CMFileReplicationRoute -SourceSiteCode $SiteCode -DestinationSiteCode $DestinationSiteCode
            }

            $valuesToCheck += @('FileReplicationAccountName')

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($valuesToCheck -contains $param.Key)
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

            if (-not [string]::IsNullOrEmpty($buildingParams) -and $buildingParams.ContainsKey('FileReplicationAccountName'))
            {
                if ($null -eq (Get-CMAccount -UserName $FileReplicationAccountName))
                {
                    throw ($script:localizedData.BadAccountName -f $FileReplicationAccountName)
                }
            }

            if (($UseSystemAccount) -or ($UseSystemAccount -eq $true -and $state.UseSystemAccount -eq $false))
            {
                $buildingParams += @{
                    FileReplicationAccountName = $null
                }
            }

            if ($checkSchedule -eq $true)
            {
                foreach ($limSched in $RateLimitingSchedule)
                {
                    $overlapCheck = $RateLimitingSchedule.Where({$limSched.LimitedBeginHour -gt $_.LimitedBeginHour -and
                                                                $limSched.LimitedBeginHour -lt $_.LimitedEndHour})
                    if ($overlapCheck)
                    {
                        $errorMsg += ($script:localizedData.OverlappingRate -f $limSched.LimitedBeginHour, $limSched.LimitedEndHour)
                    }
                    else
                    {
                        $rateParams = @{}
                        $compliance = $false

                        foreach ($thing in $state.RateLimitingSchedule)
                        {
                            if (($limSched.LimitedBeginHour -ge $thing.LimitedBeginHour -and ($limSched.LimitedEndHour -le $thing.LimitedEndHour -or
                                $thing.LimitedEndHour -eq 0)) -and $limSched.LimitAvailableBandwidthPercent -eq $thing.LimitAvailableBandwidthPercent)
                            {
                                $compliance = $true
                                break
                            }
                        }

                        if ($compliance -eq $false)
                        {
                            $rateParams = @{
                                SourceSiteCode                 = $SiteCode
                                DestinationSiteCode            = $DestinationSiteCode
                                Limited                        = $null
                                limitedBeginHour               = $limSched.LimitedBeginHour
                                LimitedEndHour                 = $limSched.LimitedEndHour
                                LimitAvailableBandwidthPercent = $limSched.LimitAvailableBandwidthPercent
                            }

                            Write-Verbose -Message ($script:localizedData.LimitedSchedSet -f $limSched.LimitedBeginHour,$limSched.LimitedEndHour,$limSched.LimitAvailableBandwidthPercent)
                            Set-CMFileReplicationRoute @rateParams
                        }
                    }
                }
            }

            if ($NetworkLoadSchedule)
            {
                foreach ($limNetSched in $NetworkLoadSchedule)
                {
                    $loadOverlap = $NetworkLoadSchedule.Where({$_.Day -eq $limNetSched.Day -and $limNetSched.BeginHour -gt
                                    $_.BeginHour -and $limNetSched.BeginHour -lt $_.EndHour})
                    if ($loadOverlap)
                    {
                        $errorMsg += ($script:localizedData.OverlappingSchedule -f $limNetSched.BeginHour, $limNetSched.EndHour, $limNetSched.Day)
                    }
                    else
                    {
                        $networkLoadParams = @{}
                        $compliance = $false
                        $limNetSchedTest = $state.NetworkLoadSchedule.Where({$_.Day -eq $limNetSched.Day})

                        foreach ($thing in $limNetSchedTest)
                        {
                            if (($limNetSched.BeginHour -ge $thing.BeginHour -and ($limNetSched.EndHour -le $thing.EndHour -or $thing.EndHour -eq 0)) -and
                                $limNetSched.Type -eq $thing.Type)
                            {
                                $compliance = $true
                                break
                            }
                        }

                        if ($compliance -eq $false)
                        {
                            $networkLoadParams = @{
                                SourceSiteCode             = $SiteCode
                                DestinationSiteCode        = $DestinationSiteCode
                                ControlNetworkLoadSchedule = $null
                                BeginHr                    = $limNetSched.BeginHour
                                EndHr                      = $limNetSched.EndHour
                                DaysOfWeek                 = $limNetSched.Day
                                AvailabilityLevel          = $limNetSched.Type
                            }

                            Write-Verbose -Message ($script:localizedData.NetworkSchedSet -f $limNetSched.BeginHour,$limNetSched.EndHour,
                                                    $limNetSched.Day,$limNetSched.Type)
                            Set-CMFileReplicationRoute @networkLoadParams
                        }
                    }
                }
            }

            foreach ($item in $PSBoundParameters.Keys)
            {
                if ($valuesToCheck -notcontains $item -and $item -ne 'NetworkLoadSchedule' -and $item -ne 'RateLimitingSchedule' -and
                    $item -ne 'UseSystemAccount' -and $item -ne 'SiteCode' -and $item -ne 'DestinationSiteCode')
                {
                    Write-Warning -Message ($script:localizedData.ExtraSettings -f $item, $ScheduleType)
                }
            }

            if ($buildingParams)
            {
                $buildingParams += @{
                    SourceSiteCode      = $SiteCode
                    DestinationSiteCode = $DestinationSiteCode
                }
                Set-CMFileReplicationRoute @buildingParams
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveReplSite -f $SiteCode, $DestinationSiteCode)
            $removeParam = @{
                DestinationSiteCode = $DestinationSiteCode
                SourceSiteCode      = $SiteCode
                Force               = $null
            }

            Remove-CMFileReplicationRoute @removeParam
        }

        if ($errorMsg)
        {
            throw ($errorMsg | Out-String)
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
        Specifies a site code for the Configuration Manager site that is the source for the file replication route.

    .PARAMETER DestinationSiteCode
        Specifies the destination site for the file replication route by using a site code.

    .PARAMETER DataBlockSizeKB
        Specifies a data block size, in kilobytes. Used in conjunction with the PulseMode parameter.

    .PARAMETER DelayBetweenDataBlockSec
        Delay, in seconds, between sending data blocks when PulseMode is enabled.

    .PARAMETER FileReplicationAccountName
        Specifies the account that Configuration Manager uses for file replication.
        If specifying an account the account must already exist in Configuration Manager.

    .PARAMETER UseSystemAccount
        Specifies if the replication service will use the site system account.

    .PARAMETER Limited
        Indicates that bandwidth for a file replication route is limited.
        Mutually exclusive with the PulseMode and Unlimited parameters.

    .PARAMETER RateLimitingSchedule
        Specifies, as an array of CimInstances, hour ranges and bandwidth percentages for limiting file replication.
        Used in conjunction with the Limited parameter.

    .PARAMETER PulseMode
        Indicates that file replication uses data block size and delays between transmissions.
        Mutually exclusive with the Unlimited and Limited parameters.

    .PARAMETER Unlimited
        Indicates that bandwidth for a file replication route is unlimited.
        Mutually exclusive with the PulseMode and Limited parameters.

    .PARAMETER NetworkLoadSchedule
        Specifies, as an array of CimInstances, hour ranges and bandwidth percentages for network load balancing schedule.
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
        $DestinationSiteCode,

        [Parameter()]
        [ValidateRange(1,256)]
        [UInt32]
        $DataBlockSizeKB,

        [Parameter()]
        [ValidateRange(1,30)]
        [UInt32]
        $DelayBetweenDataBlockSec,

        [Parameter()]
        [String]
        $FileReplicationAccountName,

        [Parameter()]
        [Boolean]
        $UseSystemAccount,

        [Parameter()]
        [Boolean]
        $Limited,

        [Parameter()]
        [Boolean]
        $PulseMode,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $RateLimitingSchedule,

        [Parameter()]
        [Boolean]
        $Unlimited,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $NetworkLoadSchedule,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -DestinationSiteCode $DestinationSiteCode
    $return = $true

    if ($Ensure -eq 'Present')
    {
        if (($PulseMode -eq $true -and ($Limited -eq $true -or $Unlimited -eq $true)) -or ($Limited -eq $true -and $Unlimited -eq $true))
        {
            Write-Warning -Message $script:localizedData.MultipleTypes
            $badInput = $true
        }

        if ($UseSystemAccount -eq $true -and $PSBoundParameters.ContainsKey('FileReplicationAccountName'))
        {
            Write-Warning -Message $script:localizedData.AccountsError
            $badInput = $true
        }

        if ($PulseMode -eq $true)
        {
            if ($PSBoundParameters.ContainsKey('DataBlockSizeKB') -and $PSBoundParameters.ContainsKey('DelayBetweenDataBlockSec'))
            {
                $valuesToCheck = @('PulseMode','DataBlockSizeKB','DelayBetweenDataBlockSec')
            }
            else
            {
                Write-Warning -Message $script:localizedData.PulseModeError
                $badInput = $true
            }
        }

        if ($Limited -eq $true)
        {
            if ($PSBoundParameters.ContainsKey('RateLimitingSchedule'))
            {
                $valuesToCheck = @('Limited')
                $checkSchedule = $true
            }
            else
            {
                Write-Warning -Message $script:localizedData.LimitedError
                $badInput = $true
            }
        }

        if ($Unlimited -eq $true)
        {
            $valuesToCheck = @('Unlimited')
        }

        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message $script:localizedData.FileRepAbsent
            $return = $false
        }
        else
        {
            $valuesToCheck += @('FileReplicationAccountName')
            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = $valuesToCheck
            }

            $return = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

            if ($checkSchedule -eq $true)
            {
                foreach ($limSched in $RateLimitingSchedule)
                {
                    $overlapCheck = $RateLimitingSchedule.Where({$limSched.LimitedBeginHour -gt $_.LimitedBeginHour -and
                                                                $limSched.LimitedBeginHour -lt $_.LimitedEndHour})
                    if ($overlapCheck)
                    {
                        Write-Warning ($script:localizedData.OverlappingRate -f $limSched.LimitedBeginHour, $limSched.LimitedEndHour)
                    }
                    else
                    {
                        $compliance = $false

                        foreach ($thing in $state.RateLimitingSchedule)
                        {
                            if (($limSched.LimitedBeginHour -ge $thing.LimitedBeginHour -and ($limSched.LimitedEndHour -le $thing.LimitedEndHour -or $thing.LimitedEndHour -eq 0)) -and
                                $limSched.LimitAvailableBandwidthPercent -eq $thing.LimitAvailableBandwidthPercent)
                            {
                                $compliance = $true
                                break
                            }
                        }

                        if ($compliance -eq $true)
                        {
                            Write-Verbose -Message ($script:localizedData.LimitSchedMatch -f $limSched.LimitedBeginHour, $limSched.LimitedEndHour,
                                                    $limSched.LimitAvailableBandwidthPercent)
                        }
                        else
                        {
                            Write-Verbose -Message ($script:localizedData.LimitSchedNonMatch -f $limSched.LimitedBeginHour,$limSched.LimitedEndHour,
                                                    $limSched.LimitAvailableBandwidthPercent)
                            $return = $false
                        }
                    }
                }
            }

            if ($NetworkLoadSchedule)
            {
                foreach ($limNetSched in $NetworkLoadSchedule)
                {
                    $loadOverlap = $NetworkLoadSchedule.Where({$_.Day -eq $limNetSched.Day -and $limNetSched.BeginHour -gt
                        $_.BeginHour -and $limNetSched.BeginHour -lt $_.EndHour})
                    if ($loadOverlap)
                    {
                        Write-Warning -Message ($script:localizedData.OverlappingSchedule -f $limNetSched.BeginHour, $limNetSched.EndHour, $limNetSched.Day)
                    }
                    else
                    {
                        $compliance = $false
                        $limNetSchedTest = $state.NetworkLoadSchedule.Where({$_.Day -eq $limNetSched.Day})

                        foreach ($thing in $limNetSchedTest)
                        {
                            if (($limNetSched.BeginHour -ge $thing.BeginHour -and ($limNetSched.EndHour -le $thing.EndHour -or
                                 $thing.EndHour -eq 0)) -and $limNetSched.Type -eq $thing.Type)
                            {
                                $compliance = $true
                                break
                            }
                        }

                        if ($compliance -eq $true)
                        {
                            Write-Verbose -Message ($script:localizedData.NetworkSchedMatch -f $limNetSched.BeginHour,$limNetSched.EndHour,
                                                    $limNetSched.Day,$limNetSched.Type)
                        }
                        else
                        {
                            Write-Verbose -Message ($script:localizedData.NetworkSchedNonMatch -f $limNetSched.BeginHour,$limNetSched.EndHour,
                                                    $limNetSched.Day,$limNetSched.Type)
                            $return = $false
                        }
                    }
                }
            }

            foreach ($item in $PSBoundParameters.Keys)
            {
                if ($valuesToCheck -notcontains $item -and $item -ne 'NetworkLoadSchedule' -and $item -ne 'RateLimitingSchedule' -and
                    $item -ne 'UseSystemAccount' -and $item -ne 'SiteCode' -and $item -ne 'DestinationSiteCode')
                {
                    Write-Warning -Message ($script:localizedData.ExtraSettings -f $item, $ScheduleType)
                }
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message $script:localizedData.FileReplPresent
        $return = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $return)
    Set-Location -Path "$env:temp"

    if ($badInput -eq $true -or $return -eq $false)
    {
        return $false
    }
    else
    {
        return $true
    }
}

Export-ModuleMember -Function *-TargetResource
