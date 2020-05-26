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

    .PARAMETER SiteServerName
        Specifies the SiteServer to install the role on.

    .Notes
        This must be ran on the Primary servers to install the ManagementPoint role.
        The Primary server computer account must be in the local
        administrators group to perform the install.
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
        $SiteServerName
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $dpProps = Get-CMDistributionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode

    if ($dpProps)
    {
        [boolean]$pullDP = $dpProps.Props.Where({$_.PropertyName -eq 'IsPullDP'}).Value
        $sourceDp = $dpProps.PropLists.Where({$_.PropertyListName -eq 'SourceDistributionPoints'}).Values
        $sourceRank = $dpProps.PropLists.Where({$_.PropertyListName -eq 'SourceDPRanks'}).Values

        if ($sourceDp.Count -ge 1)
        {
            $sourceDistros = @()
            $processing = 0
            do
            {
                if ($sourceDP.Count -eq 1)
                {
                    $value = $sourceDp.Split('\\')[2]
                    $rank = [UInt32]$sourceRank
                }
                else
                {
                    $value = $sourceDp[$processing].Split('\\')[2]
                    $rank = [UInt32]$sourceRank[$processing]
                }

                $sourceDistros += (
                    @{
                        SourceDP = $value
                        DPRank   = $rank
                    }
                )

                $processing ++
            }
            until ($processing -eq $sourceDp.Count)
        }

        if ($sourceDistros)
        {
            $convertDP = @()
            foreach ($item in $sourceDistros)
            {
                $convertParams = @{
                    Hashtable = $item
                    ClassName = 'DSC_CMPullDistributionPointSourceDP'
                }

                $convertDP += ConvertTo-AnyCimInstance @convertParams
            }
        }

        $dpInstall = 'Present'
    }
    else
    {
        $dpInstall = 'Absent'
    }

    return @{
        SiteCode                = $SiteCode
        SiteServerName          = $SiteServerName
        EnablePullDP            = $pullDP
        SourceDistributionPoint = $convertDP
        DPStatus                = $dpInstall
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the SiteServer to install the role on.

    .PARAMETER EnablePullDP
        Specifies if EnablePullDP is to be set to enabled or disabled.

    .PARAMETER SourceDistributionPoint
        Specifies the desired source distribution points and the DP ranking.
        If enabling PullDP you must specify at least one Source DP.
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
        $SiteServerName,

        [Parameter()]
        [Boolean]
        $EnablePullDP,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SourceDistributionPoint
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SiteServerName $SiteServerName

    try
    {
        if ($state.DPStatus -eq 'Absent')
        {
            throw ($script:localizedData.DistroPointInstall -f $SiteServerName)
        }

        if (((($PSBoundParameters.EnablePullDP -eq $false) -or ([string]::IsNullOrEmpty($PSBoundParameters.EnablePullDP) -and
           $state.EnablePullDP -eq $false)) -and ($PSBoundParameters.SourceDistributionPoint)) -or
           ((($PSBoundParameters.EnablePullDP -eq $true) -and ($state.EnablePullDP -eq $false)) -and
           ([string]::IsNullOrEmpty($PSBoundParameters.SourceDistributionPoint))))
        {
            throw $script:localizedData.InvalidConfig
        }

        if (($EnablePullDP -eq $true) -and ([string]::IsNullOrEmpty($PSBoundParameters.SourceDistributionPoint)))
        {
            throw $script:localizedData.PullDPEnabledThrow
        }

        if (($PSBoundParameters.ContainsKey('EnablePullDP')) -and ($EnablePullDP -ne $state.EnablePullDP))
        {
            Write-Verbose -Message $script:localizedData.EnablePullDP
            $buildingParams += @{
                EnablePullDP = $EnablePullDP
            }
        }

        if ($SourceDistributionPoint)
        {
            if ($state.SourceDistributionPoint)
            {
                $comparesParam = @{
                    ReferenceObject  = $state.SourceDistributionPoint
                    DifferenceObject = $SourceDistributionPoint
                    Property         = 'SourceDP','DPRank'
                }

                $compares = Compare-Object @comparesParam

                if ($compares)
                {
                    Write-Verbose -Message $script:localizedData.SourceDPMismatch
                    $setSourceDP = $true
                }
            }
            else
            {
                $setSourceDP = $true
            }

            if ($setSourceDP)
            {
                $sourceDP = @()
                $sourceRank = @()
                foreach ($iteration in $SourceDistributionPoint)
                {
                    $sourceDP += $iteration.SourceDP
                    $sourceRank += $iteration.DPRank
                }

                $buildingParams += @{
                    SourceDistributionPoint = $sourceDP
                }

                $buildingParams += @{
                    SourceDPRank = $sourceRank
                }
            }
        }

        if ($buildingParams)
        {
            Set-CMDistributionPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode @buildingParams
        }
    }
    catch
    {
        throw $_
    }
    finally
    {
        Set-Location -Path $env:windir
    }
}

<#
    .SYNOPSIS
        This will test the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SiteServerName
        Specifies the SiteServer to install the role on.

    .PARAMETER EnablePullDP
        Specifies if EnablePullDP is to be set to enabled or disabled.

    .PARAMETER SourceDistributionPoint
        Specifies the desired source distribution points and the DP ranking.
        If enabling PullDP you must specify at least one Source DP.
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
        $SiteServerName,

        [Parameter()]
        [Boolean]
        $EnablePullDP,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SourceDistributionPoint
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SiteServerName $SiteServerName
    $result = $true

    if ($state.DPStatus -eq 'Absent')
    {
        Write-Verbose -Message ($script:localizedData.DistroPointInstall -f $SiteServerName)
        $result = $false
    }
    else
    {
        if ($PSBoundParameters.ContainsKey('EnablePullDP') -and $EnablePullDP -ne $state.EnablePullDP)
        {
            Write-Verbose -Message ($script:localizedData.TestEnablePull -f $state.EnablePullDP, $EnablePullDp)
            $result = $false
        }

        if ($SourceDistributionPoint)
        {
            if ($state.SourceDistributionPoint)
            {
                $comparesParam = @{
                    ReferenceObject  = $state.SourceDistributionPoint
                    DifferenceObject = $SourceDistributionPoint
                    Property         = 'SourceDP','DPRank'
                }

                $compares = Compare-Object @comparesParam -IncludeEqual

                foreach ($item in $compares)
                {
                    if ($item.SideIndicator -eq '==')
                    {
                        Write-Verbose -Message ($script:localizedData.SourceDPMatch -f $item.SourceDP, $item.DPRank)
                    }
                    elseif ($item.SideIndicator -eq '=>')
                    {
                        Write-Verbose -Message ($script:localizedData.SourceDPMissing -f $item.SourceDP, $item.DPRank)
                        $result = $false
                    }
                    elseif ($item.SideIndicator -eq '<=')
                    {
                        Write-Verbose -Message ($script:localizedData.SourceDPExtra -f $item.SourceDP, $item.DPRank)
                        $result = $false
                    }
                }
            }
            else
            {
                foreach ($item in $SourceDistributionPoint)
                {
                    Write-Verbose -Message ($script:localizedData.SourceDPMissing -f $item.SourceDP, $item.DPRank)
                    $result = $false
                }
            }
        }
    }

    Set-Location -Path $env:windir
    return $result
}

Export-ModuleMember -Function *-TargetResource
