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

    .PARAMETER Account
        Specifies the Configuation Manager account name.
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
        $Account,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    return @{
        SiteCode        = $SiteCode
        Account         = $Account
        CurrentAccounts = (Get-CMAccount -SiteCode $SiteCode).Username
        Ensure          = $Ensure
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER Account
        Specifies the Configuation Manager account name.

    .PARAMETER AccountPassword
        Specifies the password of the account being added to Configuration Manager.

    .PARAMETER Ensure
        Specifies whether the account is present or absent.
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
        $Account,

        [Parameter()]
        [ValidateNotNull()]
        [PSCredential]
        $AccountPassword,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    $currentState = (Get-CMAccount -SiteCode $SiteCode).Username

    try
    {
        if ($Ensure -eq 'Present')
        {
            if ($null -eq $AccountPassword)
            {
                throw 'When adding an account a password must be specified'
            }

            if ($currentState -notcontains $Account)
            {
                $param = @{
                    UserName = $Account
                    Password = $AccountPassword.Password
                    SiteCode = $SiteCode
                }

                Write-Verbose -Message ($script:localizedData.AddingCMAccount -f $Account)
                New-CMAccount @param
            }
        }
        else
        {
            if ($currentState -contains $Account)
            {
                $param = @{
                    UserName = $Account
                    Force    = $true
                }

                Write-Verbose -Message ($script:localizedData.RemovingCMAccount -f $Account)
                Remove-CMAccount @param
            }
        }

        if ($null -eq $param)
        {
            Write-Verbose -Message $script:localizedData.DesiredState
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

    .PARAMETER Account
        Specifies the Configuation Manager account name.

    .PARAMETER AccountPassword
        Specifies the password of the account to add to Configuration Manager.

    .PARAMETER Ensure
        Specifies whether the account is present or absent.
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
        $Account,

        [Parameter()]
        [ValidateNotNull()]
        [PSCredential]
        $AccountPassword,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $currentState = (Get-CMAccount -SiteCode $SiteCode).Username
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if (($currentState -notcontains $Account))
        {
            Write-Verbose -Message ($script:localizedData.TestPresent -f $Account)
            $result = $false
        }
    }
    else
    {
        if (($currentState -contains $Account))
        {
            Write-Verbose -Message ($script:localizedData.TestAbsent -f $Account)
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource
