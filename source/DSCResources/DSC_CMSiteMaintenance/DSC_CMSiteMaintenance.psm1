$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER TaskName
        Specifies the name of the maintenance task.

    .PARAMETER Enabled
        Specifies if the task is enabled or disabled.
        Not used in Get-TargetResource.

    .NOTES
        Device Type specifies what params are avalible TaskType 1 is backup TaskType 2 is SummaryTask and 3 is MaintenanceTask
        TaskType 1 requires DeviceName (backup location) TaskType 2 may set run now and RunIntervalMins and TaskType 3 is standard
        Maintenance Tasks.  On Type 1 and 2 DeleteOlderThan have a value of 0.  TaskName of Clear Install Flag in the console equals
        'Clear Undiscovered Clients'.
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
        [ValidateSet('Delete Aged Inventory History','Delete Aged Metering Data','Clear Undiscovered Clients','Delete Obsolete Alerts',
        'Delete Aged Replication Data','Delete Aged Device Wipe Record','Delete Aged Enrolled Devices','Delete Aged User Device Affinity Data',
        'Delete Duplicate System Discovery Data','Delete Aged Unknown Computers','Delete Expired MDM Bulk Enroll Package Records','Backup SMS Site Server',
        'Delete Aged Status Messages','Delete Aged Metering Summary Data','Delete Inactive Client Discovery Data',
        'Delete Aged Application Revisions','Delete Aged Replication Summary Data','Delete Obsolete Forest Discovery Sites And Subnets',
        'Delete Aged Threat Data','Delete Aged Delete Detection Data','Delete Aged Distribution Point Usage Stats',
        'Delete Orphaned Client Deployment State Records','Rebuild Indexes','Delete Aged Discovery Data','Summarize File Usage Metering Data',
        'Delete Obsolete Client Discovery Data','Delete Aged Log Data','Delete Aged Application Request Data',
        'Check Application Title with Inventory Information','Delete Aged EP Health Status History Data','Delete Aged Notification Task History',
        'Delete Aged Passcode Records','Delete Aged Console Connection Data','Monitor Keys','Delete Aged Collected Files',
        'Summarize Monthly Usage Metering Data','Delete Aged Computer Association Data','Delete Aged Client Download History',
        'Delete Aged Exchange Partnership','Summarize Installed Software Data','Delete Aged Client Operations',
        'Delete Aged Notification Server History','Update Application Available Targeting',
        'Delete Aged Cloud Management Gateway Traffic Data','Update Application Catalog Tables')]
        [String]
        $TaskName,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $Enabled
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $siteType = Get-CMSiteDefinition -SiteCode $SiteCode

    if ($TaskName -ne 'Update Application Catalog Tables')
    {
        $siteMaintenance = (Get-CMSiteMaintenanceTask -Name $TaskName -SiteCode $SiteCode).ManagedObject

        if ($siteMaintenance)
        {
            $days = $siteMaintenance.DaysOfWeek

            $daysArr = @('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')
            $weekDays = @()
            do
            {
                $dayMax = [Math]::Truncate([Math]::Log($days,2))
                $weekDays += $daysArr[$dayMax]
                $days -= [Math]::Pow(2,$dayMax)
            }
            while ($days -gt 0 )

            $bTime = $($siteMaintenance.BeginTime).Substring(8,4)
            $lTime = $($siteMaintenance.LatestBeginTime).Substring(8,4)
            $enabledStatus = $siteMaintenance.Enabled
        }
    }
    else
    {
        $siteMaintenance = Get-CMSiteSummaryTask -TaskName $TaskName

        $interval = $($siteMaintenance.RunInterval) / 60
        if ([string]::IsNullOrEmpty($siteMaintenance.TaskParameter))
        {
            $enabledStatus = $true
        }
        else
        {
            $enabledStatus = $false
        }
    }

    return  @{
        SiteCode            = $SiteCode
        TaskName            = $TaskName
        Enabled             = $enabledStatus
        DaysOfWeek          = $weekDays
        BeginTime           = $bTime
        LatestBeginTime     = $lTime
        DeleteOlderThanDays = $siteMaintenance.DeleteOlderThan
        RunInterval         = $interval
        BackupLocation      = $siteMaintenance.DeviceName
        TaskType            = $siteMaintenance.TaskType
        SiteType            = $siteType.SiteType
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER TaskName
        Specifies the name of the maintenance task.

    .PARAMETER Enabled
        Specifies if the task is enabled or disabled.

    .PARAMETER DaysOfWeek
        Specifies an array of day names that determine the days of each week on which the maintenance task runs.

    .PARAMETER BeginTime
        Specifies the time at which a maintenance task starts.

    .PARAMETER LatestBeginTime
        Specifies the latest start time at which the maintenance task runs.

    .PARAMETER DeleteOlderThanDays
        Specifies how many days to delete data that has been inactive for.

    .PARAMETER BackupLocation
        Specifies the backup location for Backup Site Server.

    .PARAMETER RunInterval
        Species the run interval in minutes for Application Catalog Tables task only.

    .NOTES
        Device Type specifies what params are avaible TaskType 1 is backup TaskType 2 is SummaryTask and 3 is MaintenanceTask
        TaskType 1 requires DeviceName (backup location) TaskType 2 may set run now and RunIntervalMins and TaskType 3 is standard
        Maintenance Tasks.  On Type 1 and 2 DeleteOlderThan have a value of 0.  TaskName of Clear Install Flag in the console equals
        'Clear Undiscovered Clients'.
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
        [ValidateSet('Delete Aged Inventory History','Delete Aged Metering Data','Clear Undiscovered Clients','Delete Obsolete Alerts',
        'Delete Aged Replication Data','Delete Aged Device Wipe Record','Delete Aged Enrolled Devices','Delete Aged User Device Affinity Data',
        'Delete Duplicate System Discovery Data','Delete Aged Unknown Computers','Delete Expired MDM Bulk Enroll Package Records','Backup SMS Site Server',
        'Delete Aged Status Messages','Delete Aged Metering Summary Data','Delete Inactive Client Discovery Data',
        'Delete Aged Application Revisions','Delete Aged Replication Summary Data','Delete Obsolete Forest Discovery Sites And Subnets',
        'Delete Aged Threat Data','Delete Aged Delete Detection Data','Delete Aged Distribution Point Usage Stats',
        'Delete Orphaned Client Deployment State Records','Rebuild Indexes','Delete Aged Discovery Data','Summarize File Usage Metering Data',
        'Delete Obsolete Client Discovery Data','Delete Aged Log Data','Delete Aged Application Request Data',
        'Check Application Title with Inventory Information','Delete Aged EP Health Status History Data','Delete Aged Notification Task History',
        'Delete Aged Passcode Records','Delete Aged Console Connection Data','Monitor Keys','Delete Aged Collected Files',
        'Summarize Monthly Usage Metering Data','Delete Aged Computer Association Data','Delete Aged Client Download History',
        'Delete Aged Exchange Partnership','Summarize Installed Software Data','Delete Aged Client Operations',
        'Delete Aged Notification Server History','Update Application Available Targeting',
        'Delete Aged Cloud Management Gateway Traffic Data','Update Application Catalog Tables')]
        [String]
        $TaskName,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $Enabled,

        [Parameter()]
        [ValidateRange(1,365)]
        [UInt32]
        $DeleteOlderThanDays,

        [Parameter()]
        [ValidateScript({
            $validate = [datetime]::ParseExact("$_","HHmm",$null)
            if ($validate)
            {
                return $true
            }
        })]
        [String]
        $BeginTime,

        [Parameter()]
        [ValidateScript({
            $validate = [datetime]::ParseExact("$_","HHmm",$null)
            if ($validate)
            {
                return $true
            }
        })]
        [String]
        $LatestBeginTime,

        [Parameter()]
        [String]
        $BackupLocation,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String[]]
        $DaysOfWeek,

        [Parameter()]
        [ValidateRange(3,1440)]
        [UInt32]
        $RunInterval
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -TaskName $TaskName -Enabled $Enabled

    try
    {
        $casOnly = @('Check Application Title with Inventory Information','Delete Duplicate System Discovery Data')
        $primaryOnly = @('Clear Undiscovered Clients','Delete Aged Application Request Data','Delete Aged Client Download History',
            'Delete Aged Collected Files','Delete Aged Computer Association Data','Delete Aged Device Wipe Record',
            'Delete Aged Discovery Data','Delete Aged Enrolled Devices','Delete Aged EP Health Status History Data',
            'Delete Aged Exchange Partnership','Delete Aged Inventory History','Delete Aged Metering Data',
            'Delete Aged Metering Summary Data','Delete Aged Notification Task History','Delete Aged Threat Data'
            'Delete Aged Unknown Computers','Delete Aged User Device Affinity Data','Delete Inactive Client Discovery Data'
            'Delete Obsolete Client Discovery Data','Delete Orphaned Client Deployment State Records','Evaluate Collection Members',
            'Summarize File Usage Metering Data','Summarize Installed Software Data','Summarize Monthly Usage Metering Data',
            'Update Application Available Targeting','Update Application Catalog Tables'
        )

        if ($state.SiteType -eq 4)
        {
            if ($primaryOnly -contains $TaskName)
            {
                throw ($script:localizedData.PrimaryOnly -f $TaskName)
            }
        }
        elseif ($state.SiteType -eq 2)
        {
            if ($casOnly -contains $TaskName)
            {
                throw ($script:localizedData.CasOnly -f $TaskName)
            }
        }

        if ($Enabled -eq $true)
        {
            $buildingParams = @{
                SiteCode = $SiteCode
                TaskName = $TaskName
            }

            if ($TaskName -ne 'Update Application Catalog Tables')
            {
                if ($Enabled -ne $state.Enabled)
                {
                    $buildingParams += @{
                        Enabled = $Enabled
                    }
                }

                if ($PSBoundParameters.ContainsKey('BeginTime') -and $BeginTime -ne $state.BeginTime)
                {
                    Write-Verbose -Message ($script:localizedData.BeginTime -f $BeginTime)
                    $bTime = [datetime]::ParseExact("$BeginTime","HHmm",$null)

                    $buildingParams += @{
                        BeginTime = $bTime
                    }
                }

                if (-not [string]::IsNullOrEmpty($LatestBeginTime) -and $LatestBeginTime -ne $state.LatestBeginTime)
                {
                    Write-Verbose -Message ($script:localizedData.EndTime -f $LatestBeginTime)
                    $lTime = [datetime]::ParseExact("$LatestBeginTime","HHmm",$null)

                    $buildingParams += @{
                        LatestBeginTime = $lTime
                    }
                }

                if ($PSBoundParameters.ContainsKey('DaysOfWeek'))
                {
                    $week = $false
                    if ($DaysOfWeek.Count -ne $($state.DaysOfWeek).Count)
                    {
                        $week = $true
                    }
                    else
                    {
                        foreach ($day in $DaysOfWeek)
                        {
                            if ($state.DaysOfWeek -notcontains $day)
                            {
                                $week = $true
                            }
                        }
                    }

                    if ($week -eq $true)
                    {
                        Write-Verbose -Message ($script:localizedData.Days -f $TaskName, ($DaysOfWeek|Out-String))

                        $buildingParams += @{
                            DaysOfWeek = $DaysOfWeek
                        }
                    }
                }

                if ($state.TaskType -eq 1)
                {
                    if (([string]::IsNullOrEmpty($BackupLocation)) -and ([string]::IsNullOrEmpty($state.BackupLocation)))
                    {
                        throw $script:localizedData.MissingBackupLoc
                    }

                    if ((-not [string]::IsNullOrEmpty($BackupLocation)) -and ($BackupLocation -ne $state.BackupLocation))
                    {
                        Write-Verbose -Message ($script:localizedData.SetBackupLocation -f  $BackupLocation)

                        $buildingParams += @{
                            DeviceName = $BackupLocation
                        }
                    }
                }
                elseif (($state.TaskType -eq 3) -and ($PSBoundParameters.ContainsKey('DeleteOlderThanDays')))
                {
                    if ($DeleteOlderThanDays -ne $state.DeleteOlderThanDays)
                    {
                        Write-Verbose -Message ($script:localizedData.SetDeleteOlderThan -f $DeleteOlderThanDays)

                        $buildingParams += @{
                            DeleteOlderThanDays = $DeleteOlderThanDays
                        }
                    }
                }

                if ($buildingParams.Count -gt 2)
                {
                    Set-CMSiteMaintenanceTask @buildingParams
                }
            }
            else
            {
                if (($PSBoundParameters.ContainsKey('RunInterval')) -and ($RunInterval -ne $State.RunInterval))
                {
                    $buildingParams += @{
                        RunIntervalMins = $RunInterval
                    }
                }

                if ($buildingParams.Count -gt 2)
                {
                    Write-Verbose -Message ($script:localizedData.SettingSummaryTask -f $TaskName, $RunInterval)
                    Set-CMSiteSummaryTask @buildingParams
                }
            }
        }
        elseif ($state.Enabled -eq $true)
        {
            Write-Verbose -Message ($script:localizedData.SetDisabled -f $TaskName)

            if ($TaskName -eq 'Update Application Catalog Tables')
            {
                Set-CMSiteSummaryTask -TaskName $TaskName -DisableFixedRun -SiteCode $SiteCode
            }
            else
            {
                Set-CMSiteMaintenanceTask -Name $TaskName -Enabled $Enabled -SiteCode $SiteCode
            }
        }
    }
    catch
    {
        throw $_
    }
    finally
    {
        Set-Location -Path $env:windir
    }
}

