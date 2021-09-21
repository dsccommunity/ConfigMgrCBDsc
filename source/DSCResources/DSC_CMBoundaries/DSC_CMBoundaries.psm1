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
        Specifies the type of boundary ADSite, IPSubnet, IPRange, VPN, or IPv6Prefix.

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
        [ValidateSet('ADSite','IPSubnet','IPRange','VPN','IPv6Prefix')]
        [String]
        $Type,

        [Parameter(Mandatory = $true)]
        [String]
        $Value
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $convertBoundary = switch ($Type)
    {
        'IPSubnet'   { '0' }
        'AdSite'     { '1' }
        'IPv6Prefix' { '2' }
        'IPRange'    { '3' }
        'VPN'        { '4' }
    }

    if ($Type -eq 'IPSubnet')
    {
        $address = Convert-CidrToIP -IPAddress $Value.Split('/')[0] -Cidr $Value.Split('/')[1]
        $settingValue = $address.NetworkAddress
        $cValue = Get-CMBoundary | Where-Object -FilterScript { $_.Value -eq $address.NetworkAddress `
            -and $_.BoundaryType -eq $convertBoundary }
    }
    else
    {
        $cValue = Get-CMBoundary | Where-Object -FilterScript { $_.Value -eq $Value `
            -and $_.BoundaryType -eq $convertBoundary }
        $settingValue = $Value
    }

    if ($cValue)
    {
        $state = 'Present'
    }
    else
    {
        $state = 'Absent'
    }

    return @{
        SiteCode    = $SiteCode
        DisplayName = $cValue.DisplayName
        Type        = $Type
        Value       = $settingValue
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
        Specifies the type of boundary ADSite, IPSubnet, IPRange, VPN, or IPv6Prefix.

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
        [ValidateSet('ADSite','IPSubnet','IPRange','VPN','IPv6Prefix')]
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
            elseif ($DisplayName -ne $state.DisplayName)
            {
                Write-Verbose -Message ($script:localizedData.ChangeDisplayName -f $state.DisplayName, $DisplayName)
                Set-CMBoundary -Id $state.BoundaryId -NewName $DisplayName
            }
        }
        else
        {
            if ($state.BoundaryId)
            {
                Write-Verbose -Message ($script:localizedData.BoundaryRemove -f $Value)
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
        Specifies the type of boundary ADSite, IPSubnet, IPRange, VPN, or IPv6Prefix.

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
        [ValidateSet('ADSite','IPSubnet','IPRange','VPN','IPv6Prefix')]
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
            Write-Verbose -Message ($script:localizedData.MissingBoundary -f $Value)
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
            Write-Verbose -Message ($script:localizedData.RemoveBoundary -f $Value)
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
