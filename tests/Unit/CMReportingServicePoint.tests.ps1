param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMReportingServicePoint'

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

#Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMReportingServicePoint'

        Describe 'ConfigMgrCBDsc - DSC_CMReportingServicePoint\Get-TargetResource' -Tag 'Get'{
            BeforeAll{
                $getInput = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                }

                $getRSPReturn = @{
                    Props    = @(
                        @{
                            PropertyName = 'DatabaseName'
                            Value2       = 'CM_LAB'
                        }
                        @{
                            PropertyName = 'DatabaseServerName'
                            Value2       = 'CA01.contoso.com'
                        }
                        @{
                            PropertyName = 'UserName'
                            Value2       = 'contoso\SQLAdmin'
                        }
                        @{
                            PropertyName = 'ReportServerInstance'
                            Value2       = 'MSSQLSERVER'
                        }
                        @{
                            PropertyName = 'RootFolder'
                            Value2       = 'ConfigMgr_LAB'
                        }
                    )
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving reporting service point settings' {

                It 'Should return desired result when the reporting service point is not currently installed' {
                    Mock -CommandName Get-CMReportingServicePoint

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName       | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.DatabaseName         | Should -Be -ExpectedValue $null
                    $result.DatabaseServerName   | Should -Be -ExpectedValue $null
                    $result.UserName             | Should -Be -ExpectedValue $null
                    $result.FolderName           | Should -Be -ExpectedValue $null
                    $result.ReportServerInstance | Should -Be -ExpectedValue $null
                    $result.Ensure               | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when the reporting service point is currently installed' {
                    Mock -CommandName Get-CMReportingServicePoint -MockWith { $getRSPReturn }

                    $result = Get-TargetResource @getInput
                    $result                      | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode             | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName       | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.DatabaseName         | Should -Be -ExpectedValue 'CM_LAB'
                    $result.DatabaseServerName   | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.UserName             | Should -Be -ExpectedValue 'contoso\SQLAdmin'
                    $result.FolderName           | Should -Be -ExpectedValue 'ConfigMgr_LAB'
                    $result.ReportServerInstance | Should -Be -ExpectedValue 'MSSQLSERVER'
                    $result.Ensure               | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMReportingServicePoint\Set-TargetResource' -Tag 'Set'{
            BeforeAll{
                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Ensure         = 'Absent'
                }

                $inputMatch = @{
                    SiteServerName     = 'CA01.contoso.com'
                    SiteCode           = 'Lab'
                    DatabaseName       = 'CM_LAB'
                    DatabaseServerName = 'CA01.contoso.com'
                    UserName           = 'contoso\SQLAdmin'
                    Ensure             = 'Present'
                }

                $inputMismatch = @{
                    SiteServerName     = 'CA01.contoso.com'
                    SiteCode           = 'Lab'
                    DatabaseName       = 'CM_LAB'
                    DatabaseServerName = 'CA01.contoso.com'
                    UserName           = 'contoso\CMAdmin'
                    Ensure             = 'Present'
                }

                $getReturnAll = @{
                    SiteServerName       = 'CA01.contoso.com'
                    SiteCode             = 'Lab'
                    DatabaseName         = 'CM_LAB'
                    DatabaseServerName   = 'CA01.contoso.com'
                    UserName             = 'contoso\SQLAdmin'
                    FolderName           = 'ConfigMgr_LAB'
                    ReportServerInstance = 'MSSQLSERVER'
                    Ensure               = 'Present'
                }

                $getReturnAbsent = @{
                    SiteServerName       = 'CA01.contoso.com'
                    SiteCode             = 'Lab'
                    DatabaseName         = $null
                    DatabaseServerName   = $null
                    UserName             = $null
                    FolderName           = $null
                    ReportServerInstance = $null
                    Ensure               = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMReportingServicePoint
                Mock -CommandName Set-CMReportingServicePoint
                Mock -CommandName Remove-CMReportingServicePoint
            }

            Context 'When Set-TargetResource runs successfully' {

                It 'Should call expected commands for when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when reporting service point is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @inputMatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when software update point exists and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {
                BeforeEach{
                    $inputPresent = @{
                        SiteCode       = 'Lab'
                        SiteServerName = 'CA01.contoso.com'
                        Ensure         = 'Present'
                    }

                    $immutableParamMismatch = @{
                        SiteServerName     = 'CA01.contoso.com'
                        SiteCode           = 'Lab'
                        DatabaseName       = 'CM_LAB'
                        DatabaseServerName = 'CA01.contoso.com'
                        FolderName         = 'ConfigMgr_TST'
                        Ensure             = 'Present'
                    }

                    $userThrowMsg = 'The UserName parameter is required when installing the Reporting Service Point Role.'

                    $paramThrowMsg = 'Folder Name and Report Server Instance can not be changed once the Reporting Service Point is installed.'

                }

                It 'Should call throws when the role needs to be installed and a username is not specified' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    { Set-TargetResource @inputPresent } | Should -Throw -ExpectedMessage $userThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call throws when an immutable parameter is specified for change' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @immutableParamMismatch } | Should -Throw -ExpectedMessage $paramThrowMsg
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Get-CMSiteSystemServer throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { throw }

                    { Set-TargetResource @inputMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if New-CMSiteSystemServer throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName New-CMSiteSystemServer -MockWith { throw }

                    { Set-TargetResource @inputMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Add-CMReportingServicePoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName New-CMSiteSystemServer -MockWith { $true }
                    Mock -CommandName Add-CMReportingServicePoint -MockWith { throw }

                    { Set-TargetResource @inputMatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Set-CMReportingServicePoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Set-CMReportingServicePoint -MockWith { throw }

                    { Set-TargetResource @inputMismatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly 0 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly 1 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Remove-CMReportingServicePoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Remove-CMReportingServicePoint -MockWith { throw }

                    { Set-TargetResource @inputAbsent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMReportingServicePoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMReportingServicePoint -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMReportingServicePoint\Test-TargetResource' -Tag 'Test'{
            BeforeAll{
                $inputPresent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Ensure         = 'Present'
                }

                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Ensure         = 'Absent'
                }

                $inputMatch = @{
                    SiteServerName     = 'CA01.contoso.com'
                    SiteCode           = 'Lab'
                    DatabaseName       = 'CM_LAB'
                    DatabaseServerName = 'CA01.contoso.com'
                    UserName           = 'contoso\SQLAdmin'
                    Ensure             = 'Present'
                }

                $inputMismatch = @{
                    SiteServerName     = 'CA01.contoso.com'
                    SiteCode           = 'Lab'
                    DatabaseName       = 'CM_LAB'
                    DatabaseServerName = 'CA01.contoso.com'
                    UserName           = 'contoso\CMAdmin'
                    Ensure             = 'Present'
                }

                $immutableParamMismatch = @{
                    SiteServerName     = 'CA01.contoso.com'
                    SiteCode           = 'Lab'
                    DatabaseName       = 'CM_LAB'
                    DatabaseServerName = 'CA01.contoso.com'
                    FolderName         = 'ConfigMgr_TST'
                    Ensure             = 'Present'
                }

                $getReturnAll = @{
                    SiteServerName       = 'CA01.contoso.com'
                    SiteCode             = 'Lab'
                    DatabaseName         = 'CM_LAB'
                    DatabaseServerName   = 'CA01.contoso.com'
                    UserName             = 'contoso\SQLAdmin'
                    FolderName           = 'ConfigMgr_LAB'
                    ReportServerInstance = 'MSSQLSERVER'
                    Ensure               = 'Present'
                }

                $getReturnAbsent = @{
                    SiteServerName       = 'CA01.contoso.com'
                    SiteCode             = 'Lab'
                    DatabaseName         = $null
                    DatabaseServerName   = $null
                    UserName             = $null
                    FolderName           = $null
                    ReportServerInstance = $null
                    Ensure               = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource and Get-TargetResource Returns ' {
                BeforeEach{
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                }

                It 'Should return desired result false when ensure = absent and RSP is present' {

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result true when all returned values match inputs' {

                    Test-TargetResource @inputMatch | Should -Be $true
                }

                It 'Should return desired result false when there is a mismatch between returned values and inputs' {

                    Test-TargetResource @inputMismatch | Should -Be $false
                }

                It 'Should return desired result false when there is a mismatch with immutable parameters' {

                    Test-TargetResource @immutableParamMismatch | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource and Get-TargetResource Returns absent' {
                BeforeEach{
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                }

                It 'Should return desired result false when ensure = present and RSP is absent' {

                    Test-TargetResource @inputPresent  | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent and RSP is absent' {

                    Test-TargetResource @inputAbsent | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
