$script:dscResourceCommonPath = Join-Path (Join-Path -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $PsScriptRoot)) -ChildPath Modules) -ChildPath DscResource.Common
$script:configMgrResourcehelper = Join-Path (Join-Path -Path (Split-Path -Parent -Path (Split-Path -Parent -Path $PsScriptRoot)) -ChildPath Modules) -ChildPath ConfigMgrCBDsc.ResourceHelper

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode
    )

    Write-Verbose -Message $script:localizedData.RetrieveSettingValue
    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    $distroComponent = Get-CMSoftwareDistributionComponent -SiteCode $SiteCode
    $distroSettings = ($distroComponent | Where-Object -FilterScript { $_.ComponentName -eq 'SMS_DISTRIBUTION_MANAGER' }).Props
    $distroMultis = ($distroComponent | Where-Object -FilterScript { $_.ComponentName -eq 'SMS_MULTICAST_SERVICE_POINT' }).Props

    foreach ($distroSetting in $distroSettings)
    {
        switch ($distroSetting.PropertyName)
        {
            'Thread Limit'         { $maxPackage = $distroSetting.Value }
            'Retry Delay'          { $delay = $distroSetting.Value }
            'Package Thread Limit' { $packageThread = $distroSetting.Value }
            'Number of Retries'    { $retry = $distroSetting.Value }
        }
    }

    foreach ($distroMulti in $distroMultis)
    {
        switch ($distroMulti.PropertyName)
        {
            #Retry Delay is incrimented by 60. Using divide to set return value to the same as the input value for test\set compare.
            'Retry Delay'       { $multiDelay = $distroMulti.Value / 60 }
            'Number of Retries' { $multiRetry = $distroMulti.Value }
        }
    }

    [array]$accounts = (Get-CMAccount -SiteCode $SiteCode | Where-Object -FilterScript { $_.AccountUsage -contains 'Software Distribution' }).UserName

    if ([string]::IsNullOrEmpty($accounts))
    {
        $computerAccount = $true
    }
    else
    {
        $computerAccount = $false
    }

    return @{
        SiteCode                         = $SiteCode
        AccessAccounts                   = $accounts
        MaximumPackageCount              = $maxPackage
        MaximumThreadCountPerPackage     = $packageThread
        RetryCount                       = $retry
        DelayBeforeRetryingMins          = $delay
        MulticastRetryCount              = $multiRetry
        MulticastDelayBeforeRetryingMins = $multiDelay
        ClientComputerAccount            = $computerAccount
    }
}

