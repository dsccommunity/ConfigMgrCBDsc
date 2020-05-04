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
        [array]$groupMembers = (Get-CMBoundary -BoundaryGroupId $groupId).DisplayName
        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode      = $SiteCode
        BoundaryGroup = $BoundaryGroup
        Boundaries    = $groupMembers
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
        Specifies an array of boundaries that must be identical in the boundary group.

    .Parameter BoundariesToInclude
        Specifies an array of boundaries to append to the boundary group.
        If boundaries are specified this setting is ignored.

    .Parameter BoundariesToExclude
        Specifies an array of boundaries must be absent from the boundary group.
        If boundaries are specified this setting is ignored.

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
        [String[]]
        $Boundaries,

        [Parameter()]
        [String[]]
        $BoundariesToInclude,

        [Parameter()]
        [String[]]
        $BoundariesToExclude,

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

            if (($Boundaries) -or ($BoundariesToInclude))
            {
                if ($Boundaries)
                {
                    $includes = $Boundaries
                }
                else
                {
                    $includes = $BoundariesToInclude
                }

                foreach ($member in $includes)
                {
                    if (Get-CMBoundary -BoundaryName $member)
                    {
                        if ($state.Boundaries -notcontains $member)
                        {
                            Write-Verbose -Message ($script:localizedData.AddingBoundary -f $BoundaryGroup, $member)
                            Add-CMBoundaryToGroup -BoundaryName $member -BoundaryGroupName $BoundaryGroup
                        }
                    }
                    else
                    {
                        $errorMsg += ($script:localizedData.BoundaryAbsent -f $member)
                        Write-Verbose -Message ($script:localizedData.BoundaryAbsent -f $member)
                    }
                }
            }

            if (($Boundaries) -or ($BoundariesToExclude))
            {
                if (-not [string]::IsNullOrEmpty($state.Boundaries))
                {
                    if ($Boundaries)
                    {
                        $excludes = $Boundaries
                    }
                    else
                    {
                        $excludes = $BoundariesToExclude
                    }

                    $compares = Compare-Object -ReferenceObject $state.Boundaries -DifferenceObject $excludes -IncludeEqual

                    foreach ($compare in $compares)
                    {
                        if ($Boundaries)
                        {
                            if ($compare.SideIndicator -eq '<=')
                            {
                                Write-Verbose -Message ($script:localizedData.ExcludingBoundary `
                                    -f $BoundaryGroup, $compare.InputObject)
                                Remove-CMBoundaryFromGroup -BoundaryName $compare.InputObject -BoundaryGroupName $BoundaryGroup
                            }
                        }
                        else
                        {
                            if ($compare.SideIndicator -eq '==')
                            {
                                Write-Verbose -Message ($script:localizedData.ExcludingBoundary `
                                    -f $BoundaryGroup, $compare.InputObject)
                                Remove-CMBoundaryFromGroup -BoundaryName $compare.InputObject -BoundaryGroupName $BoundaryGroup
                            }
                        }
                    }
                }
            }

            if ($errorMsg)
            {
                throw $errorMsg
            }
        }
        else
        {
            if ($state.Ensure -eq 'Present')
            {
                Write-Verbose -Message ($script:localizedData.BoundaryGroupDelete -f $BoundaryGroup)
                Remove-CMBoundaryGroup -Name $BoundaryGroup
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
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER BoundaryGroup
        Specifies the boundary group name.

    .Parameter Boundaries
        Specifies an array of boundaries that must be identical in the boundary group.

    .Parameter BoundariesToInclude
        Specifies an array of boundaries to append to the boundary group.
        If boundaries are specified this setting is ignored.

    .Parameter BoundariesToExclude
        Specifies an array of boundaries must be absent from the boundary group.
        If boundaries are specified this setting is ignored.

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
        [String[]]
        $Boundaries,

        [Parameter()]
        [String[]]
        $BoundariesToInclude,

        [Parameter()]
        [String[]]
        $BoundariesToExclude,

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
            if (($Boundaries) -or ($BoundariesToInclude))
            {
                if ($Boundaries)
                {
                    $includes = $Boundaries
                }
                else
                {
                    $includes = $BoundariesToInclude
                }

                foreach ($member in $includes)
                {
                    if ($state.Boundaries -notcontains $member)
                    {
                        Write-Verbose -Message ($script:localizedData.MissingBoundary -f $BoundaryGroup, $member)
                        $result = $false
                    }
                }
            }

            if (($Boundaries) -or ($BoundariesToExclude))
            {
                if (-not [string]::IsNullOrEmpty($state.Boundaries))
                {
                    if ($boundaries)
                    {
                        $excludes = $Boundaries
                    }
                    else
                    {
                        $excludes = $BoundariesToExclude
                    }

                    $compares = Compare-Object -ReferenceObject $state.Boundaries -DifferenceObject $excludes -IncludeEqual
                    foreach ($compare in $compares)
                    {
                        if ($Boundaries)
                        {
                            if ($compare.SideIndicator -eq '<=')
                            {
                               Write-Verbose -Message ($script:localizedData.ExtraBoundary `
                                    -f $BoundaryGroup, $compare.InputObject)
                                $result = $false
                            }
                        }
                        else
                        {
                            if ($compare.SideIndicator -eq '==')
                            {
                                Write-Verbose -Message ($script:localizedData.ExtraBoundary `
                                    -f $BoundaryGroup, $compare.InputObject)
                                $result = $false
                            }
                        }
                    }
                }
            }
        }
    }
    else
    {
        if ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.BoundaryGroupRemove -f $BoundaryGroup)
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
