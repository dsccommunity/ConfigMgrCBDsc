$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the CRL Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath -ChildPath (Join-Path -Path 'ConfigMgrCBDsc.ResourceHelper' -ChildPath 'ConfigMgrCBDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'CMAccounts' -ResourcePath (Split-Path -Parent $script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER SiteCode
        Specifies the SiteCode for the Configuration Manager site.

    .PARAMETER Name
        Specifies the display name of the client setting package.

    .PARAMETER DeviceSettingName
        Specifies the parent setting category.

    .PARAMETER Setting
        Specifies the client setting to validate.

    .PARAMETER SettingValue
        Specifies the value for the setting.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $IniFileName,

        [Parameter(Mandatory = $true)]
        [String]
        $IniFilePath,

        [Parameter(Mandatory = $true)]
        [String]
        $Action,

        [Parameter()]
        [String]
        $CDLatest,

        [Parameter(Mandatory = $true)]
        [String]
        $ProductID,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteName,

        [Parameter(Mandatory = $true)]
        [String]
        $SMSInstallDir,

        [Parameter(Mandatory = $true)]
        [String]
        $SDKServer,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $PreRequisiteComp,

        [Parameter(Mandatory = $true)]
        [String]
        $PreRequisitePath,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $AdminConsole,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $JoinCeip,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $MobileDeviceLanguage,

        [Parameter()]
        [String]
        $RoleCommunicationProtocol,

        [Parameter()]
        [Boolean]
        $ClientsUsePKICertificate,

        [Parameter()]
        [String]
        $ManagementPoint,

        [Parameter()]
        [String]
        $ManagementPointProtocol,

        [Parameter()]
        [String]
        $DistributionPoint,

        [Parameter()]
        [String]
        $DistributionPointProtocol,

        [Parameter()]
        [String]
        $AddServerLanguages,

        [Parameter()]
        [String]
        $AddClientLanguages,

        [Parameter()]
        [String]
        $DeleteServerLanguages,

        [Parameter()]
        [String]
        $DeleteClientLanguages,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter()]
        [String]
        $SqlSsbPort,

        [Parameter()]
        [String]
        $SQLDataFilePath,

        [Parameter()]
        [String]
        $SQLLogFilePath,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $CloudConnector,

        [Parameter()]
        [String]
        $CloudConnectorServer,

        [Parameter()]
        [Boolean]
        $UseProxy,

        [Parameter()]
        [String]
        $ProxyName,

        [Parameter()]
        [String]
        $ProxyPort,

        [Parameter()]
        [Boolean]
        $SAActive,

        [Parameter()]
        [Boolean]
        $CurrentBranch
    )

    Write-Verbose "Getting file content of $IniFilePath\$IniFileName"
    $iniContent = Get-Content -Path  "$IniFilePath\$IniFileName" -ErrorAction SilentlyContinue

    $systemParameters = @('Verbose','Debug','ErrorAction','WarningAction','InformationAction','ErrorVariable','WarningVariable','InformationVariable','OutVariable','OutBuffer','PipelineVariable')
    $Testparameters = (Get-Command -Name 'Get-TargetResource').Parameters.values | Select-Object -Property  Name,ParameterType

    if ($iniContent)
    {
        $iniParameters = @{}
        foreach ($line in $iniContent)
        {
            if ($line -match '=')
            {
                $iniParameters += @{$line.split('=')[0] = $line.split('=')[1]}
            }
        }

        $getParameters = @{}
        foreach ($param in $testParameters)
        {
            if ($systemParameters -notcontains $param.Name)
            {
                if ($($iniParameters.$($param.Name)))
                {
                    $getParameters.Add($($param.Name),$($iniParameters.$($param.Name)))
                }
                else
                {
                    $getParameters.Add($($param.Name),$null)
                }
            }
        }

        $getParameters.Add($($param.Name),'Present')
    }
    else
    {
        Write-Verbose "Could not find $IniFilePath\$IniFileName. "

        $getParameters = @{}
        foreach ($param in $testParameters)
        {
            if ($systemParameters -notcontains $param.Name)
            {
                if ($($PSBoundParameters.$($param.Name)))
                {
                    $getParameters.Add($($param.Name),$($PSBoundParameters.$($param.Name)))
                }
                else
                {
                    $getParameters.Add($($param.Name),$null)
                }
            }
        }

        $getParameters.Add($($param.Name),'Absent')
    }
   return $getParameters
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $IniFileName,

        [Parameter(Mandatory = $true)]
        [String]
        $IniFilePath,

        [Parameter(Mandatory = $true)]
        [String]
        $Action,

        [Parameter()]
        [String]
        $CDLatest,

        [Parameter(Mandatory = $true)]
        [String]
        $ProductID,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteName,

        [Parameter(Mandatory = $true)]
        [String]
        $SMSInstallDir,

        [Parameter(Mandatory = $true)]
        [String]
        $SDKServer,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $PreRequisiteComp,

        [Parameter(Mandatory = $true)]
        [String]
        $PreRequisitePath,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $AdminConsole,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $JoinCeip,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $MobileDeviceLanguage,

        [Parameter()]
        [String]
        $RoleCommunicationProtocol,

        [Parameter()]
        [Boolean]
        $ClientsUsePKICertificate,

        [Parameter()]
        [String]
        $ManagementPoint,

        [Parameter()]
        [String]
        $ManagementPointProtocol,

        [Parameter()]
        [String]
        $DistributionPoint,

        [Parameter()]
        [String]
        $DistributionPointProtocol,

        [Parameter()]
        [String]
        $AddServerLanguages,

        [Parameter()]
        [String]
        $AddClientLanguages,

        [Parameter()]
        [String]
        $DeleteServerLanguages,

        [Parameter()]
        [String]
        $DeleteClientLanguages,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter()]
        [String]
        $SqlSsbPort,

        [Parameter()]
        [String]
        $SQLDataFilePath,

        [Parameter()]
        [String]
        $SQLLogFilePath,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $CloudConnector,

        [Parameter()]
        [String]
        $CloudConnectorServer,

        [Parameter()]
        [Boolean]
        $UseProxy,

        [Parameter()]
        [String]
        $ProxyName,

        [Parameter()]
        [String]
        $ProxyPort,

        [Parameter()]
        [Boolean]
        $SAActive,

        [Parameter()]
        [Boolean]
        $CurrentBranch
    )

    $identification = @{
        Title = '[Identification]'
        Action = ''
        CDLatest = ''
    }
    $options = @{
        Title                     = '[Options]'
        ProductID                 = ''
        SiteCode                  = ''
        SiteName                  = ''
        SMSInstallDir             = ''
        SDKServer                 = ''
        PrerequisiteComp          = ''
        PrerequisitePath          = ''
        AdminConsole              = ''
        JoinCEIP                  = ''
        MobileDeviceLanguage      = ''
        RoleCommunicationProtocol = ''
        ClientsUsePKICertificate  = ''
        ManagementPoint           = ''
        ManagementPointProtocol   = ''
        DistributionPoint         = ''
        DistributionPointProtocol = ''
        AddServerLanguages        = ''
        AddClientLanguages        = ''
        DeleteServerLanguages     = ''
        DeleteClientLanguages     = ''
    }
    $sqlConfigOptions = @{
        Title           = '[SQLConfigOptions]'
        SQLServerName   = ''
        DatabaseName    = ''
        SQLSSBPort      = ''
        SQLDataFilePath = ''
        SQLLogFilePath  = ''
    }
    $hierarchyExpansionOption = @{
        Title             = '[HierarchyExpansionOption]'
        CCARSiteServer    = ''
        CASRetryInterval  = ''
        WaitForCASTimeout = ''
    }
    $cloudConnectorOptions = @{
        Title                ='[CloudConnectorOptions]'
        CloudConnector       = ''
        CloudConnectorServer = ''
        UseProxy             = ''
        ProxyName            = ''
        ProxyPort            = ''
    }
    $saBranchOptions = @{
        Title         = '[SABranchOptions]'
        SAActive      = ''
        CurrentBranch = ''
    }

    $configOptions = @($options,$sqlConfigOptions,$hierarchyExpansionOption,$cloudConnectorOptions,$saBranchOptions)

    foreach ($configOption in $configOptions)
    {
        $outputIni += "$($configOption.Title) `n"
        $configOption.Remove('Title')
        foreach($param in $configOption)
        {
            foreach ($item in $param.GetEnumerator())
            {
                if ($PSBoundParameters.$($item.Name) -is [Boolean])
                {
                    switch ($($PSBoundParameters.$($item.Name)))
                    {
                        $true  {$newValue = 1}
                        $false {$newValue = 0}
                    }
                    $outputIni += "$($item.Key)=$newValue`n"
                }
                elseif ($PSBoundParameters.$($item.Name))
                {
                    $outputIni += "$($item.Key)=$($PSBoundParameters.$($item.Name))`n"
                }
            }
        }
        $outputIni += "`n"
    }

    $outputIni | Out-File -FilePath "$IniFilePath\$IniFileName" -Force
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $IniFileName,

        [Parameter(Mandatory = $true)]
        [String]
        $IniFilePath,

        [Parameter(Mandatory = $true)]
        [String]
        $Action,

        [Parameter()]
        [String]
        $CDLatest,

        [Parameter(Mandatory = $true)]
        [String]
        $ProductID,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteCode,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteName,

        [Parameter(Mandatory = $true)]
        [String]
        $SMSInstallDir,

        [Parameter(Mandatory = $true)]
        [String]
        $SDKServer,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $PreRequisiteComp,

        [Parameter(Mandatory = $true)]
        [String]
        $PreRequisitePath,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $AdminConsole,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $JoinCeip,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $MobileDeviceLanguage,

        [Parameter()]
        [String]
        $RoleCommunicationProtocol,

        [Parameter()]
        [Boolean]
        $ClientsUsePKICertificate,

        [Parameter()]
        [String]
        $ManagementPoint,

        [Parameter()]
        [String]
        $ManagementPointProtocol,

        [Parameter()]
        [String]
        $DistributionPoint,

        [Parameter()]
        [String]
        $DistributionPointProtocol,

        [Parameter()]
        [String]
        $AddServerLanguages,

        [Parameter()]
        [String]
        $AddClientLanguages,

        [Parameter()]
        [String]
        $DeleteServerLanguages,

        [Parameter()]
        [String]
        $DeleteClientLanguages,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter()]
        [String]
        $SqlSsbPort,

        [Parameter()]
        [String]
        $SQLDataFilePath,

        [Parameter()]
        [String]
        $SQLLogFilePath,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $CloudConnector,

        [Parameter()]
        [String]
        $CloudConnectorServer,

        [Parameter()]
        [Boolean]
        $UseProxy,

        [Parameter()]
        [String]
        $ProxyName,

        [Parameter()]
        [String]
        $ProxyPort,

        [Parameter()]
        [Boolean]
        $SAActive,

        [Parameter()]
        [Boolean]
        $CurrentBranch
    )

    Write-Verbose "Getting file content of $IniFilePath\$IniFileName"
    $iniContent = Get-Content -Path  "$IniFilePath\$IniFileName" -ErrorAction SilentlyContinue
    $result = $true

    if ($iniContent)
    {
        foreach ($line in $iniContent)
        {
            if ($line -match '=')
            {
                $iniParameters += @{$line.split('=')[0] = $line.split('=')[1]}
            }

            $systemParameters = @('Verbose','Debug','ErrorAction','WarningAction','InformationAction','ErrorVariable','WarningVariable','InformationVariable','OutVariable','OutBuffer','PipelineVariable')

            foreach($param in $PSBoundParameters)
            {
                #$($PSBoundParameters.$($param.Name))
                if ($iniParameters.$($param.Name) -and $iniParameters.$($param.Name) -ne $param.Value)
                {
                    $result = $false
                }
                elseif (-not iniParameters.$($param.Name))
                {
                    $result = $false
                }
            }
        }

    }
    else {
        $result = $false
    }

    return $result
}