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

    .PARAMETER BoundaryGroup
        Specifies the boundary group name.
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
        $BoundaryGroup
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $groupId = Get-CMBoundaryGroup -Name $BoundaryGroup

    if ($groupId)
    {
        $groupMembers = Get-CMBoundary -BoundaryGroupId $groupId.GroupId

        if ($groupMembers)
        {
            $cimBoundaries = ConvertTo-CimBoundaries -InputObject $groupMembers
        }

        $serverPath = (Get-CMBoundaryGroupSiteSystem -ID $groupId.GroupId).ServerNalPath

        if ($serverPath)
        {
            foreach ($item in $serverPath)
            {
                [array]$mappings += $item.TrimEnd('\').Split('\')[-1]
            }
        }

        $scopeObject = Get-CMObjectSecurityScope -InputObject $groupId

        foreach ($item in $scopeObject)
        {
            [array]$scopes += $item.CategoryName
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode       = $SiteCode
        BoundaryGroup  = $BoundaryGroup
        Boundaries     = $cimBoundaries
        SiteSystems    = $mappings
        SecurityScopes = $scopes
        Ensure         = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER BoundaryGroup
        Specifies the Boundary Group name.

    .Parameter Boundaries
        Specifies an array of Boundaries to add or remove.

    .Parameter BoundaryAction
        Specifies the Boundaries are to match, add, or remove Boundaries from the Boundary Group.

    .Parameter SiteSystems
        Specifies an array of SiteSystems to match on the Boundary Group.

    .Parameter SiteSystemsToInclude
        Specifies an array of SiteSystems to add to the Boundary Group.

    .Parameter SiteSystemsToExclude
        Specifies an array of SiteSystems to remove from the Boundary Group.

    .PARAMETER SecurityScopes
        Specifies an array of Security Scopes to match to the Boundary Group.

    .PARAMETER SecurityScopesToInclude
        Specifies an array of Security Scopes to add to the Boundary Group.

    .PARAMETER SecurityScopesToExclude
        Specifies an array of Security Scopes to remove from the Boundary Group.

    .Parameter Ensure
        Specifies if the Boundary Group is to be absent or present.
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
        $BoundaryGroup,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Boundaries,

        [Parameter()]
        [ValidateSet('Match','Add','Remove')]
        [String]
        $BoundaryAction = 'Add',

        [Parameter()]
        [String[]]
        $SiteSystems,

        [Parameter()]
        [String[]]
        $SiteSystemsToInclude,

        [Parameter()]
        [String[]]
        $SiteSystemsToExclude,

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
        $state = Get-TargetResource -SiteCode $SiteCode -BoundaryGroup $BoundaryGroup

        if ($Ensure -eq 'Present')
        {
            if (-not $PSBoundParameters.ContainsKey('SiteSystems') -and
                $PSBoundParameters.ContainsKey('SiteSystemsToInclude') -and
                $PSBoundParameters.ContainsKey('SiteSystemsToExclude'))
            {
                foreach ($item in $SiteSystemsToInclude)
                {
                    if ($SiteSystemsToExclude -contains $item)
                    {
                        throw ($script:localizedData.SiteInEx -f $item)
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

            if (-not $PSBoundParameters.ContainsKey('SecurityScopes') -and
                -not $PSBoundParameters.ContainsKey('SecurityScopesToInclude') -and
                $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
            {
                if ($state.SecurityScopes.Count -eq $SecurityScopesToExclude.Count)
                {
                    $excludeAll = Compare-Object -ReferenceObject $state.SecurityScopes -DifferenceObject $SecurityScopesToExclude
                    if ([string]::IsNullOrEmpty($excludeAll))
                    {
                        throw ($script:localizedData.ScopeExcludeAll)
                    }
                }
            }

            if ($state.Ensure -eq 'Absent')
            {
                Write-Verbose -Message ($script:localizedData.CreateBoundaryGroup -f $BoundaryGroup)
                New-CMBoundaryGroup -Name $BoundaryGroup
            }

            if ($Boundaries)
            {
                $convert = Convert-BoundariesIPSubnets -InputObject $Boundaries
                $boundaryToGroup = @()
                $boundaryToRemove = @()

                if ([string]::IsNullOrEmpty($state.Boundaries))
                {
                    if ($BoundaryAction -ne 'Remove')
                    {
                        foreach ($entry in $convert)
                        {
                            $boundaryToGroup += @{
                                Value = $entry.Value
                                Type  = $entry.Type
                            }
                        }
                    }
                }
                else
                {
                    $comparesParam = @{
                        ReferenceObject  = $state.Boundaries
                        DifferenceObject = $convert
                        Property         = 'Value','Type'
                    }

                    $compares = Compare-Object @comparesParam -IncludeEqual

                    if ($BoundaryAction -ne 'Remove')
                    {
                        foreach ($addCompare in $compares)
                        {
                            if ($addCompare.SideIndicator -eq '=>')
                            {
                                $boundaryToGroup += @{
                                    Value = $addCompare.Value
                                    Type  = $addCompare.Type
                                }
                            }
                        }
                    }

                    if ($BoundaryAction -ne 'Add')
                    {
                        foreach ($removeCompare in $compares)
                        {
                            if ($BoundaryAction -eq 'Match')
                            {
                                if ($removeCompare.SideIndicator -eq '<=')
                                {
                                    $boundaryToRemove += @{
                                        Value = $removeCompare.Value
                                        Type  = $removeCompare.Type
                                    }
                                }
                            }
                            else
                            {
                                if ($removeCompare.SideIndicator -eq '==')
                                {
                                    $boundaryToRemove += @{
                                        Value = $removeCompare.Value
                                        Type  = $removeCompare.Type
                                    }
                                }
                            }
                        }

                        if ($boundaryToRemove)
                        {
                            foreach ($item in $boundaryToRemove)
                            {
                                $removeBoundary = Get-BoundaryInfo -Value $item.Value -Type $item.Type

                                if ($removeBoundary)
                                {
                                    Write-Verbose -Message ($script:localizedData.ExcludingBoundary `
                                        -f $BoundaryGroup, $item.Type, $item.Value)

                                    Remove-CMBoundaryFromGroup -BoundaryId $removeBoundary -BoundaryGroupName $BoundaryGroup
                                }
                            }
                        }
                    }
                }

                if ($boundaryToGroup)
                {
                    foreach ($item in $boundaryToGroup)
                    {
                        $addBoundary = Get-BoundaryInfo -Value $item.Value -Type $item.Type

                        if ($addBoundary)
                        {
                            Write-Verbose -Message ($script:localizedData.AddingBoundary -f `
                                $BoundaryGroup, $item.Type, $item.Value)
                            Add-CMBoundaryToGroup -BoundaryId $addBoundary -BoundaryGroupName $BoundaryGroup
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.BoundaryAbsent -f $item.Type, $item.Value)
                        }
                    }
                }
            }

            if ($SiteSystems -or $SiteSystemsToInclude -or $SiteSystemsToExclude)
            {
                $systemsArray = @{
                    Match        = $SiteSystems
                    Include      = $SiteSystemsToInclude
                    Exclude      = $SiteSystemsToExclude
                    CurrentState = $state.SiteSystems
                }

                $systemsCompare = Compare-MultipleCompares @systemsArray

                if ($systemsCompare.Missing)
                {
                    foreach ($add in $systemsCompare.Missing)
                    {
                        if (Get-CMSiteSystemServer -SiteSystemServerName $add -SiteCode $siteCode)
                        {
                            [array]$addSystems += $add
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.SiteSystemMissing -f $add)
                        }
                    }

                    if ($addSystems)
                    {
                        Write-Verbose -Message ($script:localizedData.SystemMissing -f ($addSystems | Out-String))
                        Set-CMBoundaryGroup -Name $BoundaryGroup -AddSiteSystemServerName $addSystems
                    }
                }

                if ($systemsCompare.Remove)
                {
                    Write-Verbose -Message ($script:localizedData.SystemRemove -f ($systemsCompare.Remove | Out-String))
                    Set-CMBoundaryGroup -Name $BoundaryGroup  -RemoveSiteSystemServerName $systemsCompare.Remove
                }
            }

            if ($SecurityScopes -or $SecurityScopesToInclude -or $SecurityScopesToExclude)
            {
                $bgObject = Get-CMBoundaryGroup -Name $BoundaryGroup

                $scopesArray = @{
                    Match        = $SecurityScopes
                    Include      = $SecurityScopesToInclude
                    Exclude      = $SecurityScopesToExclude
                    CurrentState = $state.SecurityScopes
                }

                $scopesCompare = Compare-MultipleCompares @scopesArray

                if ($scopesCompare.Missing)
                {
                    foreach ($add in $scopesCompare.Missing)
                    {
                        if (Get-CMSecurityScope -Name $add)
                        {
                            Write-Verbose -Message ($script:localizedData.AddScope -f $add, $BoundaryGroup)
                            Add-CMObjectSecurityScope -Name $add -InputObject $bgObject
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.SecurityScopeMissing -f $add)
                        }
                    }
                }

                if ($scopesCompare.Remove)
                {
                    foreach ($remove in $scopesCompare.Remove)
                    {
                        Write-Verbose -Message ($script:localizedData.RemoveScope -f $remove, $BoundaryGroup)
                        Remove-CMObjectSecurityScope -Name $remove -InputObject $bgObject
                    }
                }
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.BoundaryGroupDelete -f $BoundaryGroup)
            Remove-CMBoundaryGroup -Name $BoundaryGroup
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
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER BoundaryGroup
        Specifies the Boundary Group name.

    .Parameter Boundaries
        Specifies an array of Boundaries to add or remove.

    .Parameter BoundaryAction
        Specifies the Boundaries are to match, add, or remove Boundaries from the Boundary Group.

    .Parameter SiteSystems
        Specifies an array of SiteSystems to match on the Boundary Group.

    .Parameter SiteSystemsToInclude
        Specifies an array of SiteSystems to add to the Boundary Group.

    .Parameter SiteSystemsToExclude
        Specifies an array of SiteSystems to remove from the Boundary Group.

    .PARAMETER SecurityScopes
        Specifies an array of Security Scopes to match to the Boundary Group.

    .PARAMETER SecurityScopesToInclude
        Specifies an array of Security Scopes to add to the Boundary Group.

    .PARAMETER SecurityScopesToExclude
        Specifies an array of Security Scopes to remove from the Boundary Group.

    .Parameter Ensure
        Specifies if the Boundary Group is to be absent or present.
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
        $BoundaryGroup,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Boundaries,

        [Parameter()]
        [ValidateSet('Match','Add','Remove')]
        [String]
        $BoundaryAction = 'Add',

        [Parameter()]
        [String[]]
        $SiteSystems,

        [Parameter()]
        [String[]]
        $SiteSystemsToInclude,

        [Parameter()]
        [String[]]
        $SiteSystemsToExclude,

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
    $state = Get-TargetResource -SiteCode $SiteCode -BoundaryGroup $BoundaryGroup
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($PSBoundParameters.ContainsKey('SiteSystems'))
        {
            if ($PSBoundParameters.ContainsKey('SiteSystemsToInclude') -or
                $PSBoundParameters.ContainsKey('SiteSystemsToExclude'))
            {
                Write-Warning -Message $script:localizedData.ParamIgnore
            }
        }
        elseif (-not $PSBoundParameters.ContainsKey('SiteSystems') -and
            $PSBoundParameters.ContainsKey('SiteSystemsToInclude') -and
            $PSBoundParameters.ContainsKey('SiteSystemsToExclude'))
        {
            foreach ($item in $SiteSystemsToInclude)
            {
                if ($SiteSystemsToExclude -contains $item)
                {
                    Write-Warning -Message ($script:localizedData.SiteInEx -f $item)
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
                    Write-Warning -Message ($script:localizedData.ScopeInEx -f $item)
                    $result = $false
                }
            }
        }

        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.BoundaryGroupMissing -f $BoundaryGroup)
            $result = $false
        }
        else
        {
            if ($Boundaries)
            {
                $convert = Convert-BoundariesIPSubnets -InputObject $Boundaries

                if ([string]::IsNullOrEmpty($state.Boundaries))
                {
                    if ($BoundaryAction -ne 'Remove')
                    {
                        foreach ($toAdd in $convert)
                        {
                            Write-Verbose -Message ($script:localizedData.MissingBoundary `
                                -f $BoundaryGroup, $toAdd.Type, $toAdd.Value)
                            $result = $false
                        }
                    }
                }
                else
                {
                    $comparesParam = @{
                        ReferenceObject  = $state.Boundaries
                        DifferenceObject = $convert
                        Property         = 'Value','Type'
                    }

                    $compares = Compare-Object @comparesParam -IncludeEqual

                    if ($BoundaryAction -ne 'Remove')
                    {
                        foreach ($addCompare in $compares)
                        {
                            if ($addCompare.SideIndicator -eq '=>')
                            {
                                Write-Verbose -Message ($script:localizedData.MissingBoundary `
                                    -f $BoundaryGroup, $addCompare.Type, $addCompare.Value)
                                $result = $false
                            }
                        }
                    }

                    if ($BoundaryAction -ne 'Add')
                    {
                        foreach ($removeCompare in $compares)
                        {
                            if ($BoundaryAction -eq 'Match')
                            {
                                if ($removeCompare.SideIndicator -eq '<=')
                                {
                                    Write-Verbose -Message ($script:localizedData.ExtraBoundary `
                                        -f $BoundaryGroup, $removeCompare.Type, $removeCompare.Value)
                                    $result = $false
                                }
                            }
                            else
                            {
                                if ($removeCompare.SideIndicator -eq '==')
                                {
                                    Write-Verbose -Message ($script:localizedData.ExtraBoundary `
                                        -f $BoundaryGroup, $removeCompare.Type, $removeCompare.Value)
                                    $result = $false
                                }
                            }
                        }
                    }
                }
            }

            if ($SiteSystems -or $SiteSystemsToInclude -or $SiteSystemsToExclude)
            {
                $systemsArray = @{
                    Match        = $SiteSystems
                    Include      = $SiteSystemsToInclude
                    Exclude      = $SiteSystemsToExclude
                    CurrentState = $state.SiteSystems
                }

                $systemsCompare = Compare-MultipleCompares @systemsArray

                if ($systemsCompare.Missing)
                {
                    Write-Verbose -Message ($script:localizedData.SystemMissing -f ($systemsCompare.Missing | Out-String))
                    $result = $false
                }

                if ($systemsCompare.Remove)
                {
                    Write-Verbose -Message ($script:localizedData.SystemRemove -f ($systemsCompare.Remove | Out-String))
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
        Write-Verbose -Message ($script:localizedData.BoundaryGroupRemove -f $BoundaryGroup)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
