ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager Security Roles.
    AbsentRoleXmlMissing = Role does not exist and will not be able to create role without specifying a valid XML.
    XmlFileNoOverwrite   = XML file was specified and Overwrite and Append was set to false, DSC will not evalute Security Roles settings.
    InvalidXml           = {0} is invalid no additional Security Scope settings will be checked.
    XmlNameMismatch      = The name specified in the xml does not match the name specified in the parameters.
    OverwriteAppend      = Overwrite and Append are set to true, defaulting to Append action.
    SettingsMismatch     = NOTMATCH: Settings do not match {0} expected {1} returned {2}.
    MissingSettings      = NOTMATCH: Missing setting ObjectTypeId: {0} with value: {1}.
    AdditionalSettings   = {0} current setting contains extra settings that are currently not in the XML these will be {1} Id: {2} value: {3}.
    MissingGetConfig     = No current settings are present, returning false to import the settings.
    DescriptionMismatch  = Description does not match expected {0} returned {1}.
    RoleDeleteAdmin      = Deleting this role will affect the following Administrators: {0}.
    TestState            = Test-TargetResource compliance check returned: {0}.
    InvalidXmlThow       = Xml appears to be invalid check xml and try again.
    SettingsMismatchSet  = Setting does not match setting ObjectTypeId: {0} to {1}.
    DescriptionSet       = Setting Description to {0}.
    DeleteRole           = Removing Security Role: {0} from Configuration Manager.
'@
