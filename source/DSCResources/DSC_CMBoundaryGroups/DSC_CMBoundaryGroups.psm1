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

    $groupId = (Get-CMBoundaryGroup -Name $BoundaryGroup).GroupId

    if ($groupId)
    {
        $groupMembers = Get-CMBoundary -BoundaryGroupId $groupId

        if ($groupMembers)
        {
            $cimBoundaries = ConvertTo-CimBoundaries -InputObject $groupMembers
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode      = $SiteCode
        BoundaryGroup = $BoundaryGroup
        Boundaries    = $cimBoundaries
        Ensure        = $status
    }
}

<#
    .SYNOPSIS
        This will test the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER BoundaryGroup
        Specifies the boundary group name.

    .Parameter Boundaries
        Specifies an array of boundaries to add or remove.

    .Parameter BoundaryAction
        Specifies the boundaries are to match, add, or remove Boundaries from the boundary group.

    .Parameter Ensure
        Specifies if the boundary group is to be absent or present.
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

                    if ($errorMsg)
                    {
                        throw $errorMsg
                    }
                }
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.BoundaryGroupDelete -f $BoundaryGroup)
            Remove-CMBoundaryGroup -Name $BoundaryGroup
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
        Specifies the boundary group name.

    .Parameter Boundaries
        Specifies an array of boundaries to add or remove.

    .Parameter BoundaryAction
        Specifies the boundaries are to match, add, or remove Boundaries from the boundary group.

    .Parameter Ensure
        Specifies if the boundary group is to be absent or present.
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
