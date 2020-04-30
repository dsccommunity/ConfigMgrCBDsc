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

    .PARAMETER DisplayName
        Specifies the display name of the boundary.
        Not used in Get-TargetResource.

    .Parameter Type
        Specifies the type of boundary ADSite, IPSubnet, or IPRange.

    .Parameter Value
        Specifies the value for the boundary.
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
        $DisplayName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ADSite','IPSubnet','IPRange')]
        [String]
        $Type,

        [Parameter(Mandatory = $true)]
        [String]
        $Value
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    if ($Type -eq 'IPSubnet')
    {
        $cValue = Get-CMBoundary | Where-Object -FilterScript { $_.Value -eq $Value.Split('/')[0] }
    }
    else
    {
        $cValue = Get-CMBoundary | Where-Object -FilterScript { $_.Value -eq $Value }
    }

    if ($cValue)
    {
        $boundaryType = switch ($cvalue.BoundaryType)
        {
            '0' { 'IPSubnet' }
            '1' { 'ADSite' }
            '3' { 'IPRange' }
        }

        $state = 'Present'
    }
    else
    {
        $state = 'Absent'
    }

    return @{
        SiteCode    = $SiteCode
        DisplayName = $cValue.DisplayName
        Type        = $boundaryType
        Value       = $cValue.Value
        Ensure      = $state
        BoundaryId  = $cValue.BoundaryID
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER DisplayName
        Specifies the display name of the boundary.

    .Parameter Type
        Specifies the type of boundary ADSite, IPSubnet, or IPRange.

    .Parameter Value
        Specifies the value for the boundary.

    .Parameter Ensure
        Specifies if the boundary is to be absent or present.
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
        $DisplayName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ADSite','IPSubnet','IPRange')]
        [String]
        $Type,

        [Parameter(Mandatory = $true)]
        [String]
        $Value,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -DisplayName $DisplayName -Type $Type -Value $Value

    try
    {
        if ($Ensure -eq 'Present')
        {
            if ($null -eq $state.BoundaryId)
            {
                Write-Verbose -Message ($script:localizedData.CreateBoundary -f $DisplayName, $Type, $Value)
                New-CMBoundary -Type $Type -Name $DisplayName -Value $Value
            }
            else
            {
                if ($DisplayName -ne $state.DisplayName)
                {
                    Write-Verbose -Message ($script:localizedData.ChangeDisplayName -f $state.DisplayName, $DisplayName)
                    Set-CMBoundary -Id $state.BoundaryId -NewName $DisplayName
                }
            }
        }
        else
        {
            if ($state.BoundaryId)
            {
                Write-Verbose -Message ($script:localizedData.BoundaryRemove -f $DisplayName)
                Remove-CMBoundary -Id $state.BoundaryId
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

    .PARAMETER DisplayName
        Specifies the display name of the boundary.

    .Parameter Type
        Specifies the type of boundary ADSite, IPSubnet, or IPRange.

    .Parameter Value
        Specifies the value for the boundary.

    .Parameter Ensure
        Specifies if the boundary is to be absent or present.
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
        $DisplayName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ADSite','IPSubnet','IPRange')]
        [String]
        $Type,

        [Parameter(Mandatory = $true)]
        [String]
        $Value,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -DisplayName $DisplayName -Type $Type -Value $Value
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.MissingBoundary -f $DisplayName)
            $result = $false
        }
        else
        {
            if ($state.DisplayName -ne $DisplayName)
            {
                Write-Verbose -Message ($script:localizedData.DisplayName -f $DisplayName, $state.DisplayName)
                $result = $false
            }
        }
    }
    else
    {
        if ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveBoundary -f $DisplayName)
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
