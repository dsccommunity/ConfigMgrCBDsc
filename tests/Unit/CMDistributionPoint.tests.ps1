[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMDistributionPoint'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Import Stub function
    $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {

        Describe 'ConfigMgrCBDsc - DSC_CMDistributionPoint\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $dpInfoReturn = @{
                    Communication     = 0
                    NALPath           = '["Display=\\DP01.contoso.com\"]MSWNET:["SMS_SITE=Lab"]\\DP01.contoso.com\'
                    PreStagingAllowed = $false
                    Description       = 'Test Description'
                    EnableLEDBAT      = $false
                }

                $boundaryGroupSiteSystemReturn = @(
                    @{
                        GroupID  = 16777226
                        ServerNalPath = '["Display=\\DP01.contoso.com\"]MSWNET:["SMS_SITE=Lab"]\\DP01.contoso.com\'
                    }
                    @{
                        GroupID  = 16777227
                        ServerNalPath = '["Display=\\DP01.contoso.com\"]MSWNET:["SMS_SITE=Lab"]\\DP01.contoso.com\'
                    }
                )

                $boundaryGroupReturnGroup1 = @{
                    GroupId = 16777226
                    Name    = 'Test-Group-1'
                }

                $boundaryGroupReturnGroup2 = @{
                    GroupId = 16777227
                    Name    = 'Test-Group-2'
                }

                $cmDistroPointProps = @{
                    Props = @(
                        @{
                            PropertyName = 'CertificateContextData'
                            Value1       =  '308201fb308'
                        }
                        @{
                            PropertyName = 'MinFreeSpace'
                            Value        =  100
                        }
                        @{
                            PropertyName = 'IsAnonymousEnabled'
                            Value        =  1
                        }
                        @{
                            PropertyName = 'UpdateBranchCacheKey'
                            Value        =  0
                        }
                        @{
                            PropertyName = 'AvailableContentLibDrivesList'
                            Value1       =  'FC'
                        }
                        @{
                            PropertyName = 'AvailablePkgShareDrivesList'
                            Value1       =  'FC'
                        }
                    )
                }

                $cmDistroPointPropsSinReturn = @{
                    Props = @(
                        @{
                            PropertyName = 'CertificateContextData'
                            Value1       =  '308201fb308'
                        }
                        @{
                            PropertyName = 'MinFreeSpace'
                            Value        =  100
                        }
                        @{
                            PropertyName = 'IsAnonymousEnabled'
                            Value        =  1
                        }
                        @{
                            PropertyName = 'UpdateBranchCacheKey'
                            Value        =  0
                        }
                        @{
                            PropertyName = 'AvailableContentLibDrivesList'
                            Value1       =  'F'
                        }
                        @{
                            PropertyName = 'AvailablePkgShareDrivesList'
                            Value1       =  'F'
                        }
                    )
                }

                $cmCertificate = @{
                    Certificate = '308201fb308'
                    ValidUntil  = '5/18/2022 8:24:38 PM'
                }

                $getInput = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'DP01.contoso.com'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving Collection settings' {

                It 'Should return desired result when all info is returned and multiple content locations' {
                    Mock -CommandName Get-CMDistributionPointInfo -MockWith { $dpInfoReturn }
                    Mock -CommandName Get-CMBoundaryGroupSiteSystem -MockWith { $boundaryGroupSiteSystemReturn }
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $boundaryGroupReturnGroup1 } -ParameterFilter {$ID -eq '16777226'}
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $boundaryGroupReturnGroup2 } -ParameterFilter {$ID -eq '16777227'}
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $cmDistroPointProps }
                    Mock -CommandName Get-CMCertificate -MockWith { $cmCertificate }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName                  | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.Description                     | Should -Be -ExpectedValue 'Test Description'
                    $result.MinimumFreeSpaceMB              | Should -Be -ExpectedValue 100
                    $result.PrimaryContentLibraryLocation   | Should -Be -ExpectedValue 'F'
                    $result.SecondaryContentLibraryLocation | Should -be -ExpectedValue 'C'
                    $result.PrimaryPackageShareLocation     | Should -Be -ExpectedValue 'F'
                    $result.SecondaryPackageShareLocation   | Should -be -ExpectedValue 'C'
                    $result.ClientCommunicationType         | Should -Be -ExpectedValue 'HTTP'
                    $result.BoundaryGroups                  | Should -Be -ExpectedValue @('Test-Group-1','Test-Group-2')
                    $result.AllowPreStaging                 | Should -Be -ExpectedValue $false
                    $result.CertificateExpirationTimeUtc    | Should -Be -ExpectedValue '5/18/2022 8:24:38 PM'
                    $result.EnableAnonymous                 | Should -Be -ExpectedValue $true
                    $result.EnableBranchCache               | Should -Be -ExpectedValue $false
                    $result.EnableLedbat                    | Should -Be -ExpectedValue $false
                    $result.Ensure                          | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when all info is returned and single content location' {
                    Mock -CommandName Get-CMDistributionPointInfo -MockWith { $dpInfoReturn }
                    Mock -CommandName Get-CMBoundaryGroupSiteSystem -MockWith { $boundaryGroupSiteSystemReturn }
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $boundaryGroupReturnGroup1 } -ParameterFilter {$ID -eq '16777226'}
                    Mock -CommandName Get-CMBoundaryGroup -MockWith { $boundaryGroupReturnGroup2 } -ParameterFilter {$ID -eq '16777227'}
                    Mock -CommandName Get-CMDistributionPoint -MockWith { $cmDistroPointPropsSinReturn }
                    Mock -CommandName Get-CMCertificate -MockWith { $cmCertificate }

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName                  | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.Description                     | Should -Be -ExpectedValue 'Test Description'
                    $result.MinimumFreeSpaceMB              | Should -Be -ExpectedValue 100
                    $result.PrimaryContentLibraryLocation   | Should -Be -ExpectedValue 'F'
                    $result.SecondaryContentLibraryLocation | Should -be -ExpectedValue $null
                    $result.PrimaryPackageShareLocation     | Should -Be -ExpectedValue 'F'
                    $result.SecondaryPackageShareLocation   | Should -be -ExpectedValue $null
                    $result.ClientCommunicationType         | Should -Be -ExpectedValue 'HTTP'
                    $result.BoundaryGroups                  | Should -Be -ExpectedValue @('Test-Group-1','Test-Group-2')
                    $result.AllowPreStaging                 | Should -Be -ExpectedValue $false
                    $result.CertificateExpirationTimeUtc    | Should -Be -ExpectedValue '5/18/2022 8:24:38 PM'
                    $result.EnableAnonymous                 | Should -Be -ExpectedValue $true
                    $result.EnableBranchCache               | Should -Be -ExpectedValue $false
                    $result.EnableLedbat                    | Should -Be -ExpectedValue $false
                    $result.Ensure                          | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when all info is returned and single content location' {
                    Mock -CommandName Get-CMDistributionPointInfo -MockWith { $null }
                    Mock -CommandName Get-CMBoundaryGroupSiteSystem
                    Mock -CommandName Get-CMBoundaryGroup
                    Mock -CommandName Get-CMDistributionPoint
                    Mock -CommandName Get-CMCertificate

                    $result = Get-TargetResource @getInput
                    $result                                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                        | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName                  | Should -Be -ExpectedValue 'DP01.contoso.com'
                    $result.Description                     | Should -Be -ExpectedValue $null
                    $result.MinimumFreeSpaceMB              | Should -Be -ExpectedValue $null
                    $result.PrimaryContentLibraryLocation   | Should -Be -ExpectedValue $null
                    $result.SecondaryContentLibraryLocation | Should -be -ExpectedValue $null
                    $result.PrimaryPackageShareLocation     | Should -Be -ExpectedValue $null
                    $result.SecondaryPackageShareLocation   | Should -be -ExpectedValue $null
                    $result.ClientCommunicationType         | Should -Be -ExpectedValue $null
                    $result.BoundaryGroups                  | Should -Be -ExpectedValue $null
                    $result.AllowPreStaging                 | Should -Be -ExpectedValue $null
                    $result.CertificateExpirationTimeUtc    | Should -Be -ExpectedValue $null
                    $result.EnableAnonymous                 | Should -Be -ExpectedValue $false
                    $result.EnableBranchCache               | Should -Be -ExpectedValue $false
                    $result.EnableLedbat                    | Should -Be -ExpectedValue $null
                    $result.Ensure                          | Should -Be -ExpectedValue 'Absent'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMDistributionPoint\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $getTargetReturnPresent = @{
                    SiteCode                        = 'Lab'
                    SiteServerName                  = 'DP01.contoso.com'
                    Description                     = 'test description'
                    MinimumFreeSpaceMB              = 100
                    PrimaryContentLibraryLocation   = 'F'
                    SecondaryContentLibraryLocation = 'C'
                    PrimaryPackageShareLocation     = 'F'
                    SecondaryPackageShareLocation   = 'C'
                    ClientCommunicationType         = 'HTTP'
                    BoundaryGroups                  = @('Test-Group-1','Test-Group-2')
                    AllowPreStaging                 = $false
                    CertificateExpirationTimeUtc    = $validData
                    EnableAnonymous                 = $false
                    EnableBranchCache               = $false
                    EnableLedbat                    = $false
                    Ensure                          = 'Present'
                }

                $getTargetReturnAbsent = @{
                    SiteCode                        = 'Lab'
                    SiteServerName                  = 'DP01.contoso.com'
                    Description                     = $null
                    MinimumFreeSpaceMB              = $null
                    PrimaryContentLibraryLocation   = $null
                    SecondaryContentLibraryLocation = $null
                    PrimaryPackageShareLocation     = $null
                    SecondaryPackageShareLocation   = $null
                    ClientCommunicationType         = $null
                    BoundaryGroups                  = $null
                    AllowPreStaging                 = $null
                    CertificateExpirationTimeUtc    = $null
                    EnableAnonymous                 = $false
                    EnableBranchCache               = $false
                    EnableLedbat                    = $null
                    Ensure                          = 'Absent'
                }

                $createDistroPointOnly = @{
                    SiteCode                        = 'Lab'
                    SiteServerName                  = 'DP01.contoso.com'
                    MinimumFreeSpaceMB              = 100
                    PrimaryContentLibraryLocation   = 'F'
                    SecondaryContentLibraryLocation = 'C'
                    PrimaryPackageShareLocation     = 'F'
                    SecondaryPackageShareLocation   = 'C'
                    CertificateExpirationTimeUtc    = '5/28/22 8:30 PM'
                }

                $boundaryGroupMatchInput = @{
                    SiteCode            = 'Lab'
                    SiteServerName      = 'DP01.contoso.com'
                    BoundaryGroups      = @('Test-Group-1','Test-Group-3')
                    BoundaryGroupStatus = 'Match'
                    Ensure              = 'Present'
                }

                $absentInput = @{
                    SiteCode        = 'Lab'
                    SiteServerName  = 'DP01.contoso.com'
                    Ensure          = 'Absent'
                }

                $misMatchInput = @{
                    SiteCode        = 'Lab'
                    SiteServerName  = 'DP01.contoso.com'
                    EnableAnonymous = $true
                    EnableLedbat    = $true
                    Ensure          = 'Present'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMDistributionPoint
                Mock -CommandName Set-CMDistributionPoint
                Mock -CommandName Remove-CMDistributionPoint
            }

            Context 'When Set-TargetResource runs successfully when get returns absent' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                }

                It 'Should call expected commands when adding a Distribution Point' {

                    Set-TargetResource @boundaryGroupMatchInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when adding only a Distribution Point and specifying a certificate date' {

                    Set-TargetResource @createDistroPointOnly
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 0 -Scope It
                }
            }

            Context 'When Set-TargetResource runs successfully when get returns present' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturnPresent }
                    Mock -CommandName Get-CMSiteSystemServer
                }

                It 'Should call expected commands when adding and removing boundary groups' {

                    Set-TargetResource @boundaryGroupMatchInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when adding settings do not match' {

                    Set-TargetResource @misMatchInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when removing a Distribution Point' {

                    Set-TargetResource @absentInput
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Set-TargetResource should throw' {
                BeforeEach {
                    $invalidPrimary = @{
                        SiteCode                        = 'Lab'
                        SiteServerName                  = 'DP01.contoso.com'
                        PrimaryPackageShareLocation     = 4
                        SecondaryContentLibraryLocation = 'C'
                    }

                    $invalidEntryThrow = 'Primary and Secondary Library or Package locations must be a character A - Z.'

                    $invalidSecondaryNoPrimary  = @{
                        SiteCode                        = 'Lab'
                        SiteServerName                  = 'DP01.contoso.com'
                        SecondaryContentLibraryLocation = 'C'
                    }

                    $invalidSecondaryThrow = 'Must specify the assoicated primary location when a secondary location is specified.'

                }

                It 'Should call expected commands when Set-CMDistributionPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturnPresent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName Set-CMDistributionPoint -MockWith { throw }

                    { Set-TargetResource @misMatchInput } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when Remove-CMDistributionPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturnPresent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName Set-CMDistributionPoint
                    Mock -CommandName Remove-CMDistributionPoint -MockWith { throw }

                    { Set-TargetResource @absentInput } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when New-CMSiteSystemServer throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName Set-CMDistributionPoint
                    Mock -CommandName Remove-CMDistributionPoint
                    Mock -CommandName New-CMSiteSystemServer -MockWith { throw }

                    { Set-TargetResource @createDistroPointOnly } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when content or package location are not a letter throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName Set-CMDistributionPoint
                    Mock -CommandName Remove-CMDistributionPoint
                    Mock -CommandName New-CMSiteSystemServer

                    { Set-TargetResource @invalidPrimary } | Should -Throw -ExpectedMessage $invalidEntryThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when secondary content or package location are specified with no primary location' {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName Set-CMDistributionPoint
                    Mock -CommandName Remove-CMDistributionPoint
                    Mock -CommandName New-CMSiteSystemServer

                    { Set-TargetResource @invalidSecondaryNoPrimary } | Should -Throw -ExpectedMessage $invalidSecondaryThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMDistributionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMDistributionPoint -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMDistributionPoint\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $getTargetReturnPresent = @{
                    SiteCode                        = 'Lab'
                    SiteServerName                  = 'DP01.contoso.com'
                    Description                     = 'test description'
                    MinimumFreeSpaceMB              = 100
                    PrimaryContentLibraryLocation   = 'F'
                    SecondaryContentLibraryLocation = 'C'
                    PrimaryPackageShareLocation     = 'F'
                    SecondaryPackageShareLocation   = 'C'
                    ClientCommunicationType         = 'HTTP'
                    BoundaryGroups                  = @('Test-Group-1','Test-Group-2')
                    AllowPreStaging                 = $false
                    CertificateExpirationTimeUtc    = $validData
                    EnableAnonymous                 = $false
                    EnableBranchCache               = $false
                    EnableLedbat                    = $false
                    Ensure                          = 'Present'
                }

                $getTargetReturnAbsent = @{
                    SiteCode                        = 'Lab'
                    SiteServerName                  = 'DP01.contoso.com'
                    Description                     = $null
                    MinimumFreeSpaceMB              = $null
                    PrimaryContentLibraryLocation   = $null
                    SecondaryContentLibraryLocation = $null
                    PrimaryPackageShareLocation     = $null
                    SecondaryPackageShareLocation   = $null
                    ClientCommunicationType         = $null
                    BoundaryGroups                  = $null
                    AllowPreStaging                 = $null
                    CertificateExpirationTimeUtc    = $null
                    EnableAnonymous                 = $false
                    EnableBranchCache               = $false
                    EnableLedbat                    = $null
                    Ensure                          = 'Absent'
                }

                $matchInput = @{
                    SiteCode        = 'Lab'
                    SiteServerName  = 'DP01.contoso.com'
                    EnableAnonymous = $false
                    EnableLedbat    = $false
                    Ensure          = 'Present'
                }

                $absentInput = @{
                    SiteCode        = 'Lab'
                    SiteServerName  = 'DP01.contoso.com'
                    Ensure          = 'Absent'
                }
                Mock -CommandName Set-Location
                Mock -CommandName Import-ConfigMgrPowerShellModule
            }

            Context 'When running Test-TargetResource and get returns present' {
                BeforeEach {
                    $misMatchInput = @{
                        SiteCode        = 'Lab'
                        SiteServerName  = 'DP01.contoso.com'
                        EnableAnonymous = $true
                        EnableLedbat    = $true
                        Ensure          = 'Present'
                    }

                    $dpPresentValidateNonCheckedSettigns = @{
                        SiteCode                      = 'Lab'
                        SiteServerName                = 'DP01.contoso.com'
                        PrimaryContentLibraryLocation = 'X'
                        EnableAnonymous               = $false
                        EnableLedbat                  = $false
                        Ensure                        = 'Present'
                    }

                    $boundaryGroupMatchInput = @{
                        SiteCode            = 'Lab'
                        SiteServerName      = 'DP01.contoso.com'
                        BoundaryGroups      = @('Test-Group-1','Test-Group-3')
                        BoundaryGroupStatus = 'Match'
                        Ensure              = 'Present'
                    }

                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturnPresent }
                }

                It 'Should return desired result true settings match' {
                    Test-TargetResource @matchInput | Should -Be $true
                }

                It 'Should return desired result false when settings do not match' {
                    Test-TargetResource @misMatchInput | Should -Be $false
                }

                It 'Should return desired result true when only settings mismatch can not be changed after DP role is installed' {
                    Test-TargetResource @dpPresentValidateNonCheckedSettigns | Should -Be $true
                }

                It 'Should return desired result false when boundarygroups do not match' {
                    Test-TargetResource @boundaryGroupMatchInput | Should -Be $false
                }

                It 'Should return desired result false when desire result is absent' {
                    Test-TargetResource @absentInput | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource and get returns absent' {
                BeforeEach {
                    Mock -CommandName Get-TargetResource -MockWith { $getTargetReturnAbsent }
                }

                It 'Should return desired result true desired result is absent' {
                    Test-TargetResource @absentInput | Should -Be $true
                }

                It 'Should return desired result false desired result is present' {
                    Test-TargetResource @matchInput | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
