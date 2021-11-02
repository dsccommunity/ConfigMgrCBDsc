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
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting ComputerAgent

        if ($settings)
        {
            $initialReminder = $settings.ReminderInterval
            $interimReminder = $settings.DayReminderInterval
            $finalReminder = $settings.HourReminderInterval
            $titleBranding = $settings.BrandingTitle
            $useSoftCenter = [System.Convert]::ToBoolean($settings.UseNewSoftwareCenter)
            $healthAttest = [System.Convert]::ToBoolean($settings.EnableHealthAttestation)
            $onPremHealth = [System.Convert]::ToBoolean($settings.UseOnPremHAService)
            $install = [UInt32]$settings.InstallRestriction
            $restrictInstall = @('AllUsers','OnlyAdministrators','','OnlyAdministratorsAndPrimaryUsers','NoUsers')[$settings.InstallRestriction]
            $bitLocker = @('Never','Always')[$settings.SuspendBitLocker]
            $thirdParty = @('No','Yes')[$settings.EnableThirdPartyOrchestration]
            $psExecut = @('AllSigned','Bypass','Restricted')[$settings.PowerShellExecutionPolicy]
            $notification = [System.Convert]::ToBoolean($settings.DisplayNewProgramNotification)
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                       = $SiteCode
        ClientSettingName              = $ClientSettingName
        InitialReminderHr              = $initialReminder
        InterimReminderHr              = $interimReminder
        FinalReminderMins              = $finalReminder
        BrandingTitle                  = $titleBranding
        UseNewSoftwareCenter           = $useSoftCenter
        EnableHealthAttestation        = $healthAttest
        UseOnPremisesHealthAttestation = $onPremHealth
        InstallRestriction             = $restrictInstall
        SuspendBitLocker               = $bitLocker
        EnableThirdPartyOrchestration  = $thirdParty
        PowerShellExecutionPolicy      = $psExecut
        DisplayNewProgramNotification  = $notification
        ClientSettingStatus            = $status
        ClientType                     = $type
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER InitialReminderHr
        Specifies reminder, in hours, for deployment deadlines greater than 24 hours.

    .PARAMETER InterimReminderHr
        Specifies reminder, in hours, for deployment deadlines less than 24 hours.

    .PARAMETER FinalReminderMins
        Specifies reminder, in minutes, for deployment deadlines less than 1 hours.

    .PARAMETER BrandingTitle
        Specifies the organizational name displayed in software center.

    .PARAMETER UseNewSoftwareCenter
        Specifies if new software center is enabled or disabled.

    .PARAMETER EnableHealthAttestation
        Specifies if communication with the Health Attestation service is enabled or disabled.

    .PARAMETER UseOnPremisesHealthAttestation
        Specifies if the on-premises health service is enabled or disabled.

    .PARAMETER InstallRestriction
        Specifies the install permissions.

    .PARAMETER SuspendBitLocker
        Specifies the suspend BitLocker PIN entry on restart.

    .PARAMETER EnableThirdPartyOrchestration
        Specifies if additional software manages the deployment of applications and updates.

    .PARAMETER PowerShellExecutionPolicy
        Specifies powershell execution policy settings.

    .PARAMETER DisplayNewProgramNotification
        Specifies if notifications are shown for new deployments.
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
        [ValidateRange(1,999)]
        [UInt32]
        $InitialReminderHr,

        [Parameter()]
        [ValidateRange(1,24)]
        [UInt32]
        $InterimReminderHr,

        [Parameter()]
        [ValidateRange(5,25)]
        [UInt32]
        $FinalReminderMins,

        [Parameter()]
        [String]
        $BrandingTitle,

        [Parameter()]
        [Boolean]
        $UseNewSoftwareCenter,

        [Parameter()]
        [Boolean]
        $EnableHealthAttestation,

        [Parameter()]
        [Boolean]
        $UseOnPremisesHealthAttestation,

        [Parameter()]
        [ValidateSet('AllUsers','OnlyAdministrators','OnlyAdministratorsAndPrimaryUsers','NoUsers')]
        [String]
        $InstallRestriction,

        [Parameter()]
        [ValidateSet('Never','Always')]
        [String]
        $SuspendBitLocker,

        [Parameter()]
        [ValidateSet('No','Yes')]
        [String]
        $EnableThirdPartyOrchestration,

        [Parameter()]
        [ValidateSet('AllSigned','Bypass','Restricted')]
        [String]
        $PowerShellExecutionPolicy,

        [Parameter()]
        [Boolean]
        $DisplayNewProgramNotification
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

        if ($PSBoundParameters.ContainsKey('UseOnPremisesHealthAttestation') -and $EnableHealthAttestation -ne $true)
        {
            Write-Warning -Message $script:localizedData.HealthAttestMsg
            $defaultValues = @('InitialReminderHr','InterimReminderHr','FinalReminderMins','BrandingTitle','UseNewSoftwareCenter','EnableHealthAttestation',
                'InstallRestriction','SuspendBitLocker','EnableThirdPartyOrchestration','PowerShellExecutionPolicy','DisplayNewProgramNotification')
        }
        else
        {
            $defaultValues = @('InitialReminderHr','InterimReminderHr','FinalReminderMins','BrandingTitle','UseNewSoftwareCenter','EnableHealthAttestation',
                'UseOnPremisesHealthAttestation','InstallRestriction','SuspendBitLocker','EnableThirdPartyOrchestration','PowerShellExecutionPolicy',
                'DisplayNewProgramNotification')
        }

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

        if ($buildingParams)
        {
            if ($buildingParams.ContainsKey('UseOnPremisesHealthAttestation') -and
                -not $buildingParams.ContainsKey('EnableHealthAttestation'))
            {
                $buildingParams += @{
                    EnableHealthAttestation = $EnableHealthAttestation
                }
            }

            if ($state.ClientType -eq 'Default')
            {
                Set-CMClientSettingComputerAgent -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingComputerAgent -Name $ClientSettingName @buildingParams
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

    .PARAMETER InitialReminderHr
        Specifies reminder, in hours, for deployment deadlines greater than 24 hours.

    .PARAMETER InterimReminderHr
        Specifies reminder, in hours, for deployment deadlines less than 24 hours.

    .PARAMETER FinalReminderMins
        Specifies reminder, in minutes, for deployment deadlines less than 1 hours.

    .PARAMETER BrandingTitle
        Specifies the organizational name displayed in software center.

    .PARAMETER UseNewSoftwareCenter
        Specifies if new software center is enabled or disabled.

    .PARAMETER EnableHealthAttestation
        Specifies if communication with the Health Attestation service is enabled or disabled.

    .PARAMETER UseOnPremisesHealthAttestation
        Specifies if the on-premises health service is enabled or disabled.

    .PARAMETER InstallRestriction
        Specifies the install permissions.

    .PARAMETER SuspendBitLocker
        Specifies the suspend BitLocker PIN entry on restart.

    .PARAMETER EnableThirdPartyOrchestration
        Specifies if additional software manages the deployment of applications and updates.

    .PARAMETER PowerShellExecutionPolicy
        Specifies powershell execution policy settings.

    .PARAMETER DisplayNewProgramNotification
        Specifies if notifications are shown for new deployments.
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
        [ValidateRange(1,999)]
        [UInt32]
        $InitialReminderHr,

        [Parameter()]
        [ValidateRange(1,24)]
        [UInt32]
        $InterimReminderHr,

        [Parameter()]
        [ValidateRange(5,25)]
        [UInt32]
        $FinalReminderMins,

        [Parameter()]
        [String]
        $BrandingTitle,

        [Parameter()]
        [Boolean]
        $UseNewSoftwareCenter,

        [Parameter()]
        [Boolean]
        $EnableHealthAttestation,

        [Parameter()]
        [Boolean]
        $UseOnPremisesHealthAttestation,

        [Parameter()]
        [ValidateSet('AllUsers','OnlyAdministrators','OnlyAdministratorsAndPrimaryUsers','NoUsers')]
        [String]
        $InstallRestriction,

        [Parameter()]
        [ValidateSet('Never','Always')]
        [String]
        $SuspendBitLocker,

        [Parameter()]
        [ValidateSet('No','Yes')]
        [String]
        $EnableThirdPartyOrchestration,

        [Parameter()]
        [ValidateSet('AllSigned','Bypass','Restricted')]
        [String]
        $PowerShellExecutionPolicy,

        [Parameter()]
        [Boolean]
        $DisplayNewProgramNotification
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
        if ($PSBoundParameters.ContainsKey('UseOnPremisesHealthAttestation') -and $EnableHealthAttestation -ne $true)
        {
            Write-Warning -Message $script:localizedData.HealthAttestMsg
            $defaultValues = @('InitialReminderHr','InterimReminderHr','FinalReminderMins','BrandingTitle','UseNewSoftwareCenter','EnableHealthAttestation',
                'InstallRestriction','SuspendBitLocker','EnableThirdPartyOrchestration','PowerShellExecutionPolicy','DisplayNewProgramNotification')
        }
        else
        {
            $defaultValues = @('InitialReminderHr','InterimReminderHr','FinalReminderMins','BrandingTitle','UseNewSoftwareCenter','EnableHealthAttestation',
                'UseOnPremisesHealthAttestation','InstallRestriction','SuspendBitLocker','EnableThirdPartyOrchestration','PowerShellExecutionPolicy',
                'DisplayNewProgramNotification')
        }

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = $defaultValues
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
