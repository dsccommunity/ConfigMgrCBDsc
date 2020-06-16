param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMServiceConnectionPoint'

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
        Describe 'ConfigMgrCBDsc - DSC_CMServiceConnectionPoint\Get-TargetResource' -Tag 'Get'{
            BeforeAll{
                $getInput = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                }

                $getSCPReturn = @{
                    Props = @(
                        @{
                            PropertyName = 'OfflineMode'
                            Value        = '0'
                        }
                    )
                }

                $getSCPReturnOffline = @{
                    Props = @(
                        @{
                            PropertyName = 'OfflineMode'
                            Value        = '1'
                        }
                    )
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving service connection point settings' {
                It 'Should return desired result when service connection point is not currently installed' {
                    Mock -CommandName Get-CMServiceConnectionPoint

                    $result = Get-TargetResource @getInput
                    $result                | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode       | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.Mode           | Should -Be -ExpectedValue $null
                    $result.Ensure         | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when service connection point is currently installed in online mode' {
                    Mock -CommandName Get-CMServiceConnectionPoint -MockWith { $getSCPReturn }

                    $result = Get-TargetResource @getInput
                    $result                | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode       | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.Mode           | Should -Be -ExpectedValue 'Online'
                    $result.Ensure         | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result when service connection point is currently installed in offline mode' {
                    Mock -CommandName Get-CMServiceConnectionPoint -MockWith { $getSCPReturnOffline }

                    $result = Get-TargetResource @getInput
                    $result                | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode       | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName | Should -Be -ExpectedValue 'CA01.contoso.com'
                    $result.Mode           | Should -Be -ExpectedValue 'Offline'
                    $result.Ensure         | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMServiceConnectionPoint\Set-TargetResource' -Tag 'Set'{
            BeforeAll{
                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Ensure         = 'Absent'
                }

                $inputMismatch = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Mode           = 'Offline'
                    Ensure         = 'Present'
                }

                $getReturnAll = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Mode           = 'Online'
                    Ensure         = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Mode           = $null
                    Ensure         = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Add-CMServiceConnectionPoint
                Mock -CommandName Set-CMServiceConnectionPoint
                Mock -CommandName Remove-CMServiceConnectionPoint
            }

            Context 'When Set-TargetResource runs successfully' {

                It 'Should call expected commands for when changing settings' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputMismatch
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when the service connection point is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @getReturnAll
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when the service connection point exists and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {

                It 'Should call expected commands and throw if Add-CMServiceConnectionPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Add-CMServiceConnectionPoint -MockWith { throw }

                    { Set-TargetResource @getReturnAll } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Set-CMServiceConnectionPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Set-CMServiceConnectionPoint -MockWith { throw }

                    { Set-TargetResource @inputMismatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Remove-CMServiceConnectionPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Remove-CMServiceConnectionPoint -MockWith { throw }

                    { Set-TargetResource @inputAbsent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMServiceConnectionPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMServiceConnectionPoint -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMServiceConnectionPoint\Test-TargetResource' -Tag 'Test'{
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

                $inputMismatch = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Mode           = 'Offline'
                    Ensure         = 'Present'
                }

                $getReturnAll = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Mode           = 'Online'
                    Ensure         = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'CA01.contoso.com'
                    Mode           = $null
                    Ensure         = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource and Get-TargetResource Returns ' {
                BeforeEach{
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                }

                It 'Should return desired result false when ensure = absent and role is present' {

                    Test-TargetResource @inputAbsent | Should -Be $false
                }

                It 'Should return desired result true when all returned values match inputs' {

                    Test-TargetResource @getReturnAll | Should -Be $true
                }

                It 'Should return desired result false when there is a mismatch between returned values and inputs' {

                    Test-TargetResource @inputMismatch | Should -Be $false
                }
            }

            Context 'When running Test-TargetResource and Get-TargetResource Returns absent' {
                BeforeEach{
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                }

                It 'Should return desired result false when ensure = present and role is absent' {

                    Test-TargetResource @inputPresent  | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent and role is absent' {

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
