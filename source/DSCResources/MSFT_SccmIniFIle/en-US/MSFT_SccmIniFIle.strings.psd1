ConvertFrom-StringData @'
    MissingFileContent       = Could not find '{0}'\'{1}'.
    GetPassParameters        = Results will contain parameters passed to configuration.
    GetParameterPrint        = '{0}' - '{1}'
    PrimaryParameterError    = The parameters ManagementPoint, ManagementPointProtocol, DistributionPoint, DistributionPointProtocol, RoleCommunicationProtocol, ClientsUsePKICertificate, CCARSiteServer, CASRetryInterval, WaitForCASTimeout are used only with InstallPrimarySite.
    CloudConnectorError      = If CloudConnector is True you must provide CloudConnectorServer and UseProxy.
    ProxyError               = If Proxy is True, you must provide ProxyName and ProxyPort.
    GettingFileContent       = Getting file content of '{0}'\'{1}'
    WritingParameter         = Writing all configuration options to ini file.
    AddingParameter          = Adding '{0}'='{1}'."
    ExportingFile            = Exporting ini file to '{0}'\'{1}'."
    TestMatch                = Match: '{0}' - Current Value: '{1}' Target Value: '{2}'
    TestNoMatch              = NOTMATCH: '{0}' - Current Value: '{1}' Target Value: '{2}'
    InDesiredStateMessage    = Ini file is in the desired state.
    NotInDesiredStateMessage = Ini file is NOT in the desired state.
'@
