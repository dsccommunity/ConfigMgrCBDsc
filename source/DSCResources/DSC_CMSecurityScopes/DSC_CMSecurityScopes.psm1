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

    .PARAMETER SecurityScopeName
        Specifies the Security Scope name.
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
        $SecurityScopeName
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $value = Get-CMSecurityScope -Name $SecurityScopeName

    if ($value)
    {
        if (($value.NumberOfAdmins -ge 1) -or ($value.NumberOfObjects -ge 2))
        {
            $assigned = $true
        }
        else
        {
            $assigned = $false
        }

        $state = 'Present'
    }
    else
    {
        $state = 'Absent'
    }

    return @{
        SiteCode          = $SiteCode
        SecurityScopeName = $SecurityScopeName
        Description       = $value.CategoryDescription
        Ensure            = $state
        InUse             = $assigned
    }
}

<#
    .SYNOPSIS
        This will set the results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SecurityScopeName
        Specifies the Security Scope name.

    .PARAMETER Description
        Specifies the description of the Security Scope.

    .PARAMETER Ensure
        Specifies if the Security Scope is to be present or absent.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $SecurityScopeName,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SecurityScopeName $SecurityScopeName

    try
    {
        if ($Ensure -eq 'Present')
        {
            if ($state.Ensure -eq 'Absent')
            {
                Write-Verbose -Message ($script:localizedData.NewScope -f $SecurityScopeName)
                New-CMSecurityScope -Name $SecurityScopeName
            }

            if ($PSBoundParameters.ContainsKey('Description') -and $Description -ne $state.Description)
            {
                Write-Verbose -Message ($script:localizedData.SetDesc -f $Description)
                Set-CMSecurityScope -Name $SecurityScopeName -Description $Description
            }
        }
        elseif ($state.Ensure -eq 'Present')
        {
            if ($state.InUse -eq $true)
            {
                throw $script:localizedData.InUseStatement
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.RemoveScope -f $SecurityScopeName)
                Remove-CMSecurityScope -Name $SecurityScopeName -Force
            }
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
        This will test the desired results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER SecurityScopeName
        Specifies the Security Scope name.

    .PARAMETER Description
        Specifies the description of the Security Scope.

    .PARAMETER Ensure
        Specifies if the Security Scope is to be present or absent.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $SecurityScopeName,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode -SecurityScopeName $SecurityScopeName
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.ScopeAbsent -f $SecurityScopeName)
            $result = $false
        }

        if ($PSBoundParameters.ContainsKey('Description') -and $Description -ne $state.Description)
        {
            Write-Verbose -Message ($script:localizedData.DescriptionTest -f $Description, $state.Description)
            $result = $false
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        if ($state.InUse -eq $true)
        {
            Write-Warning -Message $script:localizedData.InUseStatement
        }

        Write-Verbose -Message ($script:localizedData.ScopeStatusRemove -f $SecurityScopeName)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}
