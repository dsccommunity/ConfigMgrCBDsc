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

    .PARAMETER CollectionName
        Specifies a name for the collection.

    .PARAMETER CollectionType
        Specifies the type of collection. Valid values are User and Device.
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
        [String]
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('User','Device')]
        [String]
        $CollectionType
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $collection = Get-CMCollection -Name $CollectionName

    if ($collection)
    {
        $refresh = switch ($collection.RefreshType)
        {
            '1' { 'Manual' }
            '2' { 'Periodic' }
            '4' { 'Continuous' }
            '6' { 'Both' }
        }

        $type = switch ($collection.CollectionType)
        {
            '1' { 'User' }
            '2' { 'Device' }
        }

        if ($type -eq 'User')
        {
            $rules = Get-CMUserCollectionQueryMembershipRule -CollectionName $collection.Name | Select-Object QueryExpression, RuleName
            [array]$excludes = (Get-CMUserCollectionExcludeMembershipRule -CollectionName $collection.Name).RuleName
            [array]$directMember = (Get-CMUserCollectionDirectMembershipRule -CollectionName $collection.Name).ResourceID
        }
        else
        {
            $rules = Get-CMDeviceCollectionQueryMembershipRule -CollectionName $collection.Name | Select-Object QueryExpression, RuleName
            [array]$excludes = (Get-CMDeviceCollectionExcludeMembershipRule -CollectionName $collection.Name).RuleName
            [array]$directMember = (Get-CMDeviceCollectionDirectMembershipRule -CollectionName $collection.Name).ResourceID
        }

        $cSchedule = $collection.RefreshSchedule

        if ($cSchedule.DaySpan -gt 0)
        {
            $rInterval = 'Days'
            $rCount = $cSchedule.DaySpan
        }
        elseif ($cSchedule.HourSpan -gt 0)
        {
            $rInterval = 'Hours'
            $rCount = $cSchedule.HourSpan
        }
        elseif ($cSchedule.MinuteSpan -gt 0)
        {
            $rInterval = 'Minutes'
            $rCount = $cSchedule.MinuteSpan
        }

        if ($rInterval)
        {
            $schedule = New-CimInstance -ClassName DSC_CMCollectionRefreshSchedule -Property @{
                RecurInterval = $rInterval
                RecurCount    = $rCount
            } -ClientOnly -Namespace 'root/microsoft/Windows/DesiredStateConfiguration'
        }

        if ($rules)
        {
            $cimCollection = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'

            foreach ($rule in $rules)
            {
                $cimcollection += (New-CimInstance -ClassName DSC_CMCollectionQueryRules -Property @{
                    QueryExpression = $rule.QueryExpression
                    RuleName        = $rule.RuleName
                } -ClientOnly -Namespace 'root/microsoft/Windows/DesiredStateConfiguration')
            }
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode               = $SiteCode
        CollectionName         = $CollectionName
        Comment                = $collection.Comment
        CollectionType         = $type
        LimitingCollectionName = $collection.LimitToCollectionName
        RefreshSchedule        = $schedule
        RefreshType            = $refresh
        QueryRules             = $cimcollection
        ExcludeMembership      = $excludes
        DirectMembership       = $directMember
        Ensure                 = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER CollectionName
        Specifies a name for the collection.

    .PARAMETER CollectionType
        Specifies the type of collection. Valid values are User and Device.

    .PARAMETER LimitingCollectionName
        Specifies the name of a collection to use as the default scope for this collection.
        Limiting collection is not evaluated in Test and is only used
        if the collection needs created.

    .PARAMETER Comment
        Specifies a comment for the collection.

    .PARAMETER RefreshSchedule
        Specifies a schedule that determines when Configuration Manager refreshes the collection.

    .PARAMETER RefreshType
        Specifies how Configuration Manager refreshes the collection.
        Valid values are: Manual, Periodic, Continuous, and Both.

    .PARAMETER QueryRules
        Specifies the name of the rule and the query expression that Configuration Manager uses to update collections.

    .PARAMETER ExcludeMembership
        Specifies the collection name to exclude members from. If clients are in the excluded collection they will
        not be added to the collection.

    .PARAMETER DirectMembership
        Specifies the resourceid for the direct membership rule.

    .PARAMETER Ensure
        Specifies if the collection is to be present or absent.
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
        [ValidateSet('User','Device')]
        [String]
        $CollectionType,

        [Parameter()]
        [String]
        $LimitingCollectionName,

        [Parameter()]
        [String]
        $Comment,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $RefreshSchedule,

        [Parameter()]
        [ValidateSet('Manual','Periodic','Continuous','Both')]
        [String]
        $RefreshType,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $QueryRules,

        [Parameter()]
        [String[]]
        $ExcludeMembership,

        [Parameter()]
        [String[]]
        $DirectMembership,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode -CollectionName $CollectionName -CollectionType $CollectionType

        if ($Ensure -eq 'Present')
        {
            if ($state.Ensure -eq 'Absent')
            {
                Write-Verbose -Message ($script:localizedData.CollectionCreate -f $CollectionName)

                $newCollection = @{
                    Name                   = $CollectionName
                    CollectionType         = $CollectionType
                    LimitingCollectionName = $LimitingCollectionName
                }

                New-CMCollection @newCollection
            }

            $buildingParams = @{
                Name = $CollectionName
            }

            $itemsForEval = @(
                @{
                    Name  = 'Comment'
                    Value = $Comment
                }
                @{
                    Name  = 'RefreshType'
                    Value = $RefreshType
                }
            )

            foreach ($item in $itemsForEval)
            {
                if ((-not [string]::IsNullOrEmpty($item.Value)) -and ($state[$item.Name] -ne $item.Value))
                {
                    Write-Verbose -Message ($script:localizedData.CollectionSetting -f $CollectionName, `
                        $item.name, $item.Value, $($state[$item.Name]))

                    $buildingParams += @{
                        $item.Name = $item.Value
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($RefreshSchedule))
            {
                $newSchedule = @{
                    RecurInterval = $RefreshSchedule.RecurInterval
                    RecurCount    = $RefreshSchedule.RecurCount
                }

                $desiredRefreshSchedule = New-CMSchedule @newSchedule

                if ($state.RefreshSchedule)
                {
                    $cSchedule = @{
                        RecurInterval = $state.RefreshSchedule.RecurInterval
                        RecurCount    = $state.RefreshSchedule.RecurCount
                    }

                    $currentSchedule = New-CMSchedule @cSchedule
                    $array = @('DayDuration','DaySpan','HourDuration','HourSpan','IsGMT','MinuteDuration','MinuteSpan')

                    foreach ($item in $array)
                    {
                        if (($desiredRefreshSchedule).$($item) -ne ($currentSchedule).$($item))
                        {
                            Write-Verbose -Message ($script:localizedData.ScheduleItem `
                                -f $item, $($desiredRefreshSchedule).$($item), $($currentSchedule).$($item))
                            $setSchedule = $true
                        }
                    }
                }
                else
                {
                    $setSchedule = $true
                }
            }

            if ($setSchedule)
            {
                $buildingParams += @{
                    RefreshSchedule = $desiredRefreshSchedule
                }
            }

            if ($buildingParams.Count -gt 1)
            {
                Set-CMCollection @buildingParams
            }

            if (-not [string]::IsNullOrEmpty($ExcludeMembership))
            {
                foreach ($member in $ExcludeMembership)
                {
                    $excludeRule = @{}

                    if (($null -eq $state.ExcludeMembership) -or ($state.ExcludeMembership -notcontains $member))
                    {
                        $excludeRule = @{
                            CollectionName        = $CollectionName
                            ExcludeCollectionName = $member
                        }

                        Write-Verbose -Message ($script:localizedData.ExcludeMemberRule -f $CollectionName, $member)

                        if ($CollectionType -eq 'User')
                        {
                            Add-CMUserCollectionExcludeMembershipRule @excludeRule
                        }
                        else
                        {
                            Add-CMDeviceCollectionExcludeMembershipRule @excludeRule
                        }
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($DirectMembership))
            {
                foreach ($member in $DirectMembership)
                {
                    $directRule = @{}

                    if (($null -eq $state.DirectMembership) -or ($state.DirectMembership -notcontains $member))
                    {
                        $directRule = @{
                            CollectionName = $CollectionName
                            ResourceId     = $member
                        }

                        Write-Verbose -Message ($script:localizedData.DirectMemberRule -f $CollectionName, $member)

                        if ($CollectionType -eq 'User')
                        {
                            Add-CMUserCollectionDirectMembershipRule @directRule
                        }
                        else
                        {
                            Add-CMDeviceCollectionDirectMembershipRule @directRule
                        }
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($QueryRules))
            {
                foreach ($rule in $QueryRules)
                {
                    $importRule = @{}

                    if (($null -eq $state.QueryRules) -or
                       ($state.QueryRules.QueryExpression.Replace(' ','') -notcontains $rule.QueryExpression.Replace(' ','')))
                    {
                        Write-Verbose -Message ($script:localizedData.QueryRule -f $CollectionName, $($rule.QueryExpression))

                        $importRule = @{
                            CollectionName  = $CollectionName
                            RuleName        = $rule.RuleName
                            QueryExpression = $rule.QueryExpression
                        }

                        if ($CollectionType -eq 'User')
                        {
                            Add-CMUserCollectionQueryMembershipRule @importRule
                        }
                        else
                        {
                            Add-CMDeviceCollectionQueryMembershipRule @importRule
                        }
                    }
                }
            }
        }
        else
        {
            if ($state.Ensure -eq 'Present')
            {
                Write-Verbose -Message ($script:localizedData.RemoveCollection -f $CollectionName)
                Remove-CMCollection -Name $CollectionName
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
        Specifies the site code for Configuration Manager site.

    .PARAMETER CollectionName
        Specifies a name for the collection.

    .PARAMETER CollectionType
        Specifies the type of collection. Valid values are User and Device.

    .PARAMETER LimitingCollectionName
        Specifies the name of a collection to use as the default scope for this collection.
        Limiting collection is not evaluated in Test and is only used
        if the collection needs created.

    .PARAMETER Comment
        Specifies a comment for the collection.

    .PARAMETER RefreshSchedule
        Specifies a schedule that determines when Configuration Manager refreshes the collection.

    .PARAMETER RefreshType
        Specifies how Configuration Manager refreshes the collection.
        Valid values are: Manual, Periodic, Continuous, and Both.

    .PARAMETER QueryRules
        Specifies the name of the rule and the query expression that Configuration Manager uses to update collections.

    .PARAMETER ExcludeMembership
        Specifies the collection name to exclude members from. If clients are in the excluded collection they will
        not be added to the collection.

    .PARAMETER DirectMembership
        Specifies the resourceid for the direct membership rule.

    .PARAMETER Ensure
        Specifies if the collection is to be present or absent.
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
        [ValidateSet('User','Device')]
        [String]
        $CollectionType,

        [Parameter()]
        [String]
        $LimitingCollectionName,

        [Parameter()]
        [String]
        $Comment,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $RefreshSchedule,

        [Parameter()]
        [ValidateSet('Manual','Periodic','Continuous','Both')]
        [String]
        $RefreshType,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $QueryRules,

        [Parameter()]
        [String[]]
        $ExcludeMembership,

        [Parameter()]
        [String[]]
        $DirectMembership,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -CollectionName $CollectionName -CollectionType $CollectionType
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.CollectionAbsent -f $CollectionName)
            $result = $false
        }
        else
        {
            $itemsForEval = @(
                @{
                    Name  = 'Comment'
                    Value = $Comment
                }
                @{
                    Name  = 'RefreshType'
                    Value = $RefreshType
                }
            )

            foreach ($item in $itemsForEval)
            {
                if ((-not [string]::IsNullOrEmpty($item.Value)) -and ($state[$item.Name] -ne $item.Value))
                {
                    Write-Verbose -Message ($script:localizedData.CollectionSetting -f $CollectionName, `
                    $item.name, $item.Value, $($state[$item.Name]))
                    $result = $false
                }
            }

            if (-not [string]::IsNullOrEmpty($RefreshSchedule))
            {
                if ($state.RefreshSchedule)
                {
                    $newSchedule = @{
                        RecurInterval = $RefreshSchedule.RecurInterval
                        RecurCount    = $RefreshSchedule.RecurCount
                    }

                    $desiredRefreshSchedule = New-CMSchedule @newSchedule

                    $cSchedule = @{
                        RecurInterval = $state.RefreshSchedule.RecurInterval
                        RecurCount    = $state.RefreshSchedule.RecurCount
                    }

                    $currentSchedule = New-CMSchedule @cSchedule
                    $array = @('DayDuration','DaySpan','HourDuration','HourSpan','IsGMT','MinuteDuration','MinuteSpan')

                    foreach ($item in $array)
                    {
                        if (($desiredRefreshSchedule).$($item) -ne ($currentSchedule).$($item))
                        {
                            Write-Verbose -Message ($script:localizedData.ScheduleItem `
                                -f $item, $($desiredRefreshSchedule).$($item), $($currentSchedule).$($item))
                            $result = $false
                        }
                    }
                }
                else
                {
                    $result = $false
                }
            }

            if (-not [string]::IsNullOrEmpty($ExcludeMembership))
            {
                foreach ($member in $ExcludeMembership)
                {
                    if (([string]::IsNullOrEmpty($state.ExcludeMembership)) -or ($state.ExcludeMembership -notcontains $member))
                    {
                        Write-Verbose -Message ($script:localizedData.ExcludeMemberRule -f $CollectionName, $member)
                        $result = $false
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($DirectMembership))
            {
                foreach ($member in $DirectMembership)
                {
                    if (($null -eq $state.DirectMembership) -or ($state.DirectMembership -notcontains $member))
                    {
                        Write-Verbose -Message ($script:localizedData.DirectMemberRule -f $CollectionName, $member)
                        $result = $false
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($QueryRules))
            {
                foreach ($rule in $QueryRules)
                {
                    if (([string]::IsNullOrEmpty($state.QueryRules.QueryExpression)) -or
                       ($state.QueryRules.QueryExpression.Replace(' ','') -notcontains $rule.QueryExpression.Replace(' ','')))
                    {
                        Write-Verbose -Message ($script:localizedData.QueryRule -f $CollectionName, $rule.QueryExpression)
                        $result = $false
                    }
                }
            }
        }
    }
    else
    {
        if ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveCollection -f $CollectionName)
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
