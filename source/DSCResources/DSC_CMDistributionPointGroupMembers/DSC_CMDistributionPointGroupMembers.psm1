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

    .PARAMETER DistributionPoint
        Specifies the Distribution Point to modify Distribution Point Group membership.
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
        $DistributionPoint
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $status = Get-CMDistributionPoint -SiteCode $SiteCode -SiteSystemServerName $DistributionPoint

    if ($status)
    {
        $dpg = Get-CMDistributionPointGroup
        if ($dpg)
        {
            $groups = @()
            foreach ($group in $dpg)
            {
                $groupname = Get-CMDistributionPoint -DistributionPointGroupName $group.Name
                $dp = $groupname | Where-Object -FilterScript {$_.NetworkOSPath -eq "\\$DistributionPoint"}
                if ($dp)
                {
                    $groups += $group.Name
                }
            }
        }

        $dpInstall = 'Present'
    }
    else
    {
        $dpInstall = 'Absent'
    }

    return @{
        SiteCode           = $SiteCode
        DistributionPoint  = $DistributionPoint
        DistributionGroups = $groups
        DPStatus           = $dpInstall
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER DistributionPoint
        Specifies the Distribution Point to modify Distribution Point Group membership.

    .PARAMETER DistrubtionGroups
        Specifies an array of Distribution Groups to match on the Distribution Point.

    .PARAMETER DistributionGroupsToInclude
        Specifies an array of Distribution Groups to add to the Distribution Point.

    .PARAMETER DistributionGroupsToExclude
        Specifies an array of Distribution Groups to remove from the Distribution Point.
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
        $DistributionPoint,

        [Parameter()]
        [String[]]
        $DistributionGroups,

        [Parameter()]
        [String[]]
        $DistributionGroupsToInclude,

        [Parameter()]
        [String[]]
        $DistributionGroupsToExclude
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode -DistributionPoint $DistributionPoint

        if ($state.DPStatus -eq 'Absent')
        {
            throw ($script:localizedData.DistroPointInstall -f $SiteServerName)
        }

        if (-not $PSBoundParameters.ContainsKey('DistributionGroups') -and
            $PSBoundParameters.ContainsKey('DistributionGroupsToInclude') -and
            $PSBoundParameters.ContainsKey('DistributionGroupsToExclude'))
        {
            foreach ($item in $DistributionGroupsToInclude)
            {
                if ($DistributionGroupsToExclude -contains $item)
                {
                    throw ($script:localizedData.ErrorBoth -f $item)
                }
            }
        }

        if ($DistributionGroups -or $DistributionGroupsToInclude -or $DistributionGroupsToExclude)
        {
            $distroArray = @{
                Match        = $DistributionGroups
                Include      = $DistributionGroupsToInclude
                Exclude      = $DistributionGroupsToExclude
                CurrentState = $state.DistributionGroups
            }

            $distroCompare = Compare-MultipleCompares @distroArray

            if ($distroCompare.Missing)
            {
                foreach ($add in $distroCompare.Missing)
                {
                    if (Get-CMDistributionPointGroup -Name $add)
                    {
                        $addParams = @{
                            DistributionPointName      = $DistributionPoint
                            DistributionPointGroupName = $add
                        }

                        Write-Verbose -Message ($script:localizedData.AddDistroGroup -f $add, $DistributionPoint)
                        Add-CMDistributionPointToGroup @addParams
                    }
                    else
                    {
                        [array]$errorMsg += $add
                    }
                }
            }

            if ($distroCompare.Remove)
            {
                foreach ($remove in $distroCompare.Remove)
                {
                    $removeParam = @{
                        DistributionPointName      = $DistributionPoint
                        DistributionPointGroupName = $remove
                    }

                    Write-Verbose -Message ($script:localizedData.RemoveDistroGroup -f $remove, $DistributionPoint)
                    Remove-CMDistributionPointFromGroup @removeParam
                }
            }
        }

        if ($errorMsg)
        {
            throw ($script:localizedData.ErrorGroup -f ($errorMsg | Out-String))
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

    .PARAMETER DistributionPoint
        Specifies the Distribution Point to modify Distribution Point Group membership.

    .PARAMETER DistrubtionGroups
        Specifies an array of Distribution Groups to match on the Distribution Point.

    .PARAMETER DistributionGroupsToInclude
        Specifies an array of Distribution Groups to add to the Distribution Point.

    .PARAMETER DistributionGroupsToExclude
        Specifies an array of Distribution Groups to remove from the Distribution Point.
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
        $DistributionPoint,

        [Parameter()]
        [String[]]
        $DistributionGroups,

        [Parameter()]
        [String[]]
        $DistributionGroupsToInclude,

        [Parameter()]
        [String[]]
        $DistributionGroupsToExclude
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -DistributionPoint $DistributionPoint
    $result = $true

    if ($state.DPStatus -eq 'Absent')
    {
        Write-Warning -Message ($script:localizedData.DistroPointInstall -f $DistributionPoint)
        $result = $false
    }
    else
    {
        if ($PSBoundParameters.ContainsKey('DistributionGroups'))
        {
            if ($PSBoundParameters.ContainsKey('DistributionGroupsToInclude') -or
                $PSBoundParameters.ContainsKey('DistributionGroupsToExclude'))
            {
                Write-Warning -Message $script:localizedData.ParamIgnore
            }
        }
        elseif ($PSBoundParameters.ContainsKey('DistributionGroupsToInclude') -and
                $PSBoundParameters.ContainsKey('DistributionGroupsToExclude'))
        {
            foreach ($item in $DistributionGroupsToInclude)
            {
                if ($DistributionGroupsToExclude -contains $item)
                {
                    Write-Warning -Message ($script:localizedData.ErrorBoth -f $item)
                    $result = $false
                }
            }
        }

        if ($DistributionGroups -or $DistributionGroupsToInclude -or $DistributionGroupsToExclude)
        {
            $distroArray = @{
                Match        = $DistributionGroups
                Include      = $DistributionGroupsToInclude
                Exclude      = $DistributionGroupsToExclude
                CurrentState = $state.DistributionGroups
            }

            $distroCompare = Compare-MultipleCompares @distroArray

            if ($distroCompare.Missing)
            {
                Write-Verbose -Message ($script:localizedData.GroupMissing -f $DistributionPoint, ($distroCompare.Missing | Out-String))
                $result = $false
            }

            if ($distroCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.GroupExclude -f $DistributionPoint, ($distroCompare.Remove | Out-String))
                $result = $false
            }
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}
