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

    .PARAMETER AdminName
        Specifies the name of the administrator account.
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
        $AdminName
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $admin = Get-CMAdministrativeUser -Name $AdminName

    if ($admin)
    {
        $scope = @()
        $collections = @()

        foreach ($item in $admin.Permissions)
        {
            if ($item.CategoryTypeID -eq 29)
            {
                $scope += $item.CategoryName
            }
            elseif ($item.CategoryTypeId -eq 1)
            {
                $collections += $item.CategoryName
            }
        }

        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return  @{
        SiteCode    = $SiteCode
        AdminName   = $AdminName
        Roles       = $admin.RoleNames
        Collections = $collections
        Scopes      = $scope
        Ensure      = $status
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER AdminName
        Specifies the name of the administrator account.

    .PARAMETER Roles
        Specifies an array of names for the roles desired to be assigned to an administrative user.

    .PARAMETER RolesToInclude
        Specifies an array of names for the roles desired to be added to an administrative user.

    .PARAMETER RolesToExclude
        Specifies an array of names for the roles desired to be removed from an administrative user.

    .PARAMETER Scopes
        Specifies an array of names for the scopes desired to be assigned to an administrative user.

    .PARAMETER ScopesToInclude
        Specifies an array of names for the scopes desired to be added to an administrative user.

    .PARAMETER ScopesToExclude
        Specifies an array of names for the scopes desired to be removed from an administrative user.

    .PARAMETER Collections
        Specifies an array of names for the collections desired to be assigned to an administrative user.

    .PARAMETER CollectionsToInclude
        Specifies an array of names for the collections desired to be added to an administrative user.

    .PARAMETER CollectionsToExclude
        Specifies an array of names for the collections desired to be removed from an administrative user.

    .PARAMETER Ensure
        Specifies if the administrative User is to be present or absent.
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
        $AdminName,

        [Parameter()]
        [String[]]
        $Roles,

        [Parameter()]
        [String[]]
        $RolesToInclude,

        [Parameter()]
        [String[]]
        $RolesToExclude,

        [Parameter()]
        [String[]]
        $Scopes,

        [Parameter()]
        [String[]]
        $ScopesToInclude,

        [Parameter()]
        [String[]]
        $ScopesToExclude,

        [Parameter()]
        [String[]]
        $Collections,

        [Parameter()]
        [String[]]
        $CollectionsToInclude,

        [Parameter()]
        [String[]]
        $CollectionsToExclude,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -AdminName $AdminName

    try
    {
        if ($Ensure -eq 'Present')
        {
            if ($Roles -or $RolesToInclude -or $RolesToExclude)
            {
                $rolesArray = @{
                    Match        = $Roles
                    Include      = $RolesToInclude
                    Exclude      = $RolesToExclude
                    CurrentState = $state.Roles
                }

                $roleCompare = Compare-MultipleCompares @rolesArray

                if ($roleCompare.Missing)
                {
                    foreach ($roleCheck in $roleCompare.Missing)
                    {
                        if (Get-CMSecurityRole -Name $roleCheck)
                        {
                            $rolesAdd += $roleCheck
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.ErrorMsg -f $roleCheck, 'role')
                        }
                    }
                }
            }

            if ($Scopes -or $ScopesToInclude -or $ScopesToExclude)
            {
                $scopesArray = @{
                    Match        = $Scopes
                    Include      = $ScopesToInclude
                    Exclude      = $ScopesToExclude
                    CurrentState = $state.Scopes
                }

                $scopeCompare = Compare-MultipleCompares @scopesArray

                if ($scopeCompare.Missing)
                {
                    foreach ($scopeCheck in $scopeCompare.Missing)
                    {
                        if (Get-CMSecurityScope -Name $scopeCheck)
                        {
                            $scopesAdd += $scopeCheck
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.ErrorMsg -f $scopeCheck, 'Scope')
                        }
                    }
                }
            }

            if ($Collections -or $CollectionsToInclude -or $CollectionsToExclude)
            {
                $collectionsArray = @{
                    Match        = $Collections
                    Include      = $CollectionsToInclude
                    Exclude      = $CollectionsToExclude
                    CurrentState = $state.Collections
                }

                $collectionsCompare = Compare-MultipleCompares @collectionsArray

                if ($collectionsCompare.Missing)
                {
                    foreach ($collectionCheck in $collectionsCompare.Missing)
                    {
                        if (Get-CMCollection -Name $collectionCheck)
                        {
                            $collectionsAdd += $collectionCheck
                        }
                        else
                        {
                            $errorMsg += ($script:localizedData.ErrorMsg -f $collectionCheck, 'Collections')
                        }
                    }
                }
            }

            if ($state.Ensure -eq 'Absent')
            {
                if ($rolesAdd)
                {
                    Write-Verbose -Message ($script:localizedData.RolesMissing -f ($rolesAdd | Out-String))

                    $buildingParams += @{
                        RoleName = $rolesAdd
                    }
                }
                else
                {
                    throw $script:localizedData.ValidRole
                }

                if ($scopesAdd)
                {
                    Write-Verbose -Message ($script:localizedData.ScopesMissing -f ($scopesAdd | Out-String))

                    $buildingParams += @{
                        SecurityScopeName = $scopesAdd
                    }
                }

                if ($collectionsAdd)
                {
                    Write-Verbose -Message ($script:localizedData.CollectionsMissing -f ($collectionsAdd | Out-String))

                    $buildingParams += @{
                        CollectionName = $collectionsAdd
                    }
                }

                if ($buildingParams)
                {
                    New-CMAdministrativeUser -Name $AdminName @buildingParams
                }
            }
            else
            {
                if ($rolesAdd)
                {
                    foreach ($role in $rolesAdd)
                    {
                        Write-Verbose -Message ($script:localizedData.RolesMissing -f $role)
                        Add-CMSecurityRoleToAdministrativeUser -RoleName $role -AdministrativeUserName $AdminName
                    }
                }

                if ($roleCompare.Remove)
                {
                    foreach ($roleRemove in $roleCompare.Remove)
                    {
                        Write-Verbose -Message ($script:localizedData.RolesRemove -f $roleRemove)
                        Remove-CMSecurityRoleFromAdministrativeUser -RoleName $roleRemove -AdministrativeUserName $AdminName
                    }
                }

                if ($scopesAdd)
                {
                    if ($scopeCompare.CurrentState.Contains('All'))
                    {
                        throw $script:localizedData.ModifyAll
                    }

                    if ($scopesAdd.Contains('All'))
                    {
                        throw $script:localizedData.AllParam
                    }

                    foreach ($scope in $scopesAdd)
                    {
                        Write-Verbose -Message ($script:localizedData.ScopesMissing -f $scope)
                        Add-CMSecurityScopeToAdministrativeUser -AdministrativeUserName $AdminName -SecurityScopeName $scope
                    }
                }

                if ($scopeCompare.Remove)
                {
                    if ($scopeCompare.Remove.Contains('All'))
                    {
                        throw $script:localizedData.RemoveAll
                    }

                    foreach ($scopeRemove in $scopeCompare.Remove)
                    {
                        Write-Verbose -Message ($script:localizedData.ScopesRemove -f $scopeRemove)
                        Remove-CMSecurityScopeFromAdministrativeUser -AdministrativeUserName $AdminName -SecurityScopeName $scopeRemove
                    }
                }

                if ($collectionsAdd)
                {
                    foreach ($collection in $collectionsAdd)
                    {
                       Write-Verbose -Message ($script:localizedData.CollectionsMissing -f $collection)
                       Add-CMCollectionToAdministrativeUser -UserName $AdminName -CollectionName $collection
                    }
                }

                if ($collectionsCompare.Remove)
                {
                    foreach ($collectionRemove in $collectionsCompare.Remove)
                    {
                        Write-Verbose -Message ($script:localizedData.CollectionsRemove -f $collectionRemove)
                        Remove-CMCollectionFromAdministrativeUser -UserName $AdminName -CollectionName $collectionRemove
                    }
                }
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemoveAdmin -f $AdminName)
            Remove-CMAdministrativeUser -Name $AdminName
        }

        if ($errorMsg)
        {
            throw $errorMsg
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
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER AdminName
        Specifies the name of the administrator account.

    .PARAMETER Roles
        Specifies an array of names for the roles desired to be assigned to an administrative user.

    .PARAMETER RolesToInclude
        Specifies an array of names for the roles desired to be added to an administrative user.

    .PARAMETER RolesToExclude
        Specifies an array of names for the roles desired to be removed from an administrative user.

    .PARAMETER Scopes
        Specifies an array of names for the scopes desired to be assigned to an administrative user.

    .PARAMETER ScopesToInclude
        Specifies an array of names for the scopes desired to be added to an administrative user.

    .PARAMETER ScopesToExclude
        Specifies an array of names for the scopes desired to be removed from an administrative user.

    .PARAMETER Collections
        Specifies an array of names for the collections desired to be assigned to an administrative user.

    .PARAMETER CollectionsToInclude
        Specifies an array of names for the collections desired to be added to an administrative user.

    .PARAMETER CollectionsToExclude
        Specifies an array of names for the collections desired to be removed from an administrative user.

    .PARAMETER Ensure
        Specifies if the administrative User is to be present or absent.
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
        $AdminName,

        [Parameter()]
        [String[]]
        $Roles,

        [Parameter()]
        [String[]]
        $RolesToInclude,

        [Parameter()]
        [String[]]
        $RolesToExclude,

        [Parameter()]
        [String[]]
        $Scopes,

        [Parameter()]
        [String[]]
        $ScopesToInclude,

        [Parameter()]
        [String[]]
        $ScopesToExclude,

        [Parameter()]
        [String[]]
        $Collections,

        [Parameter()]
        [String[]]
        $CollectionsToInclude,

        [Parameter()]
        [String[]]
        $CollectionsToExclude,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -AdminName $AdminName
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            if ([string]::IsNullOrEmpty($Roles) -and [string]::IsNullOrEmpty($RolesToInclude))
            {
                write-Warning -Message 'Administrator account is absent, Roles or RolesToInclude will need to be specified with a valide rolename'
            }

            Write-Verbose -Message ($script:localizedData.AddAdmin -f $AdminName)
            $result = $false
        }
        else
        {
            if ($Roles -or $RolesToInclude -or $RolesToExclude)
            {
                $rolesArray = @{
                    Match        = $Roles
                    Include      = $RolesToInclude
                    Exclude      = $RolesToExclude
                    CurrentState = $state.Roles
                }

                $roleCompare = Compare-MultipleCompares @rolesArray

                if ($PSBoundParameters.ContainsKey('Roles'))
                {
                    if ($PSBoundParameters.ContainsKey('RolesToInclude') -or $PSBoundParameters.ContainsKey('RolesToExclude'))
                    {
                        Write-Warning -Message $script:localizedData.RolesIgnore
                    }
                }

                if ($roleCompare.Missing)
                {
                    Write-Verbose -Message ($script:localizedData.RolesMissing -f ($roleCompare.Missing | Out-String))
                    $result = $false
                }

                if ($roleCompare.Remove)
                {
                    Write-Verbose -Message ($script:localizedData.RolesRemove -f ($roleCompare.Remove | Out-String))
                    $result = $false
                }
            }

            if ($Scopes -or $ScopesToInclude -or $ScopesToExclude)
            {
                $scopesArray = @{
                    Match        = $Scopes
                    Include      = $ScopesToInclude
                    Exclude      = $ScopesToExclude
                    CurrentState = $state.Scopes
                }

                $scopeCompare = Compare-MultipleCompares @scopesArray

                if ($PSBoundParameters.ContainsKey('Scopes'))
                {
                    if ($PSBoundParameters.ContainsKey('ScopesToInclude') -or $PSBoundParameters.ContainsKey('ScopesToExclude'))
                    {
                        Write-Warning -Message $script:localizedData.ScopesIgnore
                    }
                }

                if ($scopeCompare.Missing)
                {
                    if ($scopeCompare.Missing.Contains('All'))
                    {
                        Write-Warning -Message $script:localizedData.AllParam
                    }

                    if ($scopeCompare.CurrentState.Contains('All'))
                    {
                        Write-Warning -Message $script:localizedData.ModifyAll
                    }

                    Write-Verbose -Message ($script:localizedData.ScopesMissing -f ($scopeCompare.Missing | Out-String))
                    $result = $false
                }

                if ($scopeCompare.Remove)
                {
                    if ($scopeCompare.Remove.Contains('All'))
                    {
                        Write-Warning -Message $script:localizedData.RemoveAll
                    }

                    Write-Verbose -Message ($script:localizedData.ScopesRemove -f ($scopeCompare.Remove | Out-String))
                    $result = $false
                }
            }

            if ($Collections -or $CollectionsToInclude -or $CollectionsToExclude)
            {
                $collectionsArray = @{
                    Match        = $Collections
                    Include      = $CollectionsToInclude
                    Exclude      = $CollectionsToExclude
                    CurrentState = $state.Collections
                }

                $collectionsCompare = Compare-MultipleCompares @collectionsArray

                if ($PSBoundParameters.ContainsKey('Collections'))
                {
                    if ($PSBoundParameters.ContainsKey('CollectionsToInclude') -or
                        $PSBoundParameters.ContainsKey('CollectionsToExclude'))
                    {
                        Write-Warning -Message $script:localizedData.CollectionsIgnore
                    }
                }

                if ($collectionsCompare.Missing)
                {
                    Write-Verbose -Message ($script:localizedData.CollectionsMissing -f ($collectionsCompare.Missing | Out-String))
                    $result = $false
                }

                if ($collectionsCompare.Remove)
                {
                    Write-Verbose -Message ($script:localizedData.CollectionsRemove -f ($collectionsCompare.Remove | Out-String))
                    $result = $false
                }
            }
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.RemoveAdmin -f $AdminName)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path $env:windir
    return $result
}

Export-ModuleMember -Function *-TargetResource
