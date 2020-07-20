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

    .PARAMETER DistributionGroup
        Specifies the Distribution Group name.
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
        $DistributionGroup
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $groupStatus = Get-CMDistributionPointGroup -Name $DistributionGroup

    if ($groupStatus)
    {
        $dplist = Get-CMDistributionPoint -DistributionPointGroupName $DistributionGroup
        $dpMembers = @()

        foreach ($dp in $dplist)
        {
            $dpMembers += $dp.NetworkOSPath.SubString(2)
        }

        $scopeObject = Get-CMObjectSecurityScope -InputObject $groupStatus

        foreach ($item in $scopeObject)
        {
            [array]$scopes += $item.CategoryName
        }

        $group = 'Present'
    }
    else
    {
        $group = 'Absent'
    }

    return @{
        SiteCode           = $SiteCode
        DistributionGroup  = $DistributionGroup
        DistributionPoints = $dpMembers
        SecurityScopes     = $scopes
        Ensure             = $group
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER DistributionGroup
        Specifies the Distribution Group name.

    .PARAMETER DistributionPoints
        Specifies an array of Distribution Points to match to the Distribution Group.

    .PARAMETER DistributionPointsToInclude
        Specifies an array of Distribution Points to add to the Distribution Group.

    .PARAMETER DistributionPointsToExclude
        Specifies an array of Distribution Points to remove from the Distribution Group.

    .PARAMETER SecurityScopes
        Specifies an array of Security Scopes to match to the Distribution Group.

    .PARAMETER SecurityScopesToInclude
        Specifies an array of Security Scopes to add to the Distribution Group.

    .PARAMETER SecurityScopesToExclude
        Specifies an array of Security Scopes to remove from the Distribution Group.

    .PARAMETER Ensure
        Specifies if the Distribution Group is to be present or absent.
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
        $DistributionGroup,

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
        [String[]]
        $SecurityScopes,

        [Parameter()]
        [String[]]
        $SecurityScopesToInclude,

        [Parameter()]
        [String[]]
        $SecurityScopesToExclude,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode -DistributionGroup $DistributionGroup

        if ($Ensure -eq 'Present')
        {
            if (-not $PSBoundParameters.ContainsKey('DistributionPoints') -and
                $PSBoundParameters.ContainsKey('DistributionPointsToInclude') -and
                $PSBoundParameters.ContainsKey('DistributionPointsToExclude'))
            {
                foreach ($item in $DistributionPointsToInclude)
                {
                    if ($DistributionPointsToExclude -contains $item)
                    {
                        throw ($script:localizedData.DistroInEx -f $item)
                    }
                }
            }

            if (-not $PSBoundParameters.ContainsKey('SecurityScopes') -and
                $PSBoundParameters.ContainsKey('SecurityScopesToInclude') -and
                $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
            {
                foreach ($item in $SecurityScopesToInclude)
                {
                    if ($SecurityScopesToExclude -contains $item)
                    {
                        throw ($script:localizedData.ScopeInEx -f $item)
                    }
                }
            }

            if ($state.Ensure -eq 'Absent')
            {
                Write-Verbose -Message ($script:localizedData.AddGroup -f $DistributionGroup)
                New-CMDistributionPointGroup -Name $DistributionGroup
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
                    $distro = 'Distribution Point'
                    foreach ($add in $distroCompare.Missing)
                    {
                        if (Get-CMDistributionPoint -Name $add)
                        {
                            $addParam = @{
                                DistributionPointName      = $add
                                DistributionPointGroupName = $DistributionGroup
                            }

                            Write-Verbose -Message ($script:localizedData.AddDistro -f $add, $DistributionGroup)
                            Add-CMDistributionPointToGroup @addParam
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.ErrorGroup -f $distro, $add)
                        }
                    }
                }

                if ($distroCompare.Remove)
                {
                    foreach ($remove in $distroCompare.Remove)
                    {
                        $removeParam = @{
                            DistributionPointName      = $remove
                            DistributionPointGroupName = $DistributionGroup
                        }

                        Write-Verbose -Message ($script:localizedData.RemoveDistro -f $remove, $DistributionGroup)
                        Remove-CMDistributionPointFromGroup @removeParam
                    }
                }
            }

            if ($SecurityScopes -or $SecurityScopesToInclude -or $SecurityScopesToExclude)
            {
                $dgObject = Get-CMDistributionPointGroup -Name $DistributionGroup

                $scopesArray = @{
                    Match        = $SecurityScopes
                    Include      = $SecurityScopesToInclude
                    Exclude      = $SecurityScopesToExclude
                    CurrentState = $state.SecurityScopes
                }

                $scopesCompare = Compare-MultipleCompares @scopesArray

                if ($scopesCompare.Missing)
                {
                    $scopeError = 'Security Scope'

                    foreach ($add in $scopesCompare.Missing)
                    {
                        if (Get-CMSecurityScope -Name $add)
                        {
                            Write-Verbose -Message ($script:localizedData.AddScope -f $add, $DistributionGroup)
                            Add-CMObjectSecurityScope -Name $add -InputObject $dgObject
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.ErrorGroup -f $scopeError, $add)
                        }
                    }
                }

                if ($scopesCompare.Remove)
                {
                    foreach ($remove in $scopesCompare.Remove)
                    {
                        Write-Verbose -Message ($script:localizedData.RemoveScope -f $remove, $DistributionGroup)
                        Remove-CMObjectSecurityScope -Name $remove -InputObject $dgObject
                    }
                }
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveGroup -f $DistributionGroup)
            Remove-CMDistributionPointGroup -Name $DistributionGroup -Force
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

    .PARAMETER DistributionGroup
        Specifies the Distribution Group name.

    .PARAMETER DistributionPoints
        Specifies an array of Distribution Points to match to the Distribution Group.

    .PARAMETER DistributionPointsToInclude
        Specifies an array of Distribution Points to add to the Distribution Group.

    .PARAMETER DistributionPointsToExclude
        Specifies an array of Distribution Points to remove from the Distribution Group.

    .PARAMETER SecurityScopes
        Specifies an array of Security Scopes to match to the Distribution Group.

    .PARAMETER SecurityScopesToInclude
        Specifies an array of Security Scopes to add to the Distribution Group.

    .PARAMETER SecurityScopesToExclude
        Specifies an array of Security Scopes to remove from the Distribution Group.

    .PARAMETER Ensure
        Specifies if the Distribution Group is to be present or absent.
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
        $DistributionGroup,

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
        [String[]]
        $SecurityScopes,

        [Parameter()]
        [String[]]
        $SecurityScopesToInclude,

        [Parameter()]
        [String[]]
        $SecurityScopesToExclude,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -DistributionGroup $DistributionGroup
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($PSBoundParameters.ContainsKey('DistributionPoints'))
        {
            if ($PSBoundParameters.ContainsKey('DistributionPointsToInclude') -or
                $PSBoundParameters.ContainsKey('DistributionPointsToExclude'))
            {
                Write-Warning -Message $script:localizedData.ParamIgnore
            }
        }
        elseif (-not $PSBoundParameters.ContainsKey('DistributionPoints') -and
            $PSBoundParameters.ContainsKey('DistributionPointsToInclude') -and
            $PSBoundParameters.ContainsKey('DistributionPointsToExclude'))
        {
            foreach ($item in $DistributionPointsToInclude)
            {
                if ($DistributionPointsToExclude -contains $item)
                {
                    Write-Warning -Message ($script:localizedData.DistroInEx -f $item)
                    $result = $false
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('SecurityScopes'))
        {
            if ($PSBoundParameters.ContainsKey('SecurityScopesToInclude') -or
                $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
            {
                Write-Warning -Message $script:localizedData.ParamIgnoreScopes
            }
        }
        elseif (-not $PSBoundParameters.ContainsKey('SecurityScopes') -and
            $PSBoundParameters.ContainsKey('SecurityScopesToInclude') -and
            $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
        {
            foreach ($item in $SecurityScopesToInclude)
            {
                if ($SecurityScopesToExclude -contains $item)
                {
                    Write-Warning -Message ($script:localizedData.DistroInEx -f $item)
                    $result = $false
                }
            }
        }

        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.GroupMissing -f $DistributionGroup)
            $result = $false
        }
        else
        {
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
                    Write-Verbose -Message ($script:localizedData.DistroMissing -f ($distroCompare.Missing | Out-String))
                    $result = $false
                }

                if ($distroCompare.Remove)
                {
                    Write-Verbose -Message ($script:localizedData.DistroRemove -f ($distroCompare.Remove | Out-String))
                    $result = $false
                }
            }

            if ($SecurityScopes -or $SecurityScopesToInclude -or $SecurityScopesToExclude)
            {
                $scopeArray = @{
                    Match        = $SecurityScopes
                    Include      = $SecurityScopesToInclude
                    Exclude      = $SecurityScopesToExclude
                    CurrentState = $state.SecurityScopes
                }

                $scopeCompare = Compare-MultipleCompares @scopeArray

                if ($scopeCompare.Missing)
                {
                    Write-Verbose -Message ($script:localizedData.ScopeMissing -f ($scopeCompare.Missing | Out-String))
                    $result = $false
                }

                if ($scopeCompare.Remove)
                {
                    Write-Verbose -Message ($script:localizedData.ScopeRemove -f ($scopeCompare.Remove | Out-String))
                    $result = $false
                }
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
