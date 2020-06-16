@{
    PSDependOptions             = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = ''
        }
    }

    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = 'latest'
    Pester                      = '4.10.1'
    Plaster                     = 'latest'
    ModuleBuilder               = 'latest'
    ChangelogManagement         = 'latest'
    Sampler                     = 'latest'
    MarkdownLinkCheck           = 'latest'
    'DscResource.Test'          = 'latest'
    'DscResource.AnalyzerRules' = 'latest'
    xDscResourceDesigner        = 'latest'
    'DscResource.DocGenerator'  = 'latest'

    # Build dependent modules
    'DscResource.Common'        = 'latest'
    'SqlServerDsc'              = '14.0.0'
    'NetworkingDsc'             = '7.4.0.0'
}
