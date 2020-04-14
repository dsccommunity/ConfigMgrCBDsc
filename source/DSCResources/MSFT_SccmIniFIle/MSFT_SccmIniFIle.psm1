$script:configMgrResourcehelper = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\ConfigMgrCBDsc.ResourceHelper'

Import-Module -Name $script:configMgrResourcehelper

<#
    .SYNOPSIS
        This will return the current state of the resource.

    .PARAMETER IniFileName
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
        Specifies whether to configure all site systems to accept only HTTPS communication from clients, or to configure the communication method for each site system role.

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

    .PARAMETER AddServerLanguages
        Specifies the server languages that will be available for the Configuration Manager console, reports, and Configuration Manager objects.

    .PARAMETER AddClientLanguages
        Specifies the languages that will be available to client computers.

    .PARAMETER DeleteServerLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be available for the Configuration Manager console, reports, and Configuration Manager objects.

    .PARAMETER DeleteClientLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be available to client computers.

    .PARAMETER SQLServerName
        Specifies the name of the server or clustered instance that's running SQL Server to host the site database.

    .PARAMETER DatabaseName
        Specifies the name of the SQL Server database to create, or the SQL Server database to use, when setup installs the CAS database.

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
        $IniFileName,

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
        [String]
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
        [String]
        $ProxyPort,

        [Parameter()]
        [Boolean]
        $SAActive,

        [Parameter()]
        [Boolean]
        $CurrentBranch
    )

    $IniFilePath = $IniFilePath.TrimEnd('\')
    Write-Verbose "Getting file content of $IniFilePath\$IniFileName"
    $iniContent = Get-Content -Path "$IniFilePath\$IniFileName" -ErrorAction SilentlyContinue

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
    }
    else
    {
        Write-Verbose "Could not find $IniFilePath\$IniFileName. "
        Write-Verbose 'Results will contain parameters passed to configuration.'

        $getParameters = @{}
        foreach ($param in $testParameters)
        {
            if ($systemParameters -notcontains $param.Name)
            {
                if ($($PSBoundParameters.$($param.Name)))
                {
                    Write-Verbose -Message "$($param.Name) - $($PSBoundParameters.$($param.Name))"
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
        This will set the resource to desired state.

    .PARAMETER IniFileName
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
        Specifies whether to configure all site systems to accept only HTTPS communication from clients, or to configure the communication method for each site system role.

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

    .PARAMETER AddServerLanguages
        Specifies the server languages that will be available for the Configuration Manager console, reports, and Configuration Manager objects.

    .PARAMETER AddClientLanguages
        Specifies the languages that will be available to client computers.

    .PARAMETER DeleteServerLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be available for the Configuration Manager console, reports, and Configuration Manager objects.

    .PARAMETER DeleteClientLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be available to client computers.

    .PARAMETER SQLServerName
        Specifies the name of the server or clustered instance that's running SQL Server to host the site database.

    .PARAMETER DatabaseName
        Specifies the name of the SQL Server database to create, or the SQL Server database to use, when setup installs the CAS database.

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
        $IniFileName,

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
        [String]
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
        [String]
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
    if (($ManagementPoint -or $ManagementPointProtocol -or -$DistributionPoint -or $DistributionPointProtocol -or $RoleCommunicationProtocol -or
        $ClientsUsePKICertificate -or $CCARSiteServer -or $CASRetryInterval -or $WaitForCASTimeout) -and $Action -ne 'InstallPrimarySite')
    {
        Write-Error -Message "The parameters ManagementPoint, ManagementPointProtocol, DistributionPoint,
                            DistributionPointProtocol, RoleCommunicationProtocol, ClientsUsePKICertificate,
                            CCARSiteServer, CASRetryInterval, WaitForCASTimeout are used only with InstallPrimarySite."
    }
    elseif ($CloudConnector -eq $true -and ([string]::IsNullOrEmpty($CloudConnectorServer) -or ($UseProxy -or $UseProxy -eq $false)))
    {
        Write-Error -Message "If CloudConnector is True you must provide CloudConnectorServer and UseProxy."
    }
    elseif ($UseProxy -eq $true -and ([string]::IsNullOrEmpty($ProxyName) -or [string]::IsNullOrEmpty($ProxyPort)))
    {
        Write-Error -Message "If Proxy is True,  you must provide ProxyName and ProxyPort."
    }

    $identification = @{
        Title    = '[Identification]'
        Action   = ''
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

    $configOptions = @($Identification,$options,$sqlConfigOptions,$hierarchyExpansionOption,$cloudConnectorOptions,$saBranchOptions)

    Write-Verbose -Message 'Writing all configuration options to ini file.'
    foreach ($configOption in $configOptions)
    {
        $outputIni += "$($configOption.Title) `n"
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
                    Write-Verbose -Message "Adding $($item.Key)=$newValue."
                    $outputIni += "$($item.Key)=$newValue`n"
                }
                elseif ($PSBoundParameters.$($item.Name))
                {
                    Write-Verbose -Message "Adding $($item.Key)=$($PSBoundParameters.$($item.Name))."
                    $outputIni += "$($item.Key)=$($PSBoundParameters.$($item.Name))`n"
                }
            }
        }
        $outputIni += "`n"
    }
    Write-Verbose -Message "Exporting ini file to $IniFilePath\$IniFileName."
    $outputIni | Out-File -FilePath "$IniFilePath\$IniFileName" -Force
} #end function Set-TargetResource

<#
    .SYNOPSIS
        This will return whether the resource is in desired state.

    .PARAMETER IniFileName
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
        Specifies whether to configure all site systems to accept only HTTPS communication from clients, or to configure the communication method for each site system role.

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

    .PARAMETER AddServerLanguages
        Specifies the server languages that will be available for the Configuration Manager console, reports, and Configuration Manager objects.

    .PARAMETER AddClientLanguages
        Specifies the languages that will be available to client computers.

    .PARAMETER DeleteServerLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be available for the Configuration Manager console, reports, and Configuration Manager objects.

    .PARAMETER DeleteClientLanguages
        Modifies a site after it's installed. Specifies the languages to remove, and which will no longer be available to client computers.

    .PARAMETER SQLServerName
        Specifies the name of the server or clustered instance that's running SQL Server to host the site database.

    .PARAMETER DatabaseName
        Specifies the name of the SQL Server database to create, or the SQL Server database to use, when setup installs the CAS database.

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
        $IniFileName,

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
        [String]
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
        [String]
        $ProxyPort,

        [Parameter()]
        [Boolean]
        $SAActive,

        [Parameter()]
        [Boolean]
        $CurrentBranch
    )

    $IniFilePath = $IniFilePath.TrimEnd('\')
    Write-Verbose "Getting file content of $IniFilePath\$IniFileName"
    $iniContent = Get-Content -Path "$IniFilePath\$IniFileName" -ErrorAction SilentlyContinue
    $result = $true

    if ($iniContent)
    {
        foreach ($line in $iniContent)
        {
            if ($line -match '=')
            {
                $iniParameters += @{$line.split('=')[0] = $line.split('=')[1]}
            }
        }

        $systemParameters = @('Verbose','Debug','ErrorAction','WarningAction','InformationAction','ErrorVariable','WarningVariable','InformationVariable','OutVariable','OutBuffer','PipelineVariable')
        $PSBoundParameters.Remove('IniFilePath') | Out-Null
        $PSBoundParameters.Remove('IniFileName') | Out-Null

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
                Write-Verbose -Message "NOTMATCH: $($param.Key) - Current Value: $($iniParameters.$($param.Key)) Target Value: $newValue"
                $result = $false
            }
            elseif (-not $iniParameters.$($param.Key) -and $systemParameters -notcontains $param.Key)
            {
                Write-Verbose -Message "NOTMATCH: $($param.Key) - Current Value: `$null Target Value: $newValue"
                $result = $false
            }
            elseif ($iniParameters.$($param.Key) -and $iniParameters.$($param.Key) -eq $newValue)
            {
                Write-Verbose -Message "Match: $($param.Key) - Current Value: $($iniParameters.$($param.Key)) Target Value: $newValue"
            }
        }

    }
    else {
        $result = $false
    }

    Write-Verbose -Message "Test returned: $result."
    return $result
} #end function Test-TargetResource
