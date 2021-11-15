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

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.
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
        $ClientSettingName
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $clientSetting = Get-CMClientSetting -Name $ClientSettingName

    if ($clientSetting)
    {
        $type = @('Default','Device','User')[$clientSetting.Type]
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting PowerManagement

        if ($settings)
        {
            $enabled = [System.Convert]::ToBoolean($settings.Enabled)
            $userToOpt = [System.Convert]::ToBoolean($settings.AllowUserToOptOutFromPowerPlan)
            $allowUp = @('NotConfigured','Enabled','Disabled')[$settings.AllowWakeup]
            $wakeupProxy = [System.Convert]::ToBoolean($settings.EnableWakeupProxy)
            [UInt32]$portInfo = $settings.Port
            [UInt32]$wolPort = $settings.WolPort
            $firewallSetting = @()
            $firewallSetting += switch ($settings.WakeupProxyFirewallFlags)
            {
                0  { 'None' }
                9  { 'Public' }
                10 { 'Private' }
                11 { 'Private','Public' }
                12 { 'Domain' }
                13 { 'Public','Domain' }
                14 { 'Domain','Private' }
                15 { 'Domain','Private','Public' }
            }

            if ($settings.WakeupProxyDirectAccessPrefixList)
            {
                [array]$ipv6Prefixes = $settings.WakeupProxyDirectAccessPrefixList
            }
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                        = $SiteCode
        ClientSettingName               = $ClientSettingName
        Enable                          = $enabled
        AllowUserToOptOutFromPowerPlan  = $userToOpt
        EnableWakeupProxy               = $wakeupProxy
        WakeupProxyPort                 = $portInfo
        WakeOnLanPort                   = $wolPort
        FirewallExceptionForWakeupProxy = $firewallSetting
        WakeupProxyDirectAccessPrefix   = $ipv6Prefixes
        NetworkWakeupOption             = $allowUp
        ClientSettingStatus             = $status
        ClientType                      = $type
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .Parameter Enable
        Specifies if power management plan is to be used.

    .Parameter AllowUserToOptOutFromPowerPlan
        Specifies if users are allowed to out out from the power plan.

    .PARAMETER NetworkWakeUpOption
        Specifies if network wake up is enabled or disabled.

    .PARAMETER EnableWakeUpProxy
        Specifies if the wake up proxy will be enabled or disabled.

    .PARAMETER WakeupProxyPort
        Specifies the wake up proxy port.

    .PARAMETER WakeOnLanPort
        Specifies the wake on lan port.

    .PARAMETER FirewallExceptionForWakeupProxy
        Specifies the which firewall states will be configured for wakeup proxy.

    .PARAMETER WakeupProxyDirectAccessPrefix
        Specifies the IPV6 direct access prefix for the wake up proxy.
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
        $ClientSettingName,

        [Parameter()]
        [Boolean]
        $Enable,

        [Parameter()]
        [Boolean]
        $AllowUserToOptOutFromPowerPlan,

        [Parameter()]
        [ValidateSet('NotConfigured','Enabled','Disabled')]
        [String]
        $NetworkWakeUpOption,

        [Parameter()]
        [Boolean]
        $EnableWakeUpProxy,

        [Parameter()]
        [UInt32]
        $WakeupProxyPort,

        [Parameter()]
        [UInt32]
        $WakeOnLanPort,

        [Parameter()]
        [ValidateSet('None','Domain','Private','Public')]
        [String[]]
        $FirewallExceptionForWakeupProxy,

        [Parameter()]
        [String[]]
        $WakeupProxyDirectAccessPrefix
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName

    try
    {
        if ($state.ClientSettingStatus -eq 'Absent')
        {
            throw ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        }

        if ($state.ClientType -eq 'User')
        {
            throw $script:localizedData.WrongClientType
        }

        if (($PSBoundParameters.ContainsKey('WakeOnLanPort')) -and
            ($NetworkWakeUpOption -ne 'Enabled') -and
            ($EnableWakeUpProxy -ne '$true'))
        {
            throw $script:localizedData.WakeOnLanMsg
        }

        if (($EnableWakeUpProxy -ne $true) -and ($PSBoundParameters.ContainsKey('WakeupProxyPort') -or
            $PSBoundParameters.ContainsKey('FirewallExceptionForWakeupProxy') -or
            $PSBoundParameters.ContainsKey('WakeupProxyDirectAccessPrefix')))
        {
            throw $script:localizedData.WakeOnProxyMsg
        }

        if (($FirewallExceptionForWakeupProxy -and $FirewallExceptionForWakeupProxy -contains 'None') -and
            ($FirewallExceptionForWakeupProxy -contains 'Domain' -or $FirewallExceptionForWakeupProxy -contains 'Public' -or
             $FirewallExceptionForWakeupProxy -contains 'Private'))
        {
            throw $script:localizedData.FirewallMsg
        }

        $defaultValues = @('Enable','AllowUserToOptOutFromPowerPlan','NetworkWakeUpOption','EnableWakeUpProxy',
                           'WakeupProxyPort','WakeOnLanPort')

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($defaultValues -contains $param.Key)
            {
                if ($param.Value -ne $state[$param.Key])
                {
                    Write-Verbose -Message ($script:localizedData.SettingValue -f $param.Key, $param.Value)
                    $buildingParams += @{
                        $param.Key = $param.Value
                    }
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('FirewallExceptionForWakeupProxy'))
        {
            if (($state.FirewallExceptionForWakeupProxy)  -and
                ($FirewallExceptionForWakeupProxy.Count -eq $state.FirewallExceptionForWakeupProxy.Count))
            {
                foreach ($item in $FirewallExceptionForWakeupProxy)
                {
                    if (-not $($state.FirewallExceptionForWakeupProxy).Contains($item))
                    {
                        $setFirewall = $true
                    }
                }
            }
            else
            {
                $setFirewall = $true
            }

            if ($setFirewall -eq $true)
            {
                Write-Verbose -Message ($script:localizedData.SetFirewall -f ($FirewallExceptionForWakeupProxy | Out-String))
                $buildingParams += @{
                    FirewallExceptionForWakeupProxy = $FirewallExceptionForWakeupProxy
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('WakeupProxyDirectAccessPrefix'))
        {
            if (($state.WakeupProxyDirectAccessPrefix) -and
                ($WakeupProxyDirectAccessPrefix.Count -eq $state.WakeupProxyDirectAccessPrefix.Count))
            {
                foreach ($item in $WakeupProxyDirectAccessPrefix)
                {
                    if (-not $($state.WakeupProxyDirectAccessPrefix).Contains($item))
                    {
                        $setDirect = $true
                    }
                }
            }
            else
            {
                $setDirect = $true
            }

            if ($setDirect -eq $true)
            {
                $proxy = $WakeupProxyDirectAccessPrefix -Join ','
                Write-Verbose -Message ($script:localizedData.DirectProxy -f $proxy)
                $buildingParams += @{
                    WakeupProxyDirectAccessPrefix = $proxy
                }
            }
        }

        if ($buildingParams)
        {
            if ($state.ClientType -eq 'Default')
            {
                Set-CMClientSettingPowerManagement -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingPowerManagement -Name $ClientSettingName @buildingParams
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
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .Parameter Enable
        Specifies if power management plan is to be used.

    .Parameter AllowUserToOptOutFromPowerPlan
        Specifies if users are allowed to out out from the power plan.

    .PARAMETER NetworkWakeUpOption
        Specifies if network wake up is enabled or disabled.

    .PARAMETER EnableWakeUpProxy
        Specifies if the wake up proxy will be enabled or disabled.

    .PARAMETER WakeupProxyPort
        Specifies the wake up proxy port.

    .PARAMETER WakeOnLanPort
        Specifies the wake on lan port.

    .PARAMETER FirewallExceptionForWakeupProxy
        Specifies the which firewall states will be configured for wakeup proxy.

    .PARAMETER WakeupProxyDirectAccessPrefix
        Specifies the IPV6 direct access prefix for the wake up proxy.
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
        $ClientSettingName,

        [Parameter()]
        [Boolean]
        $Enable,

        [Parameter()]
        [Boolean]
        $AllowUserToOptOutFromPowerPlan,

        [Parameter()]
        [ValidateSet('NotConfigured','Enabled','Disabled')]
        [String]
        $NetworkWakeUpOption,

        [Parameter()]
        [Boolean]
        $EnableWakeUpProxy,

        [Parameter()]
        [UInt32]
        $WakeupProxyPort,

        [Parameter()]
        [UInt32]
        $WakeOnLanPort,

        [Parameter()]
        [ValidateSet('None','Domain','Private','Public')]
        [String[]]
        $FirewallExceptionForWakeupProxy,

        [Parameter()]
        [String[]]
        $WakeupProxyDirectAccessPrefix
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName
    $result = $true

    if ($state.ClientSettingStatus -eq 'Absent')
    {
        Write-Warning -Message ($script:localizedData.ClientPolicySetting -f $ClientSettingName)
        $result = $false
    }
    elseif ($state.ClientType -eq 'User')
    {
        Write-Warning -Message $script:localizedData.WrongClientType
        $result = $false
    }
    else
    {
        if (($PSBoundParameters.ContainsKey('WakeOnLanPort')) -and
            ($NetworkWakeUpOption -ne 'Enabled') -and
            ($EnableWakeUpProxy -ne '$true'))
        {
            Write-Warning -Message $script:localizedData.WakeOnLanMsg
            $badInput = $true
        }

        if (($EnableWakeUpProxy -ne $true) -and ($PSBoundParameters.ContainsKey('WakeupProxyPort') -or
            $PSBoundParameters.ContainsKey('FirewallExceptionForWakeupProxy') -or
            $PSBoundParameters.ContainsKey('WakeupProxyDirectAccessPrefix')))
        {
            Write-Warning -Message $script:localizedData.WakeOnProxyMsg
            $badInput = $true
        }

        if (($FirewallExceptionForWakeupProxy -and $FirewallExceptionForWakeupProxy -contains 'None') -and
            ($FirewallExceptionForWakeupProxy -contains 'Domain' -or $FirewallExceptionForWakeupProxy -contains 'Public' -or
             $FirewallExceptionForWakeupProxy -contains 'Private'))
        {
            Write-Warning -Message $script:localizedData.FirewallMsg
            $badInput = $true
        }

        $defaultValues = @('Enable','AllowUserToOptOutFromPowerPlan','NetworkWakeUpOption','EnableWakeUpProxy',
                           'WakeupProxyPort','WakeOnLanPort','WakeupProxyDirectAccessPrefix','FirewallExceptionForWakeupProxy')

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = $defaultValues
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose -SortArrayValues
    }

    if ($result -eq $false -or $badInput -eq $true)
    {
        $return = $false
    }
    else
    {
        $return = $true
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $return)
    Set-Location -Path "$env:temp"
    return $return
}

Export-ModuleMember -Function *-TargetResource
