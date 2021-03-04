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
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $deployTo = (Get-CMSiteComponent -SiteCode $SiteCode | Where-Object -FilterScript {$_.ComponentName -eq 'SMS_Discovery_Data_Manager'}).Props

    switch (($deployTo | Where-Object -FilterScript {$_.PropertyName -eq 'Settings'}).Value1)
    {
        'Inactive' { $clientPushStatus = $false }
        'Active'   { $clientPushStatus = $true }
    }

    switch (($deployTo | Where-Object -FilterScript {$_.PropertyName -eq 'Filters'}).Value)
    {
        0 {
            $dcDeploy = $true
            $wkDeploy = $true
            $svDeploy = $true
          }
        1 {
            $dcDeploy = $true
            $wkDeploy = $false
            $svDeploy = $true
          }
        2 {
            $dcDeploy = $false
            $wkDeploy = $true
            $svDeploy = $true
          }
        3 {
            $dcDeploy = $false
            $wkDeploy = $false
            $svDeploy = $true
          }
        4 {
            $dcDeploy = $true
            $wkDeploy = $true
            $svDeploy = $false
          }
        5 {
            $dcDeploy = $true
            $wkDeploy = $false
            $svDeploy = $false
          }
        6 {
            $dcDeploy = $false
            $wkDeploy = $true
            $svDeploy = $false
          }
        7 {
            $dcDeploy = $false
            $wkDeploy = $false
            $svDeploy = $false
          }
    }

    $installProp = ((Get-CMClientPushInstallation -SiteCode $SiteCode).Props | Where-Object -FilterScript {$_.PropertyName -eq 'Advanced Client Command Line'}).Value1

    switch (($deployTo | Where-Object -FilterScript {$_.PropertyName -eq 'AutoInstallSiteSystem'}).Value)
    {
        0 { $siteSystemsDeploy = $false }
        1 { $siteSystemsDeploy = $true }
    }

    [array]$accountsList = (Get-CMClientPushInstallation -SiteCode $SiteCode).PropLists.Values

    return @{
        SiteCode                              = $SiteCode
        EnableAutomaticClientPushInstallation = $clientPushStatus
        EnableSystemTypeConfigurationManager  = $siteSystemsDeploy
        EnableSystemTypeServer                = $svDeploy
        EnableSystemTypeWorkstation           = $wkDeploy
        InstallClientToDomainController       = $dcDeploy
        InstallationProperty                  = $installProp
        Accounts                              = $accountsList
    }
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER EnableAutomaticClientPushInstallation
        Specifies whether Configuration Manager automatically uses client push for discovered computers.

    .PARAMETER EnableSystemTypeConfigurationManager
        Specifies whether Configuration Manager pushes the client software to Configuration Manager site system servers.

    .PARAMETER EnableSystemTypeServer
        Specifies whether Configuration Manager pushes the client software to servers.

    .PARAMETER EnableSystemTypeWorkstation
        Specifies whether Configuration Manager pushes the client software to workstations.

    .PARAMETER InstallClientToDomainController
        Specifies whether to use automatic site-wide client push installation to install the Configuration Manager
        client software on domain controllers.

    .PARAMETER InstallationProperty
        Specifies any installation properties to use when installing the Configuration Manager client.

    .PARAMETER Accounts
       Specifies an array of accounts to exactly match for use with client push.

        If specifying an account the account must already exist in
        Configuration Manager. This can be achieved by using the CMAccounts Resource.

    .PARAMETER AccountsToInclude
        Specifies an array of accounts to add for use with client push.

    .PARAMETER AccountsToExclude
        Specifies an array of accounts to remove for use with client push.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter()]
        [Boolean]
        $EnableAutomaticClientPushInstallation,

        [Parameter()]
        [Boolean]
        $EnableSystemTypeConfigurationManager,

        [Parameter()]
        [Boolean]
        $EnableSystemTypeServer,

        [Parameter()]
        [Boolean]
        $EnableSystemTypeWorkstation,

        [Parameter()]
        [Boolean]
        $InstallClientToDomainController,

        [Parameter()]
        [String]
        $InstallationProperty,

        [Parameter()]
        [String[]]
        $Accounts,

        [Parameter()]
        [String[]]
        $AccountsToInclude,

        [Parameter()]
        [String[]]
        $AccountsToExclude
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode

        if (-not $PSBoundParameters.ContainsKey('Accounts') -and
            $PSBoundParameters.ContainsKey('AccountsToInclude') -and
            $PSBoundParameters.ContainsKey('AccountsToExclude'))
        {
            foreach ($item in $AccountsToInclude)
            {
                if ($AccountsToExclude -contains $item)
                {
                    throw ($script:localizedData.AccountsInEx -f $item)
                }
            }
        }

        if ($EnableAutomaticClientPushInstallation -eq $true)
        {
            if ($null -eq (Get-CMManagementPoint -SiteCode $SiteCode))
            {
                throw ($script:localizedData.MissingMP -f $SiteCode)
            }
        }

        if ((($PSBoundParameters.EnableAutomaticClientPushInstallation -eq $false) -or
            ([string]::IsNullOrEmpty($PSBoundParameters.EnableAutomaticClientPushInstallation) -and
            $state.EnableAutomaticClientPushInstallation -eq $false)) -and
            ((-not [string]::IsNullOrEmpty($PSBoundParameters.EnableSystemTypeConfigurationManager)) -or
            (-not [string]::IsNullOrEmpty($PSBoundParameters.EnableSystemTypeServer)) -or
            (-not [string]::IsNullOrEmpty($PSBoundParameters.EnableSystemTypeWorkstation))))
        {
            throw $script:localizedData.DisabledSettings
        }

        $eval = @('EnableAutomaticClientPushInstallation','EnableSystemTypeConfigurationManager','EnableSystemTypeServer','EnableSystemTypeWorkstation',
            'InstallClientToDomainController','InstallationProperty')

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($eval -contains $param.Key)
            {
                if ($param.Value -ne $state[$param.Key])
                {
                    Write-Verbose -Message ($script:localizedData.ModifySetting -f $param.Key, $param.Value)

                    $buildingParams += @{
                        $param.Key = $param.Value
                    }
                }
            }
        }

        if ($Accounts -or $AccountsToInclude -or $AccountsToExclude)
        {
            $clientPushArray = @{
                Match        = $Accounts
                Include      = $AccountsToInclude
                Exclude      = $AccountsToExclude
                CurrentState = $state.Accounts
            }

            $clientCompare = Compare-MultipleCompares @clientPushArray

            if ($clientCompare.Missing)
            {
                $missingAccount = @()
                foreach ($item in $clientCompare.Missing)
                {
                    if (Get-CMAccount -UserName $item)
                    {
                        Write-Verbose -Message ($script:localizedData.AddingAccount -f $item)
                        $missingAccount += $item
                    }
                    else
                    {
                        $errorMsg += ($script:localizedData.CMAccountMissing -f $item)
                    }
                }
            }

            if ($missingAccount)
            {
                $buildingParams += @{
                    AddAccount = $missingAccount
                }
            }

            if ($clientCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.CMAccountExtra -f ($clientCompare.Remove | Out-String))
                $buildingParams += @{
                    RemoveAccount = $clientCompare.Remove
                }
            }
        }

        if ($buildingParams)
        {
            Set-CMClientPushInstallation -SiteCode $SiteCode @buildingParams
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
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER EnableAutomaticClientPushInstallation
        Specifies whether Configuration Manager automatically uses client push for discovered computers.

    .PARAMETER EnableSystemTypeConfigurationManager
        Specifies whether Configuration Manager pushes the client software to Configuration Manager site system servers.

    .PARAMETER EnableSystemTypeServer
        Specifies whether Configuration Manager pushes the client software to servers.

    .PARAMETER EnableSystemTypeWorkstation
        Specifies whether Configuration Manager pushes the client software to workstations.

    .PARAMETER InstallClientToDomainController
        Specifies whether to use automatic site-wide client push installation to install the Configuration Manager
        client software on domain controllers.

    .PARAMETER InstallationProperty
        Specifies any installation properties to use when installing the Configuration Manager client.

    .PARAMETER Accounts
        Specifies an array of accounts to exactly match for use with client push.

        If specifying an account the account must already exist in
        Configuration Manager. This can be achieved by using the CMAccounts Resource.

    .PARAMETER AccountsToInclude
        Specifies an array of accounts to add for use with client push.

    .PARAMETER AccountsToExclude
        Specifies an array of accounts to remove for use with client push.
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

        [Parameter()]
        [Boolean]
        $EnableAutomaticClientPushInstallation,

        [Parameter()]
        [Boolean]
        $EnableSystemTypeConfigurationManager,

        [Parameter()]
        [Boolean]
        $EnableSystemTypeServer,

        [Parameter()]
        [Boolean]
        $EnableSystemTypeWorkstation,

        [Parameter()]
        [Boolean]
        $InstallClientToDomainController,

        [Parameter()]
        [String]
        $InstallationProperty,

        [Parameter()]
        [String[]]
        $Accounts,

        [Parameter()]
        [String[]]
        $AccountsToInclude,

        [Parameter()]
        [String[]]
        $AccountsToExclude
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode
    $result = $true

    if ($PSBoundParameters.ContainsKey('Accounts'))
    {
        if ($PSBoundParameters.ContainsKey('AccountsToInclude') -or
            $PSBoundParameters.ContainsKey('AccountsToExclude'))
        {
            Write-Warning -Message $script:localizedData.AccountsIgnore
        }
    }
    elseif (-not $PSBoundParameters.ContainsKey('Accounts') -and
        $PSBoundParameters.ContainsKey('AccountsToInclude') -and
        $PSBoundParameters.ContainsKey('AccountsToExclude'))
    {
        foreach ($item in $AccountsToInclude)
        {
            if ($AccountsToExclude -contains $item)
            {
                Write-Warning -Message ($script:localizedData.AccountsInEx -f $item)
                $result = $false
            }
        }
    }

    if ((($PSBoundParameters.EnableAutomaticClientPushInstallation -eq $false) -or
        ([string]::IsNullOrEmpty($PSBoundParameters.EnableAutomaticClientPushInstallation) -and
        $state.EnableAutomaticClientPushInstallation -eq $false)) -and
        ((-not [string]::IsNullOrEmpty($PSBoundParameters.EnableSystemTypeConfigurationManager)) -or
        (-not [string]::IsNullOrEmpty($PSBoundParameters.EnableSystemTypeServer)) -or
        (-not [string]::IsNullOrEmpty($PSBoundParameters.EnableSystemTypeWorkstation))))
    {
        Write-Warning -Message $script:localizedData.DisabledSettings
    }

    $testParams = @{
        CurrentValues = $state
        DesiredValues = $PSBoundParameters
        ValuesToCheck = @('EnableAutomaticClientPushInstallation','EnableSystemTypeConfigurationManager','EnableSystemTypeServer',
            'EnableSystemTypeWorkstation','InstallClientToDomainController','InstallationProperty')
    }

    $result = Test-DscParameterState @testParams -Verbose

    if ($Accounts -or $AccountsToInclude -or $AccountsToExclude)
    {
        $clientPushArray = @{
            Match        = $Accounts
            Include      = $AccountsToInclude
            Exclude      = $AccountsToExclude
            CurrentState = $state.Accounts
        }

        $clientCompare = Compare-MultipleCompares @clientPushArray

        if ($clientCompare.Missing)
        {
            Write-Verbose -Message ($script:localizedData.AccountsMissing -f ($clientCompare.Missing | Out-String))
            $result = $false
        }

        if ($clientCompare.Remove)
        {
            Write-Verbose -Message ($script:localizedData.AccountsExtra -f ($clientCompare.Remove | Out-String))
            $result = $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
