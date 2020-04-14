$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $psScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the CRL Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath -ChildPath (Join-Path -Path 'ConfigMgrCBDsc.ResourceHelper' -ChildPath 'ConfigMgrCBDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'Collections' -ResourcePath (Split-Path -Parent $script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER CollectionName
        Specifies a name for the collection.

    .PARAMETER CollectionType
        Specifies the type of collection. Valid values are User and Device.

    .PARAMETER LimitingCollectionName
        Specifies the name of a collection to use as the default scope for this collection.  Limiting collection is not evaluated in Test and is only used
        if the collection needs created.

    .PARAMETER Comment
        Specifies a comment for the collection.

    .PARAMETER RefreshSchedule
        Specifies a schedule that determines when Configuration Manager refreshes the collection.

    .PARAMETER RefreshType
        Specifies how Configuration Manager refreshes the collection. Valid values are: Manual, Periodic, Continuous, and Both.

    .PARAMETER QueryRules
        Specifies the name of the Rule and the query expression that Configuration Manager uses to update collections.

    .PARAMETER ExcludeMembership
        Specifies the collection name to exclude members from. If clients are in the excluded collection they will not be added to the collection.

    .PARAMETER DirectMembership
        Specifies the resourceid for the direct membership rule.

    .PARAMETER Ensure
        Specifies if the collection is to be present or absent.
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
        [ValidateSet('None','Periodic','Continuous','Both')]
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

    Write-Verbose -Message $localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule
    Set-Location -Path "$($SiteCode):\"

    $collection = Get-CMCollection -Name $CollectionName

    if ($collection)
    {
        $refresh = switch ($($collection.RefreshType))
        {
            '1' { 'None' }
            '2' { 'Periodic' }
            '4' { 'Continuous' }
            '6' { 'Both' }
        }

        $type = switch ($($collection.CollectionType))
        {
            '1' { 'User' }
            '2' { 'Device' }
        }

        if ($type -eq 'User')
        {
            $rules = Get-CMUserCollectionQueryMembershipRule -CollectionName $collection.Name

            if ($rules)
            {
                foreach ($rule in $rules)
                {
                    [array]$qRules += ($rule |Select-Object QueryExpression, RuleName)
                }
            }

            $excludes = (Get-CMUserCollectionExcludeMembershipRule -CollectionName $collection.Name).RuleName
            $directMember = (Get-CMUserCollectionDirectMembershipRule -CollectionName $collection.Name).ResourceID
        }
        else
        {
            $rules = Get-CMDeviceCollectionQueryMembershipRule -CollectionName $collection.Name

            if ($rules)
            {
                foreach ($rule in $rules)
                {
                    [array]$qRules += ($rule |Select-Object QueryExpression, RuleName)
                }
            }

            $excludes = (Get-CMDeviceCollectionExcludeMembershipRule -CollectionName $collection.Name).RuleName
            $directMember = (Get-CMDeviceCollectionDirectMembershipRule -CollectionName $collection.Name).ResourceID
        }
    }

    return @{
        SiteCode               = $SiteCode
        CollectionName         = $CollectionName
        Comment                = $collection.Comment
        CollectionType         = $type
        LimitingCollectionName = $collection.LimitToCollectionName
        RefreshSchedule        = $collection.RefreshSchedule
        RefreshType            = $refresh
        QueryRules             = $qRules
        ExcludeMembership      = $excludes
        DirectMembership       = $directMember
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
        Specifies the name of a collection to use as the default scope for this collection.  Limiting collection is not evaluated in Test and is only used
        if the collection needs created.

    .PARAMETER Comment
        Specifies a comment for the collection.

    .PARAMETER RefreshSchedule
        Specifies a schedule that determines when Configuration Manager refreshes the collection.

    .PARAMETER RefreshType
        Specifies how Configuration Manager refreshes the collection. Valid values are: Manual, Periodic, Continuous, and Both.

    .PARAMETER QueryRules
        Specifies the name of the Rule and the query expression that Configuration Manager uses to update collections.

    .PARAMETER ExcludeMembership
        Specifies the collection name to exclude members from. If clients are in the excluded collection they will not be added to the collection.

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
        [ValidateSet('None','Periodic','Continuous','Both')]
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

    Import-ConfigMgrPowerShellModule
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode -CollectionName $CollectionName -CollectionType $CollectionType
        $cn = Get-CMCollection -Name $CollectionName

        if ($Ensure -eq 'Present')
        {
            if ($null -eq $cn)
            {
                Write-Verbose -Message ($localizedData.CollectionAbsent -f $CollectionName)
                New-CMCollection -Name $CollectionName -CollectionType $CollectionType -LimitingCollectionName $LimitingCollectionName
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

            foreach($item in $itemsForEval)
            {
                if ((-not [string]::IsNullOrEmpty($item.Value)) -and ($state[$item.Name] -ne $item.Value))
                {
                    Write-Verbose -Message "$($item.Name) expected $($item.Value) returned $($state[$item.Name])"

                    $buildingParams += @{
                        $($item.Name) = $($item.Value)
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($RefreshSchedule))
            {
                $desiredRefreshSchedule = New-CMSchedule -RecurInterval $RefreshSchedule.RecurInterval -RecurCount $RefreshSchedule.RecurCount

                if ($state.RefreshSchedule)
                {
                    $array = @('DayDuration','DaySpan','HourDuration','HourSpan','IsGMT','MinuteDuration','MinuteSpan')

                    foreach ($item in $array)
                    {
                        if (($desiredRefreshSchedule).$($item) -ne ($state.RefreshSchedule).$($item))
                        {
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
                    if (($null -eq $state.ExcludeMembership) -or ($state.ExcludeMembership -notcontains $member))
                    {
                        Write-Verbose -Message ($localizedData.ExcludeMemberRule -f $CollectionName, $member)
                        if ($CollectionType -eq 'User')
                        {
                            Add-CMUserCollectionExcludeMembershipRule -CollectionName $CollectionName -ExcludeCollectionName $member
                        }
                        else
                        {
                            Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $CollectionName -ExcludeCollectionName $member
                        }
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($DirectMembership))
            {
                foreach ($member in $DirectMembership)
                {
                    if (($null -eq $state.DirectMembership) -or ($state.DirectMembership -notcontains $member))
                    {
                        Write-Verbose -Message ($localizedData.DirectMemberRule -f $CollectionName, $member)
                        if ($CollectionType -eq 'User')
                        {
                            Add-CMUserCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $member
                        }
                        else
                        {
                            Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $member
                        }
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($QueryRules))
            {
                $rules = @()
                foreach ($queryRule in $QueryRules)
                {
                    $rules += (
                        @{
                            QueryExpression = $queryRule.QueryExpression
                            RuleName        = $queryRule.RuleName
                        }
                    )
                }

                foreach ($rule in $rules)
                {
                    if (($null -eq $state.QueryRules) -or ($state.QueryRules.QueryExpression.Replace(' ','') -notcontains $rule.QueryExpression.Replace(' ','')))
                    {
                        Write-Verbose -Message ($localizedData.QueryRule -f $CollectionName, $($rule.QueryExpression))

                        if ($CollectionType -eq 'User')
                        {
                            Add-CMUserCollectionQueryMembershipRule -CollectionName $CollectionName -RuleName $rule.RuleName -QueryExpression $rule.QueryExpression
                        }
                        else
                        {
                            Add-CMDeviceCollectionQueryMembershipRule -CollectionName $CollectionName -RuleName $rule.RuleName -QueryExpression $rule.QueryExpression
                        }
                    }
                }
            }
        }
        else
        {
            if ($null -ne $cn)
            {
                Write-Verbose -Message ($localizedData.RemoveCollection -f $CollectionName)
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
        Specifies the name of a collection to use as the default scope for this collection.  Limiting collection is not evaluated in Test and is only used
        if the collection needs created.

    .PARAMETER Comment
        Specifies a comment for the collection.

    .PARAMETER RefreshSchedule
        Specifies a schedule that determines when Configuration Manager refreshes the collection.

    .PARAMETER RefreshType
        Specifies how Configuration Manager refreshes the collection. Valid values are: Manual, Periodic, Continuous, and Both.

    .PARAMETER QueryRules
        Specifies the name of the Rule and the query expression that Configuration Manager uses to update collections.

    .PARAMETER ExcludeMembership
        Specifies the collection name to exclude members from. If clients are in the excluded collection they will not be added to the collection.

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
        [ValidateSet('None','Periodic','Continuous','Both')]
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

    Import-ConfigMgrPowerShellModule
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -CollectionName $CollectionName -CollectionType $CollectionType
    $cn = Get-CMCollection -Name $CollectionName
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($null -eq $cn)
        {
            Write-Verbose -Message ($localizedData.CollectionAbsent -f $CollectionName)
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

            foreach($item in $itemsForEval)
            {
                if ((-not [string]::IsNullOrEmpty($item.Value)) -and ($state[$item.Name] -ne $item.Value))
                {
                    Write-Verbose -Message ($localizedData.CollectionSetting -f $CollectionName, $($item.name), $($item.Value), $($state[$item.Name]))
                    $result = $false
                }
            }

            if (-not [string]::IsNullOrEmpty($RefreshSchedule))
            {
                $desiredRefreshSchedule = New-CMSchedule -RecurInterval $RefreshSchedule.RecurInterval -RecurCount $RefreshSchedule.RecurCount

                $array = @('DayDuration','DaySpan','HourDuration','HourSpan','IsGMT','MinuteDuration','MinuteSpan')

                foreach ($item in $array)
                {
                    if (($desiredRefreshSchedule).$($item) -ne ($state.RefreshSchedule).$($item))
                    {
                        Write-Verbose -Message ($localizedData.scheduleItem -f $item, $($desiredRefreshSchedule.$($item)), $(($state.RefreshSchedule).$($item)))
                        $result = $false
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($ExcludeMembership))
            {
                foreach ($member in $ExcludeMembership)
                {
                    if (([string]::IsNullOrEmpty($state.ExcludeMembership)) -or ($state.ExcludeMembership -notcontains $member))
                    {
                        Write-Verbose -Message ($localizedData.ExcludeMemberRule -f $CollectionName, $member)
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
                        Write-Verbose -Message ($localizedData.DirectMemberRule -f $CollectionName, $member)
                        $result = $false
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($QueryRules))
            {
                $rules = @()
                foreach ($queryRule in $QueryRules)
                {
                    $rules += (
                        @{
                            QueryExpression = $queryRule.QueryExpression
                            RuleName        = $queryRule.RuleName
                        }
                    )
                }

                foreach ($rule in $rules)
                {
                    if (([string]::IsNullOrEmpty($state.QueryRules.QueryExpression)) -or
                       ($state.QueryRules.QueryExpression.Replace(' ','') -notcontains $rule.QueryExpression.Replace(' ','')))
                    {
                        Write-Verbose -Message ($localizedData.QueryRule -f $CollectionName, $($rule.QueryExpression))
                        $result = $false
                    }
                }
            }
        }
    }
    else
    {
        if ($null -ne $cn)
        {
            Write-Verbose -Message ($localizedData.RemoveCollection -f $CollectionName)
            $result = $false
        }
    }

    Write-Verbose -Message ($localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