<#
    .SYNOPSIS
        This will test the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER TaskName
        Specifies the name of the maintenance task.

    .PARAMETER Enabled
        Specifies if the task is enabled or disabled.

    .PARAMETER DaysOfWeek
        Specifies an array of day names that determine the days of each week on which the maintenance task runs.

    .PARAMETER BeginTime
        Specifies the time at which a maintenance task starts.

    .PARAMETER LatestBeginTime
        Specifies the latest start time at which the maintenance task runs.

    .PARAMETER DeleteOlderThanDays
        Specifies how many days to delete data that has been inactive for.

    .PARAMETER BackupLocation
        Specifies the backup location for Backup Site Server.

    .PARAMETER RunInterval
        Species the run interval in minutes for Application Catalog Tables task only.

    .NOTES
        Device Type specifies what params are avaible TaskType 1 is backup TaskType 2 is SummaryTask and 3 is MaintenanceTask
        TaskType 1 requires DeviceName (backup location) TaskType 2 may set run now and RunIntervalMins and TaskType 3 is standard
        Maintenance Tasks.  On Type 1 and 2 DeleteOlderThan have a value of 0.  TaskName of Clear Install Flag in the console equals
        'Clear Undiscovered Clients'.
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
        [ValidateSet('Delete Aged Inventory History','Delete Aged Metering Data','Clear Undiscovered Clients','Delete Obsolete Alerts',
        'Delete Aged Replication Data','Delete Aged Device Wipe Record','Delete Aged Enrolled Devices','Delete Aged User Device Affinity Data',
        'Delete Duplicate System Discovery Data','Delete Aged Unknown Computers','Delete Expired MDM Bulk Enroll Package Records','Backup SMS Site Server',
        'Delete Aged Status Messages','Delete Aged Metering Summary Data','Delete Inactive Client Discovery Data',
        'Delete Aged Application Revisions','Delete Aged Replication Summary Data','Delete Obsolete Forest Discovery Sites And Subnets',
        'Delete Aged Threat Data','Delete Aged Delete Detection Data','Delete Aged Distribution Point Usage Stats',
        'Delete Orphaned Client Deployment State Records','Rebuild Indexes','Delete Aged Discovery Data','Summarize File Usage Metering Data',
        'Delete Obsolete Client Discovery Data','Delete Aged Log Data','Delete Aged Application Request Data',
        'Check Application Title with Inventory Information','Delete Aged EP Health Status History Data','Delete Aged Notification Task History',
        'Delete Aged Passcode Records','Delete Aged Console Connection Data','Monitor Keys','Delete Aged Collected Files',
        'Summarize Monthly Usage Metering Data','Delete Aged Computer Association Data','Delete Aged Client Download History',
        'Delete Aged Exchange Partnership','Summarize Installed Software Data','Delete Aged Client Operations',
        'Delete Aged Notification Server History','Update Application Available Targeting',
        'Delete Aged Cloud Management Gateway Traffic Data','Update Application Catalog Tables')]
        [String]
        $TaskName,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $Enabled,

        [Parameter()]
        [ValidateRange(1,365)]
        [UInt32]
        $DeleteOlderThanDays,

        [Parameter()]
        [ValidateScript({
            $validate = [datetime]::ParseExact("$_","HHmm",$null)
            if ($validate)
            {
                return $true
            }
        })]
        [String]
        $BeginTime,

        [Parameter()]
        [ValidateScript({
            $validate = [datetime]::ParseExact("$_","HHmm",$null)
            if ($validate)
            {
                return $true
            }
        })]
        [String]
        $LatestBeginTime,

        [Parameter()]
        [String]
        $BackupLocation,

        [Parameter()]
        [ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
        [String[]]
        $DaysOfWeek,

        [Parameter()]
        [ValidateRange(3,1440)]
        [UInt32]
        $RunInterval
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -TaskName $TaskName -Enabled $Enabled
    $result = $true

    $casOnly = @('Check Application Title with Inventory Information','Delete Duplicate System Discovery Data')
    $primaryOnly = @('Clear Undiscovered Clients','Delete Aged Application Request Data','Delete Aged Client Download History',
        'Delete Aged Collected Files','Delete Aged Computer Association Data','Delete Aged Device Wipe Record',
        'Delete Aged Discovery Data','Delete Aged Enrolled Devices','Delete Aged EP Health Status History Data',
        'Delete Aged Exchange Partnership','Delete Aged Inventory History','Delete Aged Metering Data',
        'Delete Aged Metering Summary Data','Delete Aged Notification Task History','Delete Aged Threat Data'
        'Delete Aged Unknown Computers','Delete Aged User Device Affinity Data','Delete Inactive Client Discovery Data'
        'Delete Obsolete Client Discovery Data','Delete Orphaned Client Deployment State Records','Evaluate Collection Members',
        'Summarize File Usage Metering Data','Summarize Installed Software Data','Summarize Monthly Usage Metering Data',
        'Update Application Available Targeting','Update Application Catalog Tables'
    )

    if ($state.SiteType -eq 4)
    {
        if ($primaryOnly -contains $TaskName)
        {
            Write-Warning -Message ($script:localizedData.PrimaryOnly -f $TaskName)
            $result = $false
        }
    }
    elseif ($state.SiteType -eq 2)
    {
        if ($casOnly -contains $TaskName)
        {
            Write-Warning -Message ($script:localizedData.CasOnly -f $TaskName)
            $result = $false
        }
    }

    if ($Enabled -eq $true -and $result -ne $false)
    {
        if ($state.TaskType -eq 1)
        {
            $notNeedParams = @('DeleteOlderThanDays','RunInterval')

            foreach ($param in $notNeedParams)
            {
                if ($PSBoundParameters.ContainsKey($param))
                {
                    Write-Warning -Message ($script:localizedData.SpecifiedParam -f $param)
                }
            }

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = @('Enabled','BeginTime','LatestBeginTime','DaysOfWeek','BackupLocation')
            }

            $result = Test-DscParameterState @testParams -TurnOffTypeChecking -SortArrayValues -Verbose
        }
        elseif ($state.TaskType -eq 2)
        {
            $notNeedParams = @('DeleteOlderThanDays','BackupLocation','RunInterval')

            foreach ($param in $notNeedParams)
            {
                if ($PSBoundParameters.ContainsKey($param))
                {
                    Write-Warning -Message ($script:localizedData.SpecifiedParam -f $param)
                }
            }

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = @('Enabled','BeginTime','LatestBeginTime','DaysOfWeek')
            }

            $result = Test-DscParameterState @testParams -TurnOffTypeChecking -SortArrayValues -Verbose
        }
        elseif ($state.TaskType -eq 3)
        {
            $notNeedParams = @('BackupLocation','RunInterval')

            foreach ($param in $notNeedParams)
            {
                if ($PSBoundParameters.ContainsKey($param))
                {
                    Write-Warning -Message ($script:localizedData.SpecifiedParam -f $param)
                }
            }

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = @('Enabled','BeginTime','LatestBeginTime','DaysOfWeek','DeleteOlderThanDays')
            }

            $result = Test-DscParameterState @testParams -TurnOffTypeChecking -SortArrayValues -Verbose
        }
        else
        {
            $notNeedParams = @('BeginTime','LatestBeginTime','DeleteOlderThanDays','BackupLocation')

            foreach ($param in $notNeedParams)
            {
                if ($PSBoundParameters.ContainsKey($param))
                {
                    Write-Warning -Message ($script:localizedData.SpecifiedParam -f $param)
                }
            }

            $testParams = @{
                CurrentValues = $state
                DesiredValues = $PSBoundParameters
                ValuesToCheck = @('Enabled','RunInterval')
            }

            $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose
        }
    }
    elseif ($state.Enabled -eq $true)
    {
        Write-Verbose ($script:localizedData.TestDisabled -f $TaskName)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path $env:windir
    return $result
}

Export-ModuleMember -Function *-TargetResource