<#
    .SYNOPSIS
        This will set the desired results.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER MaximumPackageCount
        Specifies a maximum number of packages for concurrent distribution.

    .PARAMETER MaximumThreadCountPerPackage
        Specifies a maximum thread count per package for concurrent distribution.

    .PARAMETER RetryCount
        Specifies the retry count for a package distribution.

    .PARAMETER DelayBeforeRetryingMins
        Specifies the retry delay, in minutes, for a failed package distribution.

    .PARAMETER MulticastRetryCount
        Specifies the retry count for a multicast distribution.

    .PARAMETER MulticastDelayBeforeRetryingMins
        Specifies the retry delay, in minutes, for a failed multicast distribution.

    .PARAMETER ClientComputerAccount
        Specifies if the computer account should be used instead of Network Access account.
        Note: Setting to true will remove all network access accounts.

    .PARAMETER AccessAccounts
        Specifies an array of accounts to exactly match for Network Access list with software distribution.
        If specifying an account the account must already exist in Configuration Manager.

    .PARAMETER AccessAccountsToInclude
        Specifies an array of accounts to add to the Network Access account list.
        If specifying an account the account must already exist in Configuration Manager.

    .PARAMETER AccessAccountsToExclude
        Specifies an array of accounts to exclude from the Network Access account list.
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
        [ValidateRange(1,50)]
        [UInt32]
        $MaximumPackageCount,

        [Parameter()]
        [ValidateRange(1,999)]
        [UInt32]
        $MaximumThreadCountPerPackage,

        [Parameter()]
        [ValidateRange(1,1000)]
        [UInt32]
        $RetryCount,

        [Parameter()]
        [ValidateRange(1,1440)]
        [UInt32]
        $DelayBeforeRetryingMins,

        [Parameter()]
        [ValidateRange(1,1000)]
        [UInt32]
        $MulticastRetryCount,

        [Parameter()]
        [ValidateRange(1,1440)]
        [UInt32]
        $MulticastDelayBeforeRetryingMins,

        [Parameter()]
        [Boolean]
        $ClientComputerAccount,

        [Parameter()]
        [String[]]
        $AccessAccounts,

        [Parameter()]
        [String[]]
        $AccessAccountsToInclude,

        [Parameter()]
        [String[]]
        $AccessAccountsToExclude
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"

    try
    {
        $state = Get-TargetResource -SiteCode $SiteCode

        if (($ClientComputerAccount -eq $true) -and
            ($PSBoundParameters.ContainsKey('AccessAccounts') -or
            $PSBoundParameters.ContainsKey('AccessAccountsToInclude')))
        {
            throw $script:localizedData.ComputerAccessAccount
        }
        elseif (($PSBoundParameters.ContainsKey('ClientComputerAccount') -and
                $ClientComputerAccount -eq $false) -and
                (([string]::IsNullOrEmpty($AccessAccounts) -and
                [string]::IsNullOrEmpty($AccessAccountsToInclude)) -and
                [string]::IsNullOrEmpty($state.AccessAccounts)))
        {
            throw $script:localizedData.AccountsFalse
        }

        if ($PSBoundParameters.ContainsKey('AccessAccounts'))
        {
            if ($PSBoundParameters.ContainsKey('AccessAccountsToInclude') -or
                $PSBoundParameters.ContainsKey('AccessAccountsToExclude'))
            {
                Write-Warning -Message $script:localizedData.ParamsError
            }
        }
        elseif (-not $PSBoundParameters.ContainsKey('AccessAccounts') -and
                $PSBoundParameters.ContainsKey('AccessAccountsToInclude') -and
                $PSBoundParameters.ContainsKey('AccessAccountsToExclude'))
        {
            foreach ($item in $AccessAccountsToInclude)
            {
                if ($AccessAccountsToExclude -contains $item)
                {
                    throw ($script:localizedData.AccessAccountsInEx -f $item)
                }
            }
        }

        $eval = @('MaximumPackageCount','MaximumThreadCountPerPackage','RetryCount','DelayBeforeRetryingMins',
                'MulticastRetryCount','MulticastDelayBeforeRetryingMins')

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            if ($eval -contains $param.key)
            {
                if ($param.Value -ne $state[$param.key])
                {
                    Write-Verbose -Message ($script:localizedData.ModifySetting -f $param.key, $param.Value)

                    $buildingParams += @{
                        $param.key = $param.Value
                    }
                }
            }
        }

        if (($ClientComputerAccount -eq $true) -and ($state.ClientComputerAccount -eq $false))
        {
            $buildingParams += @{
                ClientComputerAccount = $null
            }
        }

        if ($ClientComputerAccount -eq $false)
        {
            if ($AccessAccounts -or $AccessAccountsToInclude -or $AccessAccountsToExclude)
            {
                $accountsArray = @{
                    Match        = $AccessAccounts
                    Include      = $AccessAccountsToInclude
                    Exclude      = $AccessAccountsToExclude
                    CurrentState = $state.AccessAccounts
                }

                $accountCompare = Compare-MultipleCompares @accountsArray

                if ($accountCompare.Missing)
                {
                    $missingAccount = @()
                    foreach ($item in $accountCompare.Missing)
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

                    if ($missingAccount)
                    {
                        $buildingParams += @{
                            AddNetworkAccessAccountName = $missingAccount
                        }
                    }
                }

                if ($accountCompare.Remove)
                {
                    Write-Verbose -Message ($script:localizedData.CMAccountExtra -f ($accountCompare.Remove | Out-String))
                    $buildingParams += @{
                        RemoveNetworkAccessAccountName  = $accountCompare.Remove
                    }

                    if (($accountCompare.Remove.Count -eq $state.AccessAccounts.Count) -and ($accountCompare.Missing.Count -eq 0))
                    {
                        throw ($script:localizedData.AllAccountsRemoved)
                    }
                }
            }
        }

        if ($buildingParams)
        {
            Set-CMSoftwareDistributionComponent @buildingParams
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
        This will test the desired settings.

    .PARAMETER SiteCode
        Specifies the site code for Configuration Manager site.

    .PARAMETER MaximumPackageCount
        Specifies a maximum number of packages for concurrent distribution.

    .PARAMETER MaximumThreadCountPerPackage
        Specifies a maximum thread count per package for concurrent distribution.

    .PARAMETER RetryCount
        Specifies the retry count for a package distribution.

    .PARAMETER DelayBeforeRetryingMins
        Specifies the retry delay, in minutes, for a failed package distribution.

    .PARAMETER MulticastRetryCount
        Specifies the retry count for a multicast distribution.

    .PARAMETER MulticastDelayBeforeRetryingMins
        Specifies the retry delay, in minutes, for a failed multicast distribution.

    .PARAMETER ClientComputerAccount
        Specifies if the computer account should be used instead of Network Access account.
        Note: Setting to true will remove all network access accounts.

    .PARAMETER AccessAccounts
        Specifies an array of accounts to exactly match for Network Access list with software distribution.
        If specifying an account the account must already exist in Configuration Manager.

    .PARAMETER AccessAccountsToInclude
        Specifies an array of accounts to add to the Network Access account list.
        If specifying an account the account must already exist in Configuration Manager.

    .PARAMETER AccessAccountsToExclude
        Specifies an array of accounts to exclude from the Network Access account list.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter()]
        [ValidateRange(1,50)]
        [UInt32]
        $MaximumPackageCount,

        [Parameter()]
        [ValidateRange(1,999)]
        [UInt32]
        $MaximumThreadCountPerPackage,

        [Parameter()]
        [ValidateRange(1,1000)]
        [UInt32]
        $RetryCount,

        [Parameter()]
        [ValidateRange(1,1440)]
        [UInt32]
        $DelayBeforeRetryingMins,

        [Parameter()]
        [ValidateRange(1,1000)]
        [UInt32]
        $MulticastRetryCount,

        [Parameter()]
        [ValidateRange(1,1440)]
        [UInt32]
        $MulticastDelayBeforeRetryingMins,

        [Parameter()]
        [Boolean]
        $ClientComputerAccount,

        [Parameter()]
        [String[]]
        $AccessAccounts,

        [Parameter()]
        [String[]]
        $AccessAccountsToInclude,

        [Parameter()]
        [String[]]
        $AccessAccountsToExclude
    )

    Import-ConfigMgrPowerShellModule -SiteCode $SiteCode
    Set-Location -Path "$($SiteCode):\"
    $state = Get-TargetResource -SiteCode $SiteCode
    $result = $true

    if (($ClientComputerAccount -eq $true) -and
        ($PSBoundParameters.ContainsKey('AccessAccounts') -or
        $PSBoundParameters.ContainsKey('AccessAccountsToInclude')))
    {
        Write-Warning -Message $script:localizedData.ComputerAccessAccount
    }
    elseif (($PSBoundParameters.ContainsKey('ClientComputerAccount') -and
            $ClientComputerAccount -eq $false) -and
            (([string]::IsNullOrEmpty($AccessAccounts) -and
            [string]::IsNullOrEmpty($AccessAccountsToInclude)) -and
            [string]::IsNullOrEmpty($state.AccessAccounts)))
    {
        Write-Warning -Message $script:localizedData.AccountsFalse
    }

    if ($PSBoundParameters.ContainsKey('AccessAccounts'))
    {
        if ($PSBoundParameters.ContainsKey('AccessAccountsToInclude') -or
            $PSBoundParameters.ContainsKey('AccessAccountsToExclude'))
        {
            Write-Warning -Message $script:localizedData.ParamIgnore
        }
    }
    elseif (-not $PSBoundParameters.ContainsKey('AccessAccounts') -and
            $PSBoundParameters.ContainsKey('AccessAccountsToInclude') -and
            $PSBoundParameters.ContainsKey('AccessAccountsToExclude'))
    {
        foreach ($item in $AccessAccountsToInclude)
        {
            if ($AccessAccountsToExclude -contains $item)
            {
                Write-Warning -Message ($script:localizedData.AccessAccountsInEx -f $item)
                $result = $false
            }
        }
    }

    $testParams = @{
        CurrentValues = $state
        DesiredValues = $PSBoundParameters
        ValuesToCheck = @('MaximumPackageCount','MaximumThreadCountPerPackage','RetryCount',
            'DelayBeforeRetryingMins','MulticastRetryCount','MulticastDelayBeforeRetryingMins','ClientComputerAccount')
    }

    $result = Test-DscParameterState @testParams -TurnOffTypeChecking -Verbose

    if ($ClientComputerAccount -eq $false)
    {
        if ($AccessAccounts -or $AccessAccountsToInclude -or $AccessAccountsToExclude)
        {
            $accountsArray = @{
                Match        = $AccessAccounts
                Include      = $AccessAccountsToInclude
                Exclude      = $AccessAccountsToExclude
                CurrentState = $state.AccessAccounts
            }

            $accountCompare = Compare-MultipleCompares @accountsArray

            if ($accountCompare.Missing)
            {
                Write-Verbose -Message ($script:localizedData.CMAccountMissing -f ($accountCompare.Missing | Out-String))
                $result = $false
            }

            if ($accountCompare.Remove)
            {
                Write-Verbose -Message ($script:localizedData.CMAccountExtra -f ($accountCompare.Remove | Out-String))
                $result = $false

                if (($accountCompare.Remove.Count -eq $state.AccessAccounts.Count) -and ($accountCompare.Missing.Count -eq 0))
                {
                    Write-Warning -Message ($script:localizedData.AllAccountsRemoved)
                }
            }
        }
    }

    Write-Verbose -Message ($script:localizedData.TestState -f $result)
    Set-Location -Path "$env:temp"
    return $result
}

Export-ModuleMember -Function *-TargetResource
