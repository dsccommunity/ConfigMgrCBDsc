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

    .PARAMETER Enabled
        Specifies the enablement of the forest discovery method. If settings is set to $false no other value provided will be
        evaluated for compliance.

        Not used in Get-TargetResource.
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
        [Boolean]
        $Enabled
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $forestDiscovery = (Get-CMDiscoveryMethod -Name ActiveDirectoryForestDiscovery -SiteCode $SiteCode).Props
    $enabledStatus   = (($forestDiscovery | Where-Object -FilterScript {$_.PropertyName -eq 'Settings'}).Value1 -eq 'Active')
    $forestSchedule  = ($forestDiscovery | Where-Object -FilterScript {$_.PropertyName -eq 'Startup Schedule'}).Value1
    $subnetboundary  = ($forestDiscovery | Where-Object -FilterScript {$_.PropertyName -eq 'Enable Subnet Boundary Creation'}).Value
    $siteboundary    = ($forestDiscovery | Where-Object -FilterScript {$_.PropertyName -eq 'Enable AD Site Boundary Creation'}).Value

    $convertCimParam = @{
        ScheduleString = $forestSchedule
        CimClassName   = 'DSC_CMForestDiscoveryPollingSchedule'
    }
    $syncSchedule = ConvertTo-CimCMScheduleString @convertCimParam

    return @{
        SiteCode                                  = $SiteCode
        Enabled                                   = $enabledStatus
        PollingSchedule                           = $syncSchedule
        EnableActiveDirectorySiteBoundaryCreation = $siteboundary
        EnableSubnetBoundaryCreation              = $subnetboundary
    }
}

 <#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER Enabled
        Specifies the enablement of the forest discovery method. If settings is set to $false no other value provided will be
        evaluated for compliance.

    .PARAMETER PollingSchedule
        Specifies a schedule and determines how often Configuration Manager attempts to discover Active Directory forest.

    .PARAMETER EnableActiveDirectorySiteBoundaryCreation
        Indicates whether Configuration Manager creates Active Directory boundaries from AD DS discovery information.

    .PARAMETER EnableSubnetBoundaryCreation
        Indicates whether Configuration Manager creates IP address range boundaries from AD DS discovery information.
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
        [Boolean]
        $Enabled,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $PollingSchedule,

        [Parameter()]
        [Boolean]
        $EnableActiveDirectorySiteBoundaryCreation,

        [Parameter()]
        [Boolean]
        $EnableSubnetBoundaryCreation
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode -Enabled $Enabled
        if ($Enabled -eq $true)
        {
            $exludelist = @('Verbose','PollingSchedule')
            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
                if ($exludelist -notcontains $param.key)
                {
                    if ($param.Value -ne $state[$param.key])
                    {
                        Write-Verbose -Message ($script:localizedData.SettingSettings -f $param.Key, $param.Value)
                        $buildingParams += @{
                            $param.Key = $param.Value
                        }
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($PollingSchedule))
            {
                $newSchedule = @{
                    RecurInterval = $PollingSchedule.RecurInterval
                    RecurCount    = $PollingSchedule.RecurCount
                }

                $desiredPollingSchedule = New-CMSchedule @newSchedule

                $currentSchedule = @{
                    RecurInterval = $state.PollingSchedule.RecurInterval
                    RecurCount    = $state.PollingSchedule.RecurCount
                }

                $stateSchedule = New-CMSchedule @currentSchedule

                $array = @('DayDuration','DaySpan','HourDuration','HourSpan','IsGMT','MinuteDuration','MinuteSpan')

                foreach ($item in $array)
                {
                    if ($desiredPollingSchedule.$($item) -ne $stateSchedule.$($item))
                    {
                        Write-Verbose -Message ($script:localizedData.ScheduleItem `
                            -f $item, $($desiredPollingSchedule.$($item)), $($stateSchedule.$($item)))
                        $setSchedule = $true
                    }
                }

                if ($setSchedule)
                {
                    $buildingParams += @{
                        PollingSchedule = $desiredPollingSchedule
                    }
                }
            }

            if ($buildingParams)
            {
                Set-CMDiscoveryMethod -ActiveDirectoryForestDiscovery -SiteCode $SiteCode @buildingParams
            }
        }
        else
        {
            if ($state.Enabled -eq $true)
            {
                Set-CMDiscoveryMethod -ActiveDirectoryForestDiscovery -SiteCode $SiteCode -Enabled $false
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

    .PARAMETER Enabled
        Specifies the enablement of the forest discovery method. If settings is set to $false no other value provided will be
        evaluated for compliance.

    .PARAMETER PollingSchedule
        Specifies a schedule and determines how often Configuration Manager attempts to discover Active Directory forest.

    .PARAMETER EnableActiveDirectorySiteBoundaryCreation
        Indicates whether Configuration Manager creates Active Directory boundaries from AD DS discovery information.

    .PARAMETER EnableSubnetBoundaryCreation
        Indicates whether Configuration Manager creates IP address range boundaries from AD DS discovery information.
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
        [Boolean]
        $Enabled,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $PollingSchedule,

        [Parameter()]
        [Boolean]
        $EnableActiveDirectorySiteBoundaryCreation,

        [Parameter()]
        [Boolean]
        $EnableSubnetBoundaryCreation
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -Enabled $Enabled
    $result = $true

    if ($Enabled -eq $true)
    {
        $exludelist = @('Verbose','PollingSchedule')
        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($exludelist -notcontains $param.key)
            {
                if ($param.Value -ne $state[$param.key])
                {
                    Write-Verbose -Message ($script:localizedData.TestSetting -f $param.Key, $param.Value, $state[$param.key])
                    $result = $false
                }
            }
        }

        if (-not [string]::IsNullOrEmpty($PollingSchedule))
        {
            $newSchedule = @{
                RecurInterval = $PollingSchedule.RecurInterval
                RecurCount    = $PollingSchedule.RecurCount
            }

            $desiredPollingSchedule = New-CMSchedule @newSchedule

            $currentSchedule = @{
                RecurInterval = $state.PollingSchedule.RecurInterval
                RecurCount    = $state.PollingSchedule.RecurCount
            }

            $stateSchedule = New-CMSchedule @currentSchedule

            $array = @('DayDuration','DaySpan','HourDuration','HourSpan','IsGMT','MinuteDuration','MinuteSpan')

            foreach ($item in $array)
            {
                if ($desiredPollingSchedule.$($item) -ne $stateSchedule.$($item))
                {
                    Write-Verbose -Message ($script:localizedData.ScheduleItem `
                        -f $item, $($desiredPollingSchedule.$($item)), $($stateSchedule.$($item)))
                    $result = $false
                }
            }
        }
    }
    else
    {
        if ($state.Enabled -eq $true)
        {
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
