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

    .PARAMETER DistributionPointGroup
        Specifies the Distribution Point Group name.
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
        $DistributionPointGroup
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $groupStatus = Get-CMDistributionPointGroup -Name $DistributionPointGroup

    if ($groupStatus)
    {
        $dplist = Get-CMDistributionPoint -DistributionPointGroupName $DistributionPointGroup
        $dpMembers = @()

        foreach ($dp in $dplist)
        {
            $dpMembers += $dp.NetworkOSPath.SubString(2)
        }

        $group = 'Present'
    }
    else
    {
        $group = 'Absent'
    }

    return @{
        SiteCode               = $SiteCode
        DistributionPointGroup = $DistributionPointGroup
        DistributionPoints     = $dpMembers
        Ensure                 = $group
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER DistributionPointGroup
        Specifies the Distribution Point Group name.

    .PARAMETER DistributionPoints
        Specifies an array of distribution points to match to the distribution point group.

    .PARAMETER DistributionPointsToInclude
        Specifies an array of distribution points to add to the distribution point group.

    .PARAMETER DistributionPointsToExclude
        Specifies an array of distribution points to remove from the distribution point group.

    .PARAMETER Ensure
        Specifies if the Distribution Point Group is to be present or absent.
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
        $DistributionPointGroup,

        [Parameter()]
        [String[]]
        $DistributionPoints,

        [Parameter()]
        [String[]]
        $DistributionPointsToInclude,

        [Parameter()]
        [String[]]
        $DistributionPointsToExclude,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode -DistributionPointGroup $DistributionPointGroup

        if ($Ensure -eq 'Present')
        {
            if ($state.Ensure -eq 'Absent')
            {
                Write-Verbose -Message ($script:localizedData.AddGroup -f $DistributionPointGroup)
                New-CMDistributionPointGroup -Name $DistributionPointGroup
            }

            if ($DistributionPoints -or $DistributionPointsToInclude -or $DistributionPointsToExclude)
            {
                $distroArray = @{
                    Match        = $DistributionPoints
                    Include      = $DistributionPointsToInclude
                    Exclude      = $DistributionPointsToExclude
                    CurrentState = $state.DistributionPoints
                }

                $distroCompare = Compare-MultipleCompares @distroArray

                if ($distroCompare.Missing)
                {
                    foreach ($add in $distroCompare.Missing)
                    {
                        if (Get-CMDistributionPoint -Name $add)
                        {
                            $addParam = @{
                                DistributionPointName      = $add
                                DistributionPointGroupName = $DistributionPointGroup
                            }

                            Write-Verbose -Message ($script:localizedData.AddDistro -f $add, $DistributionPointGroup)
                            Add-CMDistributionPointToGroup @addParam -Force
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.ErrorGroup -f $add)
                        }
                    }
                }

                if ($distroCompare.Remove)
                {
                    foreach ($remove in $distroCompare.Remove)
                    {
                        $removeParam = @{
                            DistributionPointName      = $remove
                            DistributionPointGroupName = $DistributionPointGroup
                        }

                        Write-Verbose -Message ($script:localizedData.RemoveDistro -f $remove, $DistributionPointGroup)
                        Remove-CMDistributionPointFromGroup @removeParam -Force
                    }
                }
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveGroup -f $DistributionPointGroup)
            Remove-CMDistributionPointGroup -Name $DistributionPointGroup -Force
        }

        if ($errorMsg)
        {
            throw $errorMsg
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

    .PARAMETER DistributionPointGroup
        Specifies the Distribution Point Group name.

    .PARAMETER DistributionPoints
        Specifies an array of distribution points to match to the distribution point group.

    .PARAMETER DistributionPointsToInclude
        Specifies an array of distribution points to add to the distribution point group.

    .PARAMETER DistributionPointsToExclude
        Specifies an array of distribution points to remove from the distribution point group.

    .PARAMETER Ensure
        Specifies if the Distribution Point Group is to be present or absent.
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
        $DistributionPointGroup,

        [Parameter()]
        [String[]]
        $DistributionPoints,

        [Parameter()]
        [String[]]
        $DistributionPointsToInclude,

        [Parameter()]
        [String[]]
        $DistributionPointsToExclude,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -DistributionPointGroup $DistributionPointGroup
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.GroupMissing -f $DistributionPointGroup)
            $result = $false
        }
        elseif ($DistributionPoints -or $DistributionPointsToInclude -or $DistributionPointsToExclude)
        {
            if ($PSBoundParameters.ContainsKey('DistributionPoints'))
            {
                if ($PSBoundParameters.ContainsKey('DistributionPointsToInclude') -or
                    $PSBoundParameters.ContainsKey('DistributionPointsToExclude'))
                {
                    Write-Warning -Message $script:localizedData.ParamIgnore
                }
            }

            $distroArray = @{
                Match        = $DistributionPoints
                Include      = $DistributionPointsToInclude
                Exclude      = $DistributionPointsToExclude
                CurrentState = $state.DistributionPoints
            }

            $distroCompare = Compare-MultipleCompares @distroArray

            if ($distroCompare.Missing)
            {
                Write-Verbose -Message ($script:localizedData.DistroMissing -f ($distroCompare.Missing | Out-String))
                $result = $false
            }

            if ($distroCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.DistroRemove -f ($distroCompare.Remove | Out-String))
                $result = $false
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message $script:localizedData.DistroGroupPresent
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
