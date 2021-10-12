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

    .Parameter Type
        Specifies the client type, Device or User.
        Not Used in Get.
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
        $ClientSettingName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Device','User')]
        [String]
        $Type
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $clientSetting = Get-CMClientSetting -Name $ClientSettingName

    if ($clientSetting)
    {
        if ($clientSetting.Type -ne 0)
        {
            $descript = $clientSetting.Description
            $clientType = @('Device','User')[$clientSetting.Type - 1]
            [array]$scopes = $clientSetting.SecuredScopeNames
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode          = $SiteCode
        ClientSettingName = $ClientSettingName
        Description       = $descript
        Type              = $clientType
        SecurityScopes    = $scopes
        Ensure            = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies a site code for the Configuration Manager site.

    .Parameter ClientSettingName
        Specifies which client settings policy to modify.

    .Parameter Type
        Specifies the client type, Device or User.

    .Parameter Description
        Specifies the description of the client policy.

    .Parameter SecurityScopes
        Specifies an array of Security Scopes to match.

    .Parameter SecurityScopesToInclude
        Specifies an array of Security Scopes to include.

    .Parameter SecurityScopesToExclude
        Specifies an array of Security Scopes to exclude.

    .Parameter Ensure
        Specifies if the client policy is present or absent.
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('Device','User')]
        [String]
        $Type,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [String[]]
        $SecurityScopes,

        [Parameter()]
        [String[]]
        $SecurityScopesToInclude,

        [Parameter()]
        [String[]]
        $SecurityScopesToExclude,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName -Type $Type

    try
    {
        if ($state.Ensure -ne 'Absent' -and $state.Type -ne $Type)
        {
            throw ($script:localizedData.TypeMisMatch -f $ClientSettingName)
        }
        elseif ($Ensure -eq 'Present')
        {
            if ($PSBoundParameters.ContainsKey('SecurityScopes'))
            {
                if ($PSBoundParameters.ContainsKey('SecurityScopesToInclude') -or
                    $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
                {
                    Write-Warning -Message $script:localizedData.ParamIgnoreScopes
                }
            }
            elseif (-not $PSBoundParameters.ContainsKey('SecurityScopes') -and
                $PSBoundParameters.ContainsKey('SecurityScopesToInclude') -and
                $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
            {
                foreach ($item in $SecurityScopesToInclude)
                {
                    if ($SecurityScopesToExclude -contains $item)
                    {
                        throw ($script:localizedData.ScopeInEx -f $item)
                    }
                }
            }
            elseif (-not $PSBoundParameters.ContainsKey('SecurityScopes') -and
                -not $PSBoundParameters.ContainsKey('SecurityScopesToInclude') -and
                $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
            {
                if ($state.SecurityScopes.Count -eq $SecurityScopesToExclude.Count)
                {
                    $excludeAll = Compare-Object -ReferenceObject $state.SecurityScopes -DifferenceObject $SecurityScopesToExclude
                    if ([string]::IsNullOrEmpty($excludeAll))
                    {
                        throw ($script:localizedData.ScopeExcludeAll)
                    }
                }
            }

            if ($state.Ensure -eq 'Absent')
            {
                if ($PSBoundParameters.ContainsKey('Description'))
                {
                    $newParams = @{
                        Name        = $ClientSettingName
                        Type        = $Type
                        Description = $Description
                    }
                }
                else
                {
                    $newParams = @{
                        Name = $ClientSettingName
                        Type = $Type
                    }
                }

                New-CMClientSetting @newParams
                $newClient = $true
            }

            if ($newClient -ne $true -and $PSBoundParameters.ContainsKey('Description') -and $Description -ne $state.Description)
            {
                Set-CMClientSetting -Name $ClientSettingName -Description $Description
            }

            if ($SecurityScopes -or $SecurityScopesToInclude -or $SecurityScopesToExclude)
            {
                $scopeArray = @{
                    Match        = $SecurityScopes
                    Include      = $SecurityScopesToInclude
                    Exclude      = $SecurityScopesToExclude
                    CurrentState = $state.SecurityScopes
                }

                $scopeCompare = Compare-MultipleCompares @scopeArray

                if ($scopeCompare.Missing -or $scopeCompare.Remove)
                {
                    $clientObject = Get-CMClientSetting -Name $ClientSettingName
                }

                if ($scopeCompare.Missing)
                {
                    foreach ($add in $scopeCompare.Missing)
                    {
                        if (Get-CMSecurityScope -Name $add)
                        {
                            Write-Verbose -Message ($script:localizedData.AddScope -f $add, $ClientSettingName)
                            Add-CMObjectSecurityScope -Name $add -InputObject $clientObject
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.SecurityScopeMissing -f $add)
                        }
                    }
                }

                if ($scopeCompare.Remove)
                {
                    foreach ($remove in $scopeCompare.Remove)
                    {
                        Write-Verbose -Message ($script:localizedData.RemoveScope -f $remove, $ClientSettingName)
                        Remove-CMObjectSecurityScope -Name $remove -InputObject $clientObject
                    }
                }
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.SetAbsent -f $ClientSettingName)
            Remove-CMClientSetting -Name $ClientSettingName
        }

        if ($errorMsg)
        {
            throw ($errorMsg | Out-String)
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

    .Parameter Type
        Specifies the client type, Device or User.

    .Parameter Description
        Specifies the description of the client policy.

    .Parameter SecurityScopes
        Specifies an array of Security Scopes to match.

    .Parameter SecurityScopesToInclude
        Specifies an array of Security Scopes to include.

    .Parameter SecurityScopesToExclude
        Specifies an array of Security Scopes to exclude.

    .Parameter Ensure
        Specifies if the client policy is present or absent.
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('Device','User')]
        [String]
        $Type,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [String[]]
        $SecurityScopes,

        [Parameter()]
        [String[]]
        $SecurityScopesToInclude,

        [Parameter()]
        [String[]]
        $SecurityScopesToExclude,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -ClientSettingName $ClientSettingName -Type $Type
    $result = $true

    if ($state.Ensure -ne 'Absent' -and $state.Type -ne $Type)
    {
        Write-Warning -Message ($script:localizedData.TypeMisMatch -f $ClientSettingName)
        $result = $false
    }
    elseif ($Ensure -eq 'Present')
    {
        $defaultValues = @('Type','Description','Ensure')

        $testParams = @{
            CurrentValues = $state
            DesiredValues = $PSBoundParameters
            ValuesToCheck = $defaultValues
        }

        $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

        if ($PSBoundParameters.ContainsKey('SecurityScopes'))
        {
            if ($PSBoundParameters.ContainsKey('SecurityScopesToInclude') -or
                $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
            {
                Write-Warning -Message $script:localizedData.ParamIgnoreScopes
            }
        }
        elseif (-not $PSBoundParameters.ContainsKey('SecurityScopes') -and
            $PSBoundParameters.ContainsKey('SecurityScopesToInclude') -and
            $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
        {
            foreach ($item in $SecurityScopesToInclude)
            {
                if ($SecurityScopesToExclude -contains $item)
                {
                    Write-Warning -Message ($script:localizedData.ScopeInEx -f $item)
                    $badInput = $true
                }
            }
        }
        elseif (-not $PSBoundParameters.ContainsKey('SecurityScopes') -and
                -not $PSBoundParameters.ContainsKey('SecurityScopesToInclude') -and
                $PSBoundParameters.ContainsKey('SecurityScopesToExclude'))
        {
            if ($state.SecurityScopes.Count -eq $SecurityScopesToExclude.Count)
            {
                $excludeAll = Compare-Object -ReferenceObject $state.SecurityScopes -DifferenceObject $SecurityScopesToExclude
                if ([string]::IsNullOrEmpty($excludeAll))
                {
                    Write-Warning -Message ($script:localizedData.ScopeExcludeAll)
                    $bardInput = $true
                }
            }
        }

        if ($SecurityScopes -or $SecurityScopesToInclude -or $SecurityScopesToExclude)
        {
            $scopeArray = @{
                Match        = $SecurityScopes
                Include      = $SecurityScopesToInclude
                Exclude      = $SecurityScopesToExclude
                CurrentState = $state.SecurityScopes
            }

            $scopeCompare = Compare-MultipleCompares @scopeArray

            if ($scopeCompare.Missing)
            {
                Write-Verbose -Message ($script:localizedData.ScopeMissing -f ($scopeCompare.Missing | Out-String))
                $result = $false
            }

            if ($scopeCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.ScopeRemove -f ($scopeCompare.Remove | Out-String))
                $result = $false
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.AbsentMsg -f $ClientSettingName)
        $result = $false
    }

    if ($result -eq $false -or $badInput -eq $true)
    {
        $finalResult = $false
    }
    else
    {
        $finalResult = $true
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $finalResult)
    Set-Location -Path "$env:temp"
    return $finalResult
}

Export-ModuleMember -Function *-TargetResource
