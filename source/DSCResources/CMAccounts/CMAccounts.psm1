$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the CRL Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath -ChildPath (Join-Path -Path 'ConfigMgrCBDsc.ResourceHelper' -ChildPath 'ConfigMgrCBDsc.ResourceHelper.psm1'))

# Import Localization Strings
$localizedData = Get-LocalizedData -ResourceName 'CMAccounts' -ResourcePath (Split-Path -Parent $script:MyInvocation.MyCommand.Path)

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

    Write-Verbose -Message $localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule
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

    Import-ConfigMgrPowerShellModule
    Set-Location -Path "$($SiteCode):\"
    Write-Verbose -Message $localizedData.RetrieveSettingValue
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

                Write-Verbose -Message ($localizedData.AddingCMAccount -f $Account)
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

                Write-Verbose -Message ($localizedData.RemovingCMAccount -f $Account)
                Remove-CMAccount @param
            }
        }

        if ($null -eq $param)
        {
            Write-Verbose -Message $localizedData.DesiredState
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

    Import-ConfigMgrPowerShellModule
    Set-Location -Path "$($SiteCode):\"
    $currentState = (Get-CMAccount -SiteCode $SiteCode).Username
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if (($currentState -notcontains $Account))
        {
            Write-Verbose -Message ($localizedData.TestPresent -f $Account)
            $result = $false
        }
    }
    else
    {
        if (($currentState -contains $Account))
        {
            Write-Verbose -Message ($localizedData.TestAbsent -f $Account)
            $result = $false
        }
    }

    Write-Verbose -Message ($localizedData.TestState -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource
