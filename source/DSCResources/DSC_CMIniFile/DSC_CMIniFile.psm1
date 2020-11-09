$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:configMgrResourcehelper

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return the current state of the resource.

    .PARAMETER IniFilename
        Specifies the ini file name.

    .PARAMETER IniFilePath
        Specifies the path of the ini file.

    .PARAMETER Action
        Specifies whether to install a CAS or Primary.

    .PARAMETER CDLatest
        This value informs setup that you're using media from CD.Latest.

    .PARAMETER ProductID
        Specifies the Configuration Manager installation product key, including the dashes.

    .PARAMETER SiteCode
        Specifies three alphanumeric characters that uniquely identify the site in your hierarchy.

    .PARAMETER SiteName
        Specifies the name for this site.

    .PARAMETER SMSInstallDir
        Specifies the installation folder for the Configuration Manager program files.

    .PARAMETER SDKServer
        Specifies the FQDN for the server that will host the SMS Provider.

    .PARAMETER PreRequisiteComp
        Specifies whether setup prerequisite files have already been downloaded.

    .PARAMETER PreRequisitePath
        Specifies the path to the setup prerequisite files.

    .PARAMETER AdminConsole
        Specifies whether to install the Configuration Manager console.

    .PARAMETER JoinCeip
        Specifies whether to join the Customer Experience Improvement Program (CEIP).

    .PARAMETER MobileDeviceLanguage
        Specifies whether the mobile device client languages are installed.

    .PARAMETER RoleCommunicationProtocol
        Specifies whether to configure all site systems to accept only HTTPS communication from clients,
        or to configure the communication method for each site system role.

    .PARAMETER ClientsUsePKICertificate
        Specifies whether clients will use a client PKI certificate to communicate with site system roles.

    .PARAMETER ManagementPoint
        Specifies the FQDN of the server that will host the management point site system role.

    .PARAMETER ManagementPointProtocol
        Specifies the protocol to use for the management point.

    .PARAMETER DistributionPoint
        Specifies the FQDN of the server that will host the distribution point site system role.

    .PARAMETER DistributionPointProtocol
        Specifies the protocol to use for the distribution point.

    .PARAMETER DistributionPointInstallIis
        Specifies whether to install the IIS features when installing the Distribution Point.

    .PARAMETER AddServerLanguages
        Specifies the server languages that will be available for the Configuration Manager console, reports,
        and Configuration Manager objects.

    .PARAMETER AddClientLanguages
        Specifies the languages that will be available to client computers.

    .PARAMETER DeleteServerLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be
        available for the Configuration Manager console, reports, and Configuration Manager objects.

    .PARAMETER DeleteClientLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be
        available to client computers.

    .PARAMETER SQLServerName
        Specifies the name of the server or clustered instance that's running SQL Server to host the site database.

    .PARAMETER DatabaseName
        Specifies the name of the SQL Server database to create, or the SQL Server database to use, when setup
        installs the CAS database. This can also include the instance, instance\<databasename>.

    .PARAMETER SqlSsbPort
        Specifies the SQL Server Service Broker (SSB) port that SQL Server uses.

    .PARAMETER SQLDataFilePath
        Specifies an alternate location to create the database .mdb file.

    .PARAMETER SQLLogFilePath
        Specifies an alternate location to create the database .ldf file.

    .PARAMETER CCARSiteServer
        Specifies the CAS that a primary site attaches to when it joins the Configuration Manager hierarchy.

    .PARAMETER CasRetryInterval
        Specifies the retry interval in minutes to attempt a connection to the CAS after the connection fails.

    .PARAMETER WaitForCasTimeout
        Specifies the maximum timeout value in minutes for a primary site to connect to the CAS.

    .PARAMETER CloudConnector
        Specifies whether to install a service connection point at this site.

    .PARAMETER CloudConnectorServer
        Specifies the FQDN of the server that will host the service connection point site system role.

    .PARAMETER UseProxy
        Specifies whether the service connection point uses a proxy server.

    .PARAMETER ProxyName
        Specifies the FQDN of the proxy server that the service connection point uses.

    .PARAMETER ProxyPort
        Specifies the port number to use for the proxy port.

    .PARAMETER SAActive
        Specify if you have active Software Assurance.

    .PARAMETER CurrentBranch
        Specify whether to use Configuration Manager current branch or long-term servicing branch (LTSB).
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $IniFilename,

        [Parameter(Mandatory = $true)]
        [String]
        $IniFilePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('InstallCAS', 'InstallPrimarySite')]
        [String]
        $Action,

        [Parameter()]
        [Boolean]
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
        [ValidateSet('EnforceHTTPS','HTTPorHTTPS')]
        [String]
        $RoleCommunicationProtocol,

        [Parameter()]
        [Boolean]
        $ClientsUsePKICertificate,

        [Parameter()]
        [String]
        $ManagementPoint,

        [Parameter()]
        [ValidateSet('HTTPS','HTTP')]
        [String]
        $ManagementPointProtocol,

        [Parameter()]
        [String]
        $DistributionPoint,

        [Parameter()]
        [ValidateSet('HTTPS','HTTP')]
        [String]
        $DistributionPointProtocol,

        [Parameter()]
        [Boolean]
        $DistributionPointInstallIis,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $AddServerLanguages,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $AddClientLanguages,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $DeleteServerLanguages,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $DeleteClientLanguages,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter()]
        [UInt16]
        $SqlSsbPort,

        [Parameter()]
        [String]
        $SQLDataFilePath,

        [Parameter()]
        [String]
        $SQLLogFilePath,

        [Parameter()]
        [String]
        $CCARSiteServer,

        [Parameter()]
        [String]
        $CasRetryInterval,

        [Parameter()]
        [ValidateRange(0, 100)]
        [uint16]
        $WaitForCasTimeout,

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
        [UInt16]
        $ProxyPort,

        [Parameter()]
        [Boolean]
        $SAActive,

        [Parameter()]
        [Boolean]
        $CurrentBranch
    )

    $IniFilePath = $IniFilePath.TrimEnd('\')
    Write-Verbose -Message ($script:localizedData.GettingFileContent -f $IniFilePath, $IniFilename)
    $iniContent = Get-Content -Path "$IniFilePath\$IniFilename" -ErrorAction SilentlyContinue

    $systemParameters = @('Verbose','Debug','ErrorAction','WarningAction','InformationAction','ErrorVariable',
        'WarningVariable','InformationVariable','OutVariable','OutBuffer','PipelineVariable')
    $testParameters = (Get-Command -Name 'Get-TargetResource').Parameters.values | Select-Object -Property  Name,ParameterType

    if ($iniContent)
    {
        $iniParameters = @{}
        foreach ($line in $iniContent)
        {
            if ($line -match '=')
            {
                $iniParameters += @{
                    (($line.split('=')[0]).Trim(' ')) = (($line.split('=')[1]).Trim(' '))
                }
            }
        }

        $getParameters = @{}
        foreach ($param in $testParameters)
        {
            if ($systemParameters -notcontains $param.Name)
            {
                if ($($iniParameters.$($param.Name)))
                {
                    Write-Verbose -Message ($script:localizedData.AddingParameter -f $($param.Name), $($iniParameters.$($param.Name)))
                    $getParameters.Add($($param.Name),$($iniParameters.$($param.Name)))
                }
                else
                {
                    Write-Verbose -Message ($script:localizedData.AddingParameter -f $($param.Name),$('$null'))
                    $getParameters.Add($($param.Name),$null)
                }
            }
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.MissingFileContent -f $IniFilePath, $IniFilename)
        Write-Verbose -Message $script:localizedData.GetPassParameters

        $getParameters = @{}
        foreach ($param in $testParameters)
        {
            if ($systemParameters -notcontains $param.Name)
            {
                if ($($PSBoundParameters.$($param.Name)))
                {
                    Write-Verbose -Message ($script:localizedData.GetParameterPrint -f $($param.Name), $($PSBoundParameters.$($param.Name)))
                    $getParameters.Add($($param.Name),$($PSBoundParameters.$($param.Name)))
                }
                else
                {
                    $getParameters.Add($($param.Name),$null)
                }
            }
        }
    }
   return $getParameters
} #end function Get-TargetResource

<#
    .SYNOPSIS
        This will return the current state of the resource.

    .PARAMETER IniFilename
        Specifies the ini file name.

    .PARAMETER IniFilePath
        Specifies the path of the ini file.

    .PARAMETER Action
        Specifies whether to install a CAS or Primary.

    .PARAMETER CDLatest
        This value informs setup that you're using media from CD.Latest.

    .PARAMETER ProductID
        Specifies the Configuration Manager installation product key, including the dashes.

    .PARAMETER SiteCode
        Specifies three alphanumeric characters that uniquely identify the site in your hierarchy.

    .PARAMETER SiteName
        Specifies the name for this site.

    .PARAMETER SMSInstallDir
        Specifies the installation folder for the Configuration Manager program files.

    .PARAMETER SDKServer
        Specifies the FQDN for the server that will host the SMS Provider.

    .PARAMETER PreRequisiteComp
        Specifies whether setup prerequisite files have already been downloaded.

    .PARAMETER PreRequisitePath
        Specifies the path to the setup prerequisite files.

    .PARAMETER AdminConsole
        Specifies whether to install the Configuration Manager console.

    .PARAMETER JoinCeip
        Specifies whether to join the Customer Experience Improvement Program (CEIP).

    .PARAMETER MobileDeviceLanguage
        Specifies whether the mobile device client languages are installed.

    .PARAMETER RoleCommunicationProtocol
        Specifies whether to configure all site systems to accept only HTTPS communication from clients,
        or to configure the communication method for each site system role.

    .PARAMETER ClientsUsePKICertificate
        Specifies whether clients will use a client PKI certificate to communicate with site system roles.

    .PARAMETER ManagementPoint
        Specifies the FQDN of the server that will host the management point site system role.

    .PARAMETER ManagementPointProtocol
        Specifies the protocol to use for the management point.

    .PARAMETER DistributionPoint
        Specifies the FQDN of the server that will host the distribution point site system role.

    .PARAMETER DistributionPointProtocol
        Specifies the protocol to use for the distribution point.

    .PARAMETER DistributionPointInstallIis
        Specifies whether to install the IIS features when installing the Distribution Point.

    .PARAMETER AddServerLanguages
        Specifies the server languages that will be available for the Configuration Manager console, reports,
        and Configuration Manager objects.

    .PARAMETER AddClientLanguages
        Specifies the languages that will be available to client computers.

    .PARAMETER DeleteServerLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be
        available for the Configuration Manager console, reports, and Configuration Manager objects.

    .PARAMETER DeleteClientLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be
        available to client computers.

    .PARAMETER SQLServerName
        Specifies the name of the server or clustered instance that's running SQL Server to host the site database.

    .PARAMETER DatabaseName
        Specifies the name of the SQL Server database to create, or the SQL Server database to use, when setup
        installs the CAS database. This can also include the instance, instance\<databasename>.

    .PARAMETER SqlSsbPort
        Specifies the SQL Server Service Broker (SSB) port that SQL Server uses.

    .PARAMETER SQLDataFilePath
        Specifies an alternate location to create the database .mdb file.

    .PARAMETER SQLLogFilePath
        Specifies an alternate location to create the database .ldf file.

    .PARAMETER CCARSiteServer
        Specifies the CAS that a primary site attaches to when it joins the Configuration Manager hierarchy.

    .PARAMETER CasRetryInterval
        Specifies the retry interval in minutes to attempt a connection to the CAS after the connection fails.

    .PARAMETER WaitForCasTimeout
        Specifies the maximum timeout value in minutes for a primary site to connect to the CAS.

    .PARAMETER CloudConnector
        Specifies whether to install a service connection point at this site.

    .PARAMETER CloudConnectorServer
        Specifies the FQDN of the server that will host the service connection point site system role.

    .PARAMETER UseProxy
        Specifies whether the service connection point uses a proxy server.

    .PARAMETER ProxyName
        Specifies the FQDN of the proxy server that the service connection point uses.

    .PARAMETER ProxyPort
        Specifies the port number to use for the proxy port.

    .PARAMETER SAActive
        Specify if you have active Software Assurance.

    .PARAMETER CurrentBranch
        Specify whether to use Configuration Manager current branch or long-term servicing branch (LTSB).
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $IniFilename,

        [Parameter(Mandatory = $true)]
        [String]
        $IniFilePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('InstallCAS', 'InstallPrimarySite')]
        [String]
        $Action,

        [Parameter()]
        [Boolean]
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
        [ValidateSet('EnforceHTTPS','HTTPorHTTPS')]
        [String]
        $RoleCommunicationProtocol,

        [Parameter()]
        [Boolean]
        $ClientsUsePKICertificate,

        [Parameter()]
        [String]
        $ManagementPoint,

        [Parameter()]
        [ValidateSet('HTTPS','HTTP')]
        [String]
        $ManagementPointProtocol,

        [Parameter()]
        [String]
        $DistributionPoint,

        [Parameter()]
        [ValidateSet('HTTPS','HTTP')]
        [String]
        $DistributionPointProtocol,

        [Parameter()]
        [Boolean]
        $DistributionPointInstallIis,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $AddServerLanguages,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $AddClientLanguages,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $DeleteServerLanguages,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $DeleteClientLanguages,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter()]
        [UInt16]
        $SqlSsbPort,

        [Parameter()]
        [String]
        $SQLDataFilePath,

        [Parameter()]
        [String]
        $SQLLogFilePath,

        [Parameter()]
        [String]
        $CCARSiteServer,

        [Parameter()]
        [String]
        $CasRetryInterval,

        [Parameter()]
        [ValidateRange(0, 100)]
        [uint16]
        $WaitForCasTimeout,

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
        [UInt16]
        $ProxyPort,

        [Parameter()]
        [Boolean]
        $SAActive,

        [Parameter()]
        [Boolean]
        $CurrentBranch
    )

    $IniFilePath = $IniFilePath.TrimEnd('\')

    # Check for mandatory parameters for specific scenarios
    if (($ManagementPoint -or $ManagementPointProtocol -or -$DistributionPoint -or $DistributionPointProtocol -or
        $RoleCommunicationProtocol -or $ClientsUsePKICertificate -or $CCARSiteServer -or $CASRetryInterval -or
        $WaitForCASTimeout) -and $Action -ne 'InstallPrimarySite')
    {
        throw $script:localizedData.PrimaryParameterError
    }
    elseif ($CloudConnector -eq $true -and ([string]::IsNullOrEmpty($CloudConnectorServer) -or ($UseProxy -or $UseProxy -eq $false)))
    {
        throw $script:localizedData.CloudConnectorError
    }
    elseif ($UseProxy -eq $true -and ([string]::IsNullOrEmpty($ProxyName) -or [string]::IsNullOrEmpty($ProxyPort)))
    {
        throw $script:localizedData.ProxyError
    }
    elseif ($DistributionPoint -and (-not $DistributionPointInstallIis))
    {
        throw $script:localizedData.DistributionPointError
    }

    $identification = @{
        Title    = '[Identification]'
        Action   = ''
        CDLatest = ''
    }
    $options = @{
        Title                       = '[Options]'
        ProductID                   = ''
        SiteCode                    = ''
        SiteName                    = ''
        SMSInstallDir               = ''
        SDKServer                   = ''
        PrerequisiteComp            = ''
        PrerequisitePath            = ''
        AdminConsole                = ''
        JoinCEIP                    = ''
        MobileDeviceLanguage        = ''
        RoleCommunicationProtocol   = ''
        ClientsUsePKICertificate    = ''
        ManagementPoint             = ''
        ManagementPointProtocol     = ''
        DistributionPoint           = ''
        DistributionPointProtocol   = ''
        DistributionPointInstallIis = ''
        AddServerLanguages          = ''
        AddClientLanguages          = ''
        DeleteServerLanguages       = ''
        DeleteClientLanguages       = ''
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

    $configOptions = @($Identification,$options,$sqlConfigOptions,$hierarchyExpansionOption,
        $cloudConnectorOptions,$saBranchOptions)

    Write-Verbose -Message $script:localizedData.WritingParameter
    foreach ($configOption in $configOptions)
    {
        $outputIni += "$($configOption.Title) `r`n"
        $configOption.Remove('Title')
        foreach ($param in $configOption)
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
                    Write-Verbose -Message ($script:localizedData.AddingParameter -f $($item.Key), $newValue)
                    $outputIni += "$($item.Key)=$newValue`r`n"
                }
                elseif ($PSBoundParameters.$($item.Name))
                {
                    Write-Verbose -Message ($script:localizedData.AddingParameter -f $($item.Key), $($PSBoundParameters.$($item.Name)))
                    $outputIni += "$($item.Key)=$($PSBoundParameters.$($item.Name))`r`n"
                }
            }
        }
        $outputIni += "`r`n"
    }
    Write-Verbose -Message ($script:localizedData.ExportingFile -f $IniFilePath, $IniFilename)
    $outputIni | Out-File -FilePath "$IniFilePath\$IniFilename" -Force
} #end function Set-TargetResource

