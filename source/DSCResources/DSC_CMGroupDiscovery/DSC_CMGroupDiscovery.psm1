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
        Specifies the enablement of the Group discovery method.
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

    $groupDiscovery = Get-CMDiscoveryMethod -Name ActiveDirectoryGroupDiscovery -SiteCode $SiteCode
    $status = ($groupDiscovery.Props | Where-Object -FilterScript {$_.PropertyName -eq 'Settings'}).Value1

    if ($status -eq 'Active')
    {
        foreach ($prop in $groupDiscovery.Props)
        {
            switch ($prop.PropertyName)
            {
                'Settings'                          { $enabledStatus = ($prop.Value1 -eq 'Active') }
                'Full Sync Schedule'                { $groupSchedule = $prop.Value1 }
                'Enable Incremental Sync'           { [boolean]$deltaEnabled = $prop.Value }
                'Startup Schedule'                  { $groupDelta = $prop.Value1 }
                'Enable Filtering Expired Logon'    { [boolean]$lastLogonEnabled = $prop.Value }
                'Days Since Last Logon'             { $lastLogon = $prop.Value }
                'Enable Filtering Expired Password' { [boolean]$lastPasswordEnabled = $prop.Value }
                'Days Since Last Password Set'      { $lastPassword = $prop.Value }
                'Discover DG Membership'            { [boolean]$dgMemberEnabled = $prop.Value }
            }
        }

        $adContainers = ($groupDiscovery.Proplists | Where-Object -FilterScript {$_.PropertyListName -eq 'AD Containers'}).Values

        $count = 0
        if ($adContainers)
        {
            $adGroups = @()
            foreach ($item in $adContainers)
            {
                if ($item -ne 0 -and $item -ne 1)
                {
                    $value = $count + 2
                    if ($adContainers[$value] -eq 0)
                    {
                        $recurse = $true
                    }
                    else
                    {
                        $recurse = $false
                    }

                    $ou = ($groupDiscovery.Proplists | Where-Object -FilterScript {$_.PropertyListName -eq "Search Bases:$item"}).Values
                    $adCollection = @{
                        Name         = $item
                        Recurse      = $recurse
                        LDAPLocation = $ou[0]
                    }
                    $adGroups += ConvertTo-AnyCimInstance -ClassName DSC_CMGroupDiscoveryScope -Hashtable $adCollection
                }
                $count ++
            }
        }

        if ($deltaEnabled -eq $false)
        {
            $groupSchedule = $groupDelta
            $groupDelta = $null
        }

        $schedule = Get-CMSchedule -ScheduleString $groupSchedule

        if (-not [string]::IsNullOrEmpty($groupDelta))
        {
            $sDelta = Convert-CMSchedule -ScheduleString $groupDelta

            if ($sDelta.HourSpan -eq 1)
            {
                $syncDelta = 60
            }
            else
            {
                $syncDelta = $sDelta.MinuteSpan
            }
        }
    }
    else
    {
        $enabledStatus = $false
    }

    return @{
        SiteCode                            = $SiteCode
        Enabled                             = $enabledStatus
        EnableDeltaDiscovery                = $deltaEnabled
        DeltaDiscoveryMins                  = $syncDelta
        EnableFilteringExpiredLogon         = $lastLogonEnabled
        TimeSinceLastLogonDays              = $lastLogon
        EnableFilteringExpiredPassword      = $lastPasswordEnabled
        TimeSinceLastPasswordUpdateDays     = $lastPassword
        DiscoverDistributionGroupMembership = $dgMemberEnabled
        GroupDiscoveryScope                 = $adGroups
        Start                               = $schedule.Start
        ScheduleType                        = $schedule.ScheduleType
        DayOfWeek                           = $schedule.DayofWeek
        MonthlyWeekOrder                    = $schedule.WeekOrder
        DayofMonth                          = $schedule.MonthDay
        RecurInterval                       = $schedule.RecurInterval
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER Enabled
        Specifies the enablement of the group discovery method.

    .PARAMETER EnableDeltaDiscovery
        Indicates whether Configuration Manager discovers resources created or modified in AD DS
        since the last discovery cycle. If you specify a value of $True for this parameter,
        specify a value for the DeltaDiscoveryMins parameter.

    .PARAMETER DeltaDiscoveryMins
        Specifies the number of minutes for the delta discovery.

    .PARAMETER EnableFilteringExpiredLogon
        Indicates whether Configuration Manager discovers only computers that have logged onto a
        domain within a specified number of days. Specify the number of days by using the
        TimeSinceLastLogonDays parameter.

    .PARAMETER TimeSinceLastLogonDays
        Specify the number of days for EnableFilteringExpiredLogon.

    .PARAMETER EnableFilteringExpiredPassword
        Indicates whether Configuration Manager discovers only computers that have updated ther
        account password within a specified number of days. Specify the number of days by using the
        TimeSinceLastPasswordUpdateDays parameter.

    .PARAMETER TimeSinceLastPasswordUpdateDays
        Specify the number of days for EnableFilteringExpiredPassword.

    .PARAMETER DiscoverDistributionGroupMembership
        Specify if group discovery will discover distribution groups and the members of the group.

    .PARAMETER GroupDiscoveryScope
        Specifies an array of Group Discovery Scopes to match to the discovery.

    .PARAMETER GroupDiscoveryScopeToInclude
        Specifies an array of Group Discovery Scopes to add to the discovery.

    .PARAMETER GroupDiscoveryScopeToExclude
        Specifies an array of names of Group Discovery Scopes to exclude to the discovery.

    .PARAMETER Start
        Specifies the start date and start time for the group discovery schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the group discovery schedule.

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
        [Boolean]
        $EnableFilteringExpiredLogon,

        [Parameter()]
        [ValidateRange(14,720)]
        [UInt32]
        $TimeSinceLastLogonDays,

        [Parameter()]
        [Boolean]
        $EnableFilteringExpiredPassword,

        [Parameter()]
        [ValidateRange(30,720)]
        [UInt32]
        $TimeSinceLastPasswordUpdateDays,

        [Parameter()]
        [Boolean]
        $DiscoverDistributionGroupMembership,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $GroupDiscoveryScope,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $GroupDiscoveryScopeToInclude,

        [Parameter()]
        [String[]]
        $GroupDiscoveryScopeToExclude,

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

            if (($EnableDeltaDiscovery -eq $true -and $state.EnableDeltaDiscovery -eq $false) -and
                (-not $PSBoundParameters.ContainsKey('DeltaDiscoveryMins')))
            {
                throw $script:localizedData.DeltaNoInterval
            }

            if ($PSBoundParameters.ContainsKey('GroupDiscoveryScope'))
            {
                if ($PSBoundParameters.ContainsKey('GroupDiscoveryScopeToInclude') -or
                    $PSBoundParameters.ContainsKey('GroupDiscoveryScopeToExclude'))
                {
                    Write-Warning -Message $script:localizedData.GdsIgnore
                }
            }
            elseif ($GroupDiscoveryScopeToInclude -and $GroupDiscoveryScopeToExclude)
            {
                foreach ($item in $GroupDiscoveryScopeToInclude)
                {
                    if ($GroupDiscoveryScopeToExclude -contains $item.Name)
                    {
                        throw ($script:localizedData.GdsInEx -f $item.Name)
                    }
                }
            }

            $paramsToCheck = @('Enabled','EnableDeltaDiscovery','DeltaDiscoveryMins','EnableFilteringExpiredLogon',
                              'TimeSinceLastLogonDays','EnableFilteringExpiredPassword','TimeSinceLastPasswordUpdateDays',
                              'DiscoverDistributionGroupMembership')

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
                    PollingSchedule = $newSchedule
                }
            }

            if ($GroupDiscoveryScope -or $GroupDiscoveryScopeToInclude)
            {
                if ($GroupDiscoveryScope)
                {
                    $refObject = $GroupDiscoveryScope
                }
                elseif ($GroupDiscoveryScopeToInclude)
                {
                    $refObject = $GroupDiscoveryScopeToInclude
                }

                $compareParams = @{
                    ReferenceObject  = $refObject
                    DifferenceObject = $state.GroupDiscoveryScope
                    Property         = 'Recurse','Name','LdapLocation'
                    IncludeEqual     = $null
                }

                $compare = Compare-Object @compareParams
                $removing = @()
                $missing = @()

                foreach ($item in $compare)
                {
                    if ($item.SideIndicator -eq '<=')
                    {
                        if ($state.GroupDiscoveryScope.Name -contains $item.Name)
                        {
                            Write-Verbose -Message ($script:localizedData.GdsUpdate -f $item.Name, $item.LdapLocation, $item.Recurse,$item.LdapLocation, $item.Recurse)
                        }
                        else
                        {
                            Write-Verbose -Message ($script:localizedData.GdsMissing -f $item.Name, $item.LdapLocation, $item.Recurse)
                        }

                        $cmAddGroup = @{
                            SiteCode        = $SiteCode
                            LdapLocation    = $item.LdapLocation
                            Name            = $item.Name
                            RecursiveSearch = $item.Recurse
                        }

                        [array]$groupOus += New-CMADGroupDiscoveryScope @cmAddGroup
                    }

                    if ($GroupDiscoveryScope)
                    {
                        if ($item.SideIndicator -eq '=>')
                        {
                            #if ($refObject.Name -notcontains $item.Name)
                            #{
                                Write-Verbose -Message ($script:localizedData.GdsExtra -f $item.Name)
                                $removing += "$($item.Name)"
                            #}
                        }
                    }
                }
            }

            if ((-not $GroupDiscoveryScope) -and ($GroupDiscoveryScopeToExclude))
            {
                foreach ($item in $GroupDiscoveryScopeToExclude)
                {
                    if ($state.GroupDiscoveryScope.Name -contains $item)
                    {
                        Write-Verbose -Message ($script:localizedData.GdsExtra -f $item)
                        $removing += $item
                    }
                }
            }

            if ($removing)
            {
                Set-CMDiscoveryMethod -ActiveDirectoryGroupDiscovery -SiteCode $SiteCode -RemoveGroupDiscoveryScope $removing
            }

            if ($groupOus)
            {
                $buildingParams += @{
                    AddGroupDiscoveryScope = $groupOus
                }
            }

            if ($buildingParams)
            {
                Set-CMDiscoveryMethod -ActiveDirectoryGroupDiscovery -SiteCode $SiteCode @buildingParams
            }
        }
        elseif ($state.Enabled -eq $true)
        {
            Write-Verbose -Message $script:localizedData.SetDisabled
            Set-CMDiscoveryMethod -ActiveDirectoryGroupDiscovery -Enabled $false -SiteCode $SiteCode
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
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER Enabled
        Specifies the enablement of the group discovery method.

    .PARAMETER EnableDeltaDiscovery
        Indicates whether Configuration Manager discovers resources created or modified in AD DS
        since the last discovery cycle. If you specify a value of $True for this parameter,
        specify a value for the DeltaDiscoveryMins parameter.

    .PARAMETER DeltaDiscoveryMins
        Specifies the number of minutes for the delta discovery.

    .PARAMETER EnableFilteringExpiredLogon
        Indicates whether Configuration Manager discovers only computers that have logged onto a
        domain within a specified number of days. Specify the number of days by using the
        TimeSinceLastLogonDays parameter.

    .PARAMETER TimeSinceLastLogonDays
        Specify the number of days for EnableFilteringExpiredLogon.

    .PARAMETER EnableFilteringExpiredPassword
        Indicates whether Configuration Manager discovers only computers that have updated ther
        account password within a specified number of days. Specify the number of days by using the
        TimeSinceLastPasswordUpdateDays parameter.

    .PARAMETER TimeSinceLastPasswordUpdateDays
        Specify the number of days for EnableFilteringExpiredPassword.

    .PARAMETER DiscoverDistributionGroupMembership
        Specify if group discovery will discover distribution groups and the members of the group.

    .PARAMETER GroupDiscoveryScope
        Specifies an array of Group Discovery Scopes to match to the discovery.

    .PARAMETER GroupDiscoveryScopeToInclude
        Specifies an array of Group Discovery Scopes to add to the discovery.

    .PARAMETER GroupDiscoveryScopeToExclude
        Specifies an array of names of Group Discovery Scopes to exclude to the discovery.

    .PARAMETER Start
        Specifies the start date and start time for the group discovery schedule Month/Day/Year, example 1/1/2020 02:00.

    .PARAMETER ScheduleType
        Specifies the schedule type for the group discovery schedule.

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
        [Boolean]
        $EnableFilteringExpiredLogon,

        [Parameter()]
        [ValidateRange(14,720)]
        [UInt32]
        $TimeSinceLastLogonDays,

        [Parameter()]
        [Boolean]
        $EnableFilteringExpiredPassword,

        [Parameter()]
        [ValidateRange(30,720)]
        [UInt32]
        $TimeSinceLastPasswordUpdateDays,

        [Parameter()]
        [Boolean]
        $DiscoverDistributionGroupMembership,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $GroupDiscoveryScope,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $GroupDiscoveryScopeToInclude,

        [Parameter()]
        [String[]]
        $GroupDiscoveryScopeToExclude,

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
    $state = Get-TargetResource -SiteCode $SiteCode -Enabled $Enabled
    $result = $true
    $testResult = $true
    $schedResult = $true

    if ($Enabled -eq $true)
    {
        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = @('Enabled','EnableDeltaDiscovery','DeltaDiscoveryMins','EnableFilteringExpiredLogon',
                              'TimeSinceLastLogonDays','EnableFilteringExpiredPassword','TimeSinceLastPasswordUpdateDays',
                              'DiscoverDistributionGroupMembership')
        }

        $testResult = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

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

        if (($EnableDeltaDiscovery -eq $true -and $state.EnableDeltaDiscovery -eq $false) -and
                (-not $PSBoundParameters.ContainsKey('DeltaDiscoveryMins')))
        {
            Write-Warning -Message $script:localizedData.DeltaNoInterval
        }

        if ($PSBoundParameters.ContainsKey('GroupDiscoveryScope'))
        {
            if ($PSBoundParameters.ContainsKey('GroupDiscoveryScopeToInclude') -or
                $PSBoundParameters.ContainsKey('GroupDiscoveryScopeToExclude'))
            {
                Write-Warning -Message $script:localizedData.GdsIgnore
            }
        }
        elseif (-not $PSBoundParameters.ContainsKey('GroupDiscoveryScope') -and
                $PSBoundParameters.ContainsKey('GroupDiscoveryScopeToInclude') -and
                $PSBoundParameters.ContainsKey('GroupDiscoveryScopeToExclude'))
        {
            foreach ($item in $GroupDiscoveryScopeToInclude)
            {
                if ($GroupDiscoveryScopeToExclude -contains $item.Name)
                {
                    Write-Warning -Message ($script:localizedData.GdsInEx -f $item.Name)
                    $result = $false
                }
            }
        }

        if ($GroupDiscoveryScope -or $GroupDiscoveryScopeToInclude)
        {
            if ($GroupDiscoveryScope)
            {
                $refObject = $GroupDiscoveryScope
            }
            elseif ($GroupDiscoveryScopeToInclude)
            {
                $refObject = $GroupDiscoveryScopeToInclude
            }

            $compareParams = @{
                ReferenceObject  = $refObject
                DifferenceObject = $state.GroupDiscoveryScope
                Property         = 'Recurse','Name','LdapLocation'
                IncludeEqual     = $null
            }

            $compare = Compare-Object @compareParams
            $removing = @()
            $missing = @()
            foreach ($item in $compare)
            {
                if ($item.SideIndicator -eq '<=')
                {
                    if ($state.GroupDiscoveryScope.Name -contains $item.Name)
                    {
                        Write-Verbose -Message ($script:localizedData.GdsUpdate -f $item.Name, $item.LdapLocation, $item.Recurse,$item.LdapLocation, $item.Recurse)
                    }
                    else
                    {
                        Write-Verbose -Message ($script:localizedData.GdsMissing -f $item.Name, $item.LdapLocation, $item.Recurse)
                    }

                    $result = $false
                }

                if ($GroupDiscoveryScope)
                {
                    if ($item.SideIndicator -eq '=>')
                    {
                        #if ($refObject.Name -notcontains $item.Name)
                        #{
                            Write-Verbose -Message ($script:localizedData.GdsExtra -f $item.Name)
                            $result = $false
                        #}
                    }
                }
            }
        }

        if ((-not $GroupDiscoveryScope) -and ($GroupDiscoveryScopeToExclude))
        {
            foreach ($item in $GroupDiscoveryScopeToExclude)
            {
                if ($state.GroupDiscoveryScope.Name -contains $item)
                {
                    Write-Verbose -Message ($script:localizedData.GdsExtra -f $item)
                    $result = $false
                }
            }
        }

        if ($result -eq $false -or $testResult -eq $false -or $schedResult -eq $false)
        {
            $result = $false
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
