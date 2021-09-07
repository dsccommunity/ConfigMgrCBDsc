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
        $settings = Get-CMClientSetting -Name $ClientSettingName -Setting ClientPolicy

        if ($settings)
        {
            $timeout = $settings.PolicyRequestAssignmentTimeout
            $userPolicy = [System.Convert]::ToBoolean($settings.PolicyEnableUserPolicyPolling)
            $internetUser = [System.Convert]::ToBoolean($settings.PolicyEnableUserPolicyOnInternet)
            $multiUser = [System.Convert]::ToBoolean($settings.PolicyEnableUserPolicyOnTS)
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode                   = $SiteCode
        ClientSettingName          = $ClientSettingName
        PolicyPollingMins          = $timeout
        EnableUserPolicy           = $userPolicy
        EnableUserPolicyOnInternet = $internetUser
        EnableUserPolicyOnTS       = $multiUser
        ClientSettingStatus        = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .PARAMETER PolicyPollingMins
        Specifies client policy interval in minutes.

    .PARAMETER EnableUserPolicy
        Specifies if user policy on clients is enabled or disabled.

    .PARAMETER EnableUserPolicyOnInternet
        Specifies if user policy request from internet clients is enabled or disabled.

    .PARAMETER EnableUserPolicyOnTS
        Specifies if user policy for multiple sessions is enabled or disabled.
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
        [ValidateRange(3,1440)]
        [UInt32]
        $PolicyPollingMins,

        [Parameter()]
        [Boolean]
        $EnableUserPolicy,

        [Parameter()]
        [Boolean]
        $EnableUserPolicyOnInternet,

        [Parameter()]
        [Boolean]
        $EnableUserPolicyOnTS
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

        $defaultValues = @('PolicyPollingMins','EnableUserPolicy','EnableUserPolicyOnInternet','EnableUserPolicyOnTS')

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
            if ($ClientSettingName -eq 'Default Client Agent Settings')
            {
                Set-CMClientSettingClientPolicy -DefaultSetting @buildingParams
            }
            else
            {
                Set-CMClientSettingClientPolicy -Name $ClientSettingName @buildingParams
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

    .PARAMETER PolicyPollingMins
        Specifies client policy interval in minutes.

    .PARAMETER EnableUserPolicy
        Specifies if user policy on clients is enabled or disabled.

    .PARAMETER EnableUserPolicyOnInternet
        Specifies if user policy request from internet clients is enabled or disabled.

    .PARAMETER EnableUserPolicyOnTS
        Specifies if user policy for multiple sessions is enabled or disabled.
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
        [ValidateRange(3,1440)]
        [UInt32]
        $PolicyPollingMins,

        [Parameter()]
        [Boolean]
        $EnableUserPolicy,

        [Parameter()]
        [Boolean]
        $EnableUserPolicyOnInternet,

        [Parameter()]
        [Boolean]
        $EnableUserPolicyOnTS
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
    else
    {
        $defaultValues = @('PolicyPollingMins','EnableUserPolicy','EnableUserPolicyOnInternet','EnableUserPolicyOnTS')

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
