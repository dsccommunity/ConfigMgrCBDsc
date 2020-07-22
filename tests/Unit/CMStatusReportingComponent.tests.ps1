param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMStatusReportingComponent'

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
        Describe 'ConfigMgrCBDsc - DSC_CMStatusReportingComponent\Get-TargetResource' -Tag 'Get'{
            BeforeAll{
                $getInput = @{
                    SiteCode = 'Lab'
                }

                $getEWI = @(
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Client Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value2       = 'EWI,True'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value2       = 'EWI,True'
                            }
                        )
                    }
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Server Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value1       = 'EWI,True'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value1       = 'EWI,True'
                            }
                        )
                    }
                )

                $getAll = @(
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Client Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value2       = 'All,True'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value2       = 'All,True'
                            }
                        )
                    }
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Server Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value1       = 'All,True'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value1       = 'All,True'
                            }
                        )
                    }
                )

                $getEW = @(
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Client Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value2       = 'EW,True'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value2       = 'EW,True'
                            }
                        )
                    }
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Server Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value1       = 'EW,True'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value1       = 'EW,True'
                            }
                        )
                    }
                )

                $getE = @(
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Client Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value2       = 'E,True'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value2       = 'E,True'
                            }
                        )
                    }
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Server Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value1       = 'E,True'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value1       = 'E,True'
                            }
                        )
                    }
                )

                $getNone = @(
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Client Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value2       = 'NONE,False'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value2       = 'NONE,False'
                            }
                        )
                    }
                    @{
                        SiteCode = 'Lab'
                        ItemName = 'Server Component Status Reporting'
                        Props    = @(
                            @{
                                PropertyName = 'Default Status Message Reporting Level'
                                Value1       = 'NONE,False'
                            }
                            @{
                                PropertyName = 'Default Windows NT Event Reporting Level'
                                Value1       = 'NONE,False'
                            }
                        )
                    }
                )

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving status reporting component settings' {

                It 'Should return desired result for AllMilestones and failures checked' {
                    Mock -CommandName Get-CMStatusReportingComponent -MockWith { $getEWI }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientLogChecked           | Should -Be -ExpectedValue $true
                    $result.ClientLogFailureChecked    | Should -Be -ExpectedValue $true
                    $result.ClientLogType              | Should -Be -ExpectedValue 'AllMilestones'
                    $result.ClientReportChecked        | Should -Be -ExpectedValue $true
                    $result.ClientReportFailureChecked | Should -Be -ExpectedValue $true
                    $result.ClientReportType           | Should -Be -ExpectedValue 'AllMilestones'
                    $result.ServerLogChecked           | Should -Be -ExpectedValue $true
                    $result.ServerLogFailureChecked    | Should -Be -ExpectedValue $true
                    $result.ServerLogType              | Should -Be -ExpectedValue 'AllMilestones'
                    $result.ServerReportChecked        | Should -Be -ExpectedValue $true
                    $result.ServerReportFailureChecked | Should -Be -ExpectedValue $true
                    $result.ServerReportType           | Should -Be -ExpectedValue 'AllMilestones'
                }

                It 'Should return desired result for AllMilestonesAndAllDetails and failures checked' {
                    Mock -CommandName Get-CMStatusReportingComponent -MockWith { $getAll }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientLogChecked           | Should -Be -ExpectedValue $true
                    $result.ClientLogFailureChecked    | Should -Be -ExpectedValue $true
                    $result.ClientLogType              | Should -Be -ExpectedValue 'AllMilestonesAndAllDetails'
                    $result.ClientReportChecked        | Should -Be -ExpectedValue $true
                    $result.ClientReportFailureChecked | Should -Be -ExpectedValue $true
                    $result.ClientReportType           | Should -Be -ExpectedValue 'AllMilestonesAndAllDetails'
                    $result.ServerLogChecked           | Should -Be -ExpectedValue $true
                    $result.ServerLogFailureChecked    | Should -Be -ExpectedValue $true
                    $result.ServerLogType              | Should -Be -ExpectedValue 'AllMilestonesAndAllDetails'
                    $result.ServerReportChecked        | Should -Be -ExpectedValue $true
                    $result.ServerReportFailureChecked | Should -Be -ExpectedValue $true
                    $result.ServerReportType           | Should -Be -ExpectedValue 'AllMilestonesAndAllDetails'
                }

                It 'Should return desired result for ErrorAndWarningMilestones and failures checked' {
                    Mock -CommandName Get-CMStatusReportingComponent -MockWith { $getEW }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientLogChecked           | Should -Be -ExpectedValue $true
                    $result.ClientLogFailureChecked    | Should -Be -ExpectedValue $true
                    $result.ClientLogType              | Should -Be -ExpectedValue 'ErrorAndWarningMilestones'
                    $result.ClientReportChecked        | Should -Be -ExpectedValue $true
                    $result.ClientReportFailureChecked | Should -Be -ExpectedValue $true
                    $result.ClientReportType           | Should -Be -ExpectedValue 'ErrorAndWarningMilestones'
                    $result.ServerLogChecked           | Should -Be -ExpectedValue $true
                    $result.ServerLogFailureChecked    | Should -Be -ExpectedValue $true
                    $result.ServerLogType              | Should -Be -ExpectedValue 'ErrorAndWarningMilestones'
                    $result.ServerReportChecked        | Should -Be -ExpectedValue $true
                    $result.ServerReportFailureChecked | Should -Be -ExpectedValue $true
                    $result.ServerReportType           | Should -Be -ExpectedValue 'ErrorAndWarningMilestones'
                }

                It 'Should return desired result for ErrorMilestones and failures checked' {
                    Mock -CommandName Get-CMStatusReportingComponent -MockWith { $getE }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientLogChecked           | Should -Be -ExpectedValue $true
                    $result.ClientLogFailureChecked    | Should -Be -ExpectedValue $true
                    $result.ClientLogType              | Should -Be -ExpectedValue 'ErrorMilestones'
                    $result.ClientReportChecked        | Should -Be -ExpectedValue $true
                    $result.ClientReportFailureChecked | Should -Be -ExpectedValue $true
                    $result.ClientReportType           | Should -Be -ExpectedValue 'ErrorMilestones'
                    $result.ServerLogChecked           | Should -Be -ExpectedValue $true
                    $result.ServerLogFailureChecked    | Should -Be -ExpectedValue $true
                    $result.ServerLogType              | Should -Be -ExpectedValue 'ErrorMilestones'
                    $result.ServerReportChecked        | Should -Be -ExpectedValue $true
                    $result.ServerReportFailureChecked | Should -Be -ExpectedValue $true
                    $result.ServerReportType           | Should -Be -ExpectedValue 'ErrorMilestones'
                }

                It 'Should return desired result when all items are unchecked' {
                    Mock -CommandName Get-CMStatusReportingComponent -MockWith { $getNone }

                    $result = Get-TargetResource @getInput
                    $result                            | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode                   | Should -Be -ExpectedValue 'Lab'
                    $result.ClientLogChecked           | Should -Be -ExpectedValue $false
                    $result.ClientLogFailureChecked    | Should -Be -ExpectedValue $false
                    $result.ClientLogType              | Should -Be -ExpectedValue 'NONE'
                    $result.ClientReportChecked        | Should -Be -ExpectedValue $false
                    $result.ClientReportFailureChecked | Should -Be -ExpectedValue $false
                    $result.ClientReportType           | Should -Be -ExpectedValue 'NONE'
                    $result.ServerLogChecked           | Should -Be -ExpectedValue $false
                    $result.ServerLogFailureChecked    | Should -Be -ExpectedValue $false
                    $result.ServerLogType              | Should -Be -ExpectedValue 'NONE'
                    $result.ServerReportChecked        | Should -Be -ExpectedValue $false
                    $result.ServerReportFailureChecked | Should -Be -ExpectedValue $false
                    $result.ServerReportType           | Should -Be -ExpectedValue 'NONE'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMStatusReportingComponent\Set-TargetResource' -Tag 'Set'{
            BeforeAll{
                $getReturnAll = @{
                    SiteCode                   = 'Lab'
                    ClientLogChecked           = $true
                    ClientLogFailureChecked    = $true
                    ClientLogType              = 'AllMilestones'
                    ClientReportChecked        = $true
                    ClientReportFailureChecked = $true
                    ClientReportType           = 'AllMilestones'
                    ServerLogChecked           = $true
                    ServerLogFailureChecked    = $true
                    ServerLogType              = 'AllMilestones'
                    ServerReportChecked        = $true
                    ServerReportFailureChecked = $true
                    ServerReportType           = 'AllMilestones'
                }

                $inputMismatch = @{
                    SiteCode                   = 'Lab'
                    ClientLogChecked           = $true
                    ClientLogFailureChecked    = $false
                    ClientLogType              = 'AllMilestones'
                    ClientReportChecked        = $true
                    ClientReportFailureChecked = $false
                    ClientReportType           = 'AllMilestones'
                    ServerLogChecked           = $true
                    ServerLogFailureChecked    = $true
                    ServerLogType              = 'ErrorAndWarningMilestones'
                    ServerReportChecked        = $true
                    ServerReportFailureChecked = $true
                    ServerReportType           = 'ErrorMilestones'
                }

                $cLogMalformed = @{
                    SiteCode         = 'Lab'
                    ClientLogChecked = $false
                    ClientLogType    = 'AllMilestones'
                }

                $cLogThrow = 'In order to set the Client Log settings, you must specify ClientLogChecked to be True.'

                $cReportMalformed = @{
                    SiteCode            = 'Lab'
                    ClientReportChecked = $false
                    ClientReportType    = 'AllMilestones'
                }

                $cReportThrow = 'In order to set the Client Report settings, you must specify ClientReportChecked to be True.'

                $sLogMalformed = @{
                    SiteCode         = 'Lab'
                    ServerLogChecked = $false
                    ServerLogType    = 'AllMilestones'
                }

                $sLogThrow = 'In order to set the Server Log settings, you must specify ServerLogChecked to be True.'

                $sReportMalformed = @{
                    SiteCode            = 'Lab'
                    ServerReportChecked = $false
                    ServerReportType    = 'AllMilestones'
                }

                $sReportThrow = 'In order to set the Server Report settings, you must specify ServerReportChecked to be True.'

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Set-CMStatusReportingComponent
            }

            Context 'When Set-TargetResource runs successfully' {

                It 'Should call expected commands when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMStatusReportingComponent -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {

                It 'Should call expected commands and throw if client logging settings are malformed' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @cLogMalformed } | Should -Throw -ExpectedMessage $cLogThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMStatusReportingComponent -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if client reporting settings are malformed' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @cReportMalformed } | Should -Throw -ExpectedMessage $cReportThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMStatusReportingComponent -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if server logging settings are malformed' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @sLogMalformed } | Should -Throw -ExpectedMessage $sLogThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMStatusReportingComponent -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if server reporting settings are malformed' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    { Set-TargetResource @sReportMalformed } | Should -Throw -ExpectedMessage $sReportThrow
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMStatusReportingComponent -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Set-CMStatusReportingComponent throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Set-CMStatusReportingComponent -MockWith { throw }

                    { Set-TargetResource @inputMismatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMStatusReportingComponent -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMStatusReportingComponent\Test-TargetResource' -Tag 'Test'{
            BeforeAll{
                $getReturnAll = @{
                    SiteCode                   = 'Lab'
                    ClientLogChecked           = $true
                    ClientLogFailureChecked    = $true
                    ClientLogType              = 'AllMilestones'
                    ClientReportChecked        = $true
                    ClientReportFailureChecked = $true
                    ClientReportType           = 'AllMilestones'
                    ServerLogChecked           = $true
                    ServerLogFailureChecked    = $true
                    ServerLogType              = 'AllMilestones'
                    ServerReportChecked        = $true
                    ServerReportFailureChecked = $true
                    ServerReportType           = 'AllMilestones'
                }

                $inputMismatch = @{
                    SiteCode                   = 'Lab'
                    ClientLogChecked           = $true
                    ClientLogFailureChecked    = $false
                    ClientLogType              = 'AllMilestones'
                    ClientReportChecked        = $true
                    ClientReportFailureChecked = $false
                    ClientReportType           = 'AllMilestones'
                    ServerLogChecked           = $true
                    ServerLogFailureChecked    = $true
                    ServerLogType              = 'ErrorAndWarningMilestones'
                    ServerReportChecked        = $true
                    ServerReportFailureChecked = $true
                    ServerReportType           = 'ErrorMilestones'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource' {
                BeforeEach{
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                }

                It 'Should return desired result true when all returned values match inputs' {

                    Test-TargetResource @getReturnAll | Should -Be $true
                }

                It 'Should return desired result false when there is a mismatch between returned values and inputs' {

                    Test-TargetResource @inputMismatch | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
