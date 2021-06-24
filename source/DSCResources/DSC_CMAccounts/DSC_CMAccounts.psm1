$script:dscResourceCommonPath = Join-Path (Join-Path -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $PsScriptRoot)) -ChildPath Modules) -ChildPath DscResource.Common
$script:configMgrResourcehelper = Join-Path (Join-Path -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $PsScriptRoot)) -ChildPath Modules) -ChildPath ConfigMgrCBDsc.ResourceHelper

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
        $Account
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $accStatus = Get-CMAccount -SiteCode $SiteCode -UserName $Account

    if ($accStatus)
    {
        $status = 'Present'
    }
    else
    {
        $status = 'Absent'
    }

    return @{
        SiteCode = $SiteCode
        Account  = $Account
        Ensure   = $status
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
    $state = Get-TargetResource -SiteCode $SiteCode -Account $Account

    try
    {
        if ($Ensure -eq 'Present')
        {
            if ([string]::IsNullOrEmpty($AccountPassword))
            {
                throw $script:localizedData.MissingPass
            }

            if ($state.Ensure -eq 'Absent')
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
        elseif ($state.Ensure -eq 'Present')
        {
            $param = @{
                UserName = $Account
                Force    = $true
            }

            Write-Verbose -Message ($script:localizedData.RemovingCMAccount -f $Account)
            Remove-CMAccount @param
        }

        if ([string]::IsNullOrEmpty($param))
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
    $state = Get-TargetResource -SiteCode $SiteCode -Account $Account
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ([string]::IsNullOrEmpty($AccountPassword))
        {
            Write-Warning -Message $script:localizedData.MissingPass
        }

        if ($state.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.TestPresent -f $Account)
            $result = $false
        }
    }
    elseif ($state.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.TestAbsent -f $Account)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource
