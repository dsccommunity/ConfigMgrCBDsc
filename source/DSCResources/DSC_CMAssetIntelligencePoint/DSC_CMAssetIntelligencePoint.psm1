$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

 <#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site that manages the system role for the asset intelligence point.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.

    .Notes
        This role must only be installed on top-level site of the hierarchy.

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

    $apProps      = Get-CMAssetIntelligenceProxy

    if ($apProps)
    {
        $cert         = $apProps.ProxyCertPath
        $apEnabled    = $apProps.ProxyEnabled
        $syncEnabled  = $apProps.PeriodicCatalogUpdateEnabled
        $syncSchedule = $apProps.PeriodicCatalogUpdateSchedule
        $status       = 'Present'

        $convertCimParam = @{
            ScheduleString = $syncSchedule
            CimClassName   = 'DSC_CMAssetIntelligenceSynchronizationSchedule'
        }
        $sSchedule = ConvertTo-CimCMScheduleString @convertCimParam
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteServerName        = $SiteServerName
        SiteCode              = $SiteCode
        CertificateFile       = $cert
        Enable                = $apEnabled
        EnableSynchronization = $syncEnabled
        Schedule              = $sSchedule
        Ensure                = $status
    }
}

 <#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site that manages the system role for the asset intelligence point.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.

    .PARAMETER CertificateFile
        Specifies the path to a System Center Online authentication certificate (.pfx) file.
        If used, this must be in UNC format. Local paths are not allowed.

    .PARAMETER Schedule
        Specifies when the asset intelligence catalog is synchronized.

    .PARAMETER Enable
        Specifies whether the installed asset intelligence role is enabled or disabled.

    .PARAMETER EnableSynchronization
        Specifies whether to synchronize the asset intelligence catalog.

    .PARAMETER Ensure
        Specifies whether the asset intelligence synchronization point is present or absent.

    .Notes
        This role must only be installed on top-level site of the hierarchy.
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
        [String]
        $CertificateFile,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $Schedule,

        [Parameter()]
        [Boolean]
        $Enable,

        [Parameter()]
        [Boolean]
        $EnableSynchronization,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SiteServerName $SiteServerName

    try
    {
        if (($Schedule) -and ($EnableSynchronization -eq $false))
        {
            throw $script:localizedData.ScheduleNoSync
        }

        if ($Ensure -eq 'Present')
        {
            if ($state.Ensure -eq 'Absent')
            {
                if ($null -eq (Get-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName))
                {
                    Write-Verbose -Message ($script:localizedData.SiteServerRole -f $SiteServerName)
                    New-CMSiteSystemServer -SiteCode $SiteCode -SiteSystemServerName $SiteServerName
                }

                Write-Verbose -Message ($script:localizedData.AddAPRole -f $SiteServerName)
                Add-CMAssetIntelligenceSynchronizationPoint -SiteSystemServerName $SiteServerName
            }

            $evalList = @('CertificateFile','Enable','EnableSynchronization')

            foreach ($param in $PSBoundParameters.GetEnumerator())
            {
            if ($evalList -contains $param.key)
                {
                    if ($param.Value -ne $state[$param.key])
                    {
                        Write-Verbose -Message ($script:localizedData.SettingValue -f $param.Key, $param.Value)
                        $buildingParams += @{
                            $param.Key = $param.Value
                        }
                    }
                }
            }

            if (([string]::IsNullOrEmpty($CertificateFile)) -and (-not [string]::IsNullOrEmpty(($state.CertificateFile))))
            {
                Write-Verbose -Message ($script:localizedData.RemoveCert -f $SiteServerName)
                $buildingParams += @{
                    CertificateFile = ''
                }
            }

            if (-not [string]::IsNullOrEmpty($Schedule))
            {
                $newSchedule = @{
                    RecurInterval = $Schedule.RecurInterval
                    RecurCount    = $Schedule.RecurCount
                }

                $desiredSchedule = New-CMSchedule @newSchedule

                $currentSchedule = @{
                    RecurInterval = $state.Schedule.RecurInterval
                    RecurCount    = $state.Schedule.RecurCount
                }

                $stateSchedule = New-CMSchedule @currentSchedule

                $array = @('DayDuration','DaySpan','HourDuration','HourSpan','IsGMT')

                foreach ($item in $array)
                {
                    if ($desiredSchedule.$($item) -ne $stateSchedule.$($item))
                    {
                        Write-Verbose -Message ($script:localizedData.ScheduleItem `
                            -f $item, $($desiredSchedule.$($item)), $($stateSchedule.$($item)))
                        $setSchedule = $true
                    }
                }

                if ($setSchedule)
                {
                    $buildingParams += @{
                        Schedule = $desiredPollingSchedule
                    }
                }
            }

            if ($buildingParams)
            {
                Set-CMAssetIntelligenceSynchronizationPoint @buildingParams
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveAPRole -f $SiteServerName)
            Remove-CMAssetIntelligenceSynchronizationPoint -SiteSystemServerName $SiteServerName -SiteCode $SiteCode
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
        Specifies a site code for the Configuration Manager site that manages the system role for the asset intelligence point.

    .PARAMETER SiteServerName
        Specifies the Site Server to install or configure the role on.

    .PARAMETER CertificateFile
        Specifies the path to a System Center Online authentication certificate (.pfx) file.
        If used, this must be in UNC format. Local paths are not allowed.

    .PARAMETER Schedule
        Specifies when the asset intelligence catalog is synchronized.

    .PARAMETER Enable
        Specifies whether the installed asset intelligence role is enabled or disabled.

    .PARAMETER EnableSynchronization
        Specifies whether to synchronize the asset intelligence catalog.

    .PARAMETER Ensure
        Specifies whether the asset intelligence synchronization point is present or absent.

    .Notes
        This role must only be installed on top-level site of the hierarchy.
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
        [String]
        $CertificateFile,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $Schedule,

        [Parameter()]
        [Boolean]
        $Enable,

        [Parameter()]
        [Boolean]
        $EnableSynchronization,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SiteServerName $SiteServerName
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.APNotInstalled -f $SiteServerName)
            $result = $false
        }

        $evalList = @('CertificateFile','Enable','EnableSynchronization')

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($evalList -contains $param.key)
            {
                if ($param.Value -ne $state[$param.key])
                {
                    Write-Verbose -Message ($script:localizedData.TestSetting -f $param.Key, $param.Value, $state[$param.key])
                    $result = $false
                }
            }
        }

        if (([string]::IsNullOrEmpty($CertificateFile)) -and (-not [string]::IsNullOrEmpty(($state.CertificateFile))))
        {
            Write-Verbose -Message ($script:localizedData.NullCertCheck -f $SiteServerName)
            $result = $false
        }

        if (-not [string]::IsNullOrEmpty($Schedule))
        {
            $newSchedule = @{
                RecurInterval = $Schedule.RecurInterval
                RecurCount    = $Schedule.RecurCount
            }

            $desiredSchedule = New-CMSchedule @newSchedule

            $currentSchedule = @{
                RecurInterval = $state.Schedule.RecurInterval
                RecurCount    = $state.Schedule.RecurCount
            }

            $stateSchedule = New-CMSchedule @currentSchedule

            $array = @('DayDuration','DaySpan','HourDuration','HourSpan','IsGMT')

            foreach ($item in $array)
            {
                if ($desiredSchedule.$($item) -ne $stateSchedule.$($item))
                {
                    Write-Verbose -Message ($script:localizedData.ScheduleItem `
                        -f $item, $($desiredSchedule.$($item)), $($stateSchedule.$($item)))
                    $result = $false
                }
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.APAbsent -f $SiteServerName)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