<#
    .SYNOPSIS
        This will return the current state of the resource.

    .PARAMETER IniFilename
        Specifies the ini file name.

    .PARAMETER IniFilePath
        Specifies the path of the ini file.

    .PARAMETER Action
        Specifies whether to install a CAS or Primary.

    .PARAMETER CDLatest
        This value informs setup that you're using media from CD.Latest.

    .PARAMETER ProductID
        Specifies the Configuration Manager installation product key, including the dashes.

    .PARAMETER SiteCode
        Specifies three alphanumeric characters that uniquely identify the site in your hierarchy.

    .PARAMETER SiteName
        Specifies the name for this site.

    .PARAMETER SMSInstallDir
        Specifies the installation folder for the Configuration Manager program files.

    .PARAMETER SDKServer
        Specifies the FQDN for the server that will host the SMS Provider.

    .PARAMETER PreRequisiteComp
        Specifies whether setup prerequisite files have already been downloaded.

    .PARAMETER PreRequisitePath
        Specifies the path to the setup prerequisite files.

    .PARAMETER AdminConsole
        Specifies whether to install the Configuration Manager console.

    .PARAMETER JoinCeip
        Specifies whether to join the Customer Experience Improvement Program (CEIP).

    .PARAMETER MobileDeviceLanguage
        Specifies whether the mobile device client languages are installed.

    .PARAMETER RoleCommunicationProtocol
        Specifies whether to configure all site systems to accept only HTTPS communication from clients,
        or to configure the communication method for each site system role.

    .PARAMETER ClientsUsePKICertificate
        Specifies whether clients will use a client PKI certificate to communicate with site system roles.

    .PARAMETER ManagementPoint
        Specifies the FQDN of the server that will host the management point site system role.

    .PARAMETER ManagementPointProtocol
        Specifies the protocol to use for the management point.

    .PARAMETER DistributionPoint
        Specifies the FQDN of the server that will host the distribution point site system role.

    .PARAMETER DistributionPointProtocol
        Specifies the protocol to use for the distribution point.

    .PARAMETER DistributionPointInstallIis
        Specifies whether to install the IIS features when installing the Distribution Point.

    .PARAMETER AddServerLanguages
        Specifies the server languages that will be available for the Configuration Manager console, reports,
        and Configuration Manager objects.

    .PARAMETER AddClientLanguages
        Specifies the languages that will be available to client computers.

    .PARAMETER DeleteServerLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be
        available for the Configuration Manager console, reports, and Configuration Manager objects.

    .PARAMETER DeleteClientLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be
        available to client computers.

    .PARAMETER SQLServerName
        Specifies the name of the server or clustered instance that's running SQL Server to host the site database.

    .PARAMETER DatabaseName
        Specifies the name of the SQL Server database to create, or the SQL Server database to use, when setup
        installs the CAS database. This can also include the instance, instance\<databasename>.

    .PARAMETER SqlSsbPort
        Specifies the SQL Server Service Broker (SSB) port that SQL Server uses.

    .PARAMETER SQLDataFilePath
        Specifies an alternate location to create the database .mdb file.

    .PARAMETER SQLLogFilePath
        Specifies an alternate location to create the database .ldf file.

    .PARAMETER CCARSiteServer
        Specifies the CAS that a primary site attaches to when it joins the Configuration Manager hierarchy.

    .PARAMETER CasRetryInterval
        Specifies the retry interval in minutes to attempt a connection to the CAS after the connection fails.

    .PARAMETER WaitForCasTimeout
        Specifies the maximum timeout value in minutes for a primary site to connect to the CAS.

    .PARAMETER CloudConnector
        Specifies whether to install a service connection point at this site.

    .PARAMETER CloudConnectorServer
        Specifies the FQDN of the server that will host the service connection point site system role.

    .PARAMETER UseProxy
        Specifies whether the service connection point uses a proxy server.

    .PARAMETER ProxyName
        Specifies the FQDN of the proxy server that the service connection point uses.

    .PARAMETER ProxyPort
        Specifies the port number to use for the proxy port.

    .PARAMETER SAActive
        Specify if you have active Software Assurance.

    .PARAMETER CurrentBranch
        Specify whether to use Configuration Manager current branch or long-term servicing branch (LTSB).
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $IniFilename,

        [Parameter(Mandatory = $true)]
        [String]
        $IniFilePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('InstallCAS', 'InstallPrimarySite')]
        [String]
        $Action,

        [Parameter()]
        [Boolean]
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
        [ValidateSet('EnforceHTTPS','HTTPorHTTPS')]
        [String]
        $RoleCommunicationProtocol,

        [Parameter()]
        [Boolean]
        $ClientsUsePKICertificate,

        [Parameter()]
        [String]
        $ManagementPoint,

        [Parameter()]
        [ValidateSet('HTTPS','HTTP')]
        [String]
        $ManagementPointProtocol,

        [Parameter()]
        [String]
        $DistributionPoint,

        [Parameter()]
        [ValidateSet('HTTPS','HTTP')]
        [String]
        $DistributionPointProtocol,

        [Parameter()]
        [Boolean]
        $DistributionPointInstallIis,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $AddServerLanguages,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $AddClientLanguages,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $DeleteServerLanguages,

        [Parameter()]
        [ValidateSet('DEU','FRA','RUS','CHS','JPN','CHT','CSY','ESN','HUN','ITA','KOR','NLD','PLK','PTB','PTG','SVE','TRK','ZHH')]
        [String]
        $DeleteClientLanguages,

        [Parameter(Mandatory = $true)]
        [String]
        $SQLServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter()]
        [UInt16]
        $SqlSsbPort,

        [Parameter()]
        [String]
        $SQLDataFilePath,

        [Parameter()]
        [String]
        $SQLLogFilePath,

        [Parameter()]
        [String]
        $CCARSiteServer,

        [Parameter()]
        [String]
        $CasRetryInterval,

        [Parameter()]
        [ValidateRange(0, 100)]
        [uint16]
        $WaitForCasTimeout,

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
        [UInt16]
        $ProxyPort,

        [Parameter()]
        [Boolean]
        $SAActive,

        [Parameter()]
        [Boolean]
        $CurrentBranch
    )

    $IniFilePath = $IniFilePath.TrimEnd('\')
    Write-Verbose -Message ($script:localizedData.InDesiredStateMessage -f $IniFilePath,$IniFilename)
    $iniContent = Get-Content -Path "$IniFilePath\$IniFilename" -ErrorAction SilentlyContinue
    $result = $true

    if ($DistributionPoint -and (-not $DistributionPointInstallIis))
    {
        Write-Warning -Message $script:localizedData.DistributionPointError
    }

    if ($iniContent)
    {
        foreach ($line in $iniContent)
        {
            if ($line -match '=')
            {
                $iniParameters += @{
                    (($line.split('=')[0]).Trim(' ')) = (($line.split('=')[1]).Trim(' '))
                }
            }
        }

        $systemParameters = @('Verbose','Debug','ErrorAction','WarningAction','InformationAction','ErrorVariable',
            'WarningVariable','InformationVariable','OutVariable','OutBuffer','PipelineVariable'
        )
        $PSBoundParameters.Remove('IniFilePath') | Out-Null
        $PSBoundParameters.Remove('IniFilename') | Out-Null

        foreach ($param in $PSBoundParameters.GetEnumerator())
        {
            switch ($param.Value)
            {
                $true   {$newValue = 1}
                $false  {$newValue = 0}
                default {$newValue = $param.Value}
            }
            if ($iniParameters.$($param.Key) -and $iniParameters.$($param.Key) -ne $newValue)
            {
                Write-Verbose -Message ($script:localizedData.TestNoMatch -f $($param.Key), $($iniParameters.$($param.Key)), $newValue)
                $result = $false
            }
            elseif (-not $iniParameters.$($param.Key) -and $systemParameters -notcontains $param.Key)
            {
                Write-Verbose -Message ($script:localizedData.TestNoMatch -f $($param.Key), $('$null'), $newValue)
                $result = $false
            }
            elseif ($iniParameters.$($param.Key) -and $iniParameters.$($param.Key) -eq $newValue)
            {
                Write-Verbose -Message ($script:localizedData.TestMatch -f $($param.Key), $($iniParameters.$($param.Key)), $newValue)
            }
        }
    }
    else
    {
        $result = $false
    }

    if ($result)
    {
        Write-Verbose -Message $script:localizedData.InDesiredStateMessage
    }
    else
    {
        Write-Verbose -Message $script:localizedData.NotInDesiredStateMessage
    }

    return $result
} #end function Test-TargetResource

Export-ModuleMember -Function *-TargetResource
