param ()

$script:dscModuleName   = 'ConfigMgrCBDsc'
$script:dscResourceName = 'DSC_CMFallbackStatusPoint'

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
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMFallbackStatusPoint'

        Describe 'ConfigMgrCBDsc - DSC_CMFallbackStatusPoint\Get-TargetResource' -Tag 'Get'{
            BeforeAll{
                $getInput = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'FSP01.contoso.com'
                }

                $getFSPReturn = @{
                    SiteCode = 'Lab'
                    Props    = @(
                        @{
                            PropertyName = 'Throttle Count'
                            Value        = '10000'
                        }
                        @{
                            PropertyName = 'Throttle Interval'
                            Value        = '3600000'
                        }
                    )
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When retrieving fallback status point settings' {

                It 'Should return desired result when fallback status point is not currently installed' {
                    Mock -CommandName Get-CMFallbackStatusPoint -MockWith { $null }

                    $result = Get-TargetResource @getInput
                    $result                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode          | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName    | Should -Be -ExpectedValue 'FSP01.contoso.com'
                    $result.StateMessageCount | Should -Be -ExpectedValue $null
                    $result.ThrottleSec       | Should -Be -ExpectedValue $null
                    $result.Ensure            | Should -Be -ExpectedValue 'Absent'
                }

                It 'Should return desired result when fallback status point is currently installed' {
                    Mock -CommandName Get-CMFallbackStatusPoint -MockWith { $getFSPReturn }

                    $result = Get-TargetResource @getInput
                    $result                   | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode          | Should -Be -ExpectedValue 'Lab'
                    $result.SiteServerName    | Should -Be -ExpectedValue 'FSP01.contoso.com'
                    $result.StateMessageCount | Should -Be -ExpectedValue '10000'
                    $result.ThrottleSec       | Should -Be -ExpectedValue '3600'
                    $result.Ensure            | Should -Be -ExpectedValue 'Present'
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMFallbackStatusPoint\Set-TargetResource' -Tag 'Set'{
            BeforeAll{
                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'FSP01.contoso.com'
                    Ensure         = 'Absent'
                }

                $inputMismatch = @{
                    SiteCode          = 'Lab'
                    SiteServerName    = 'FSP01.contoso.com'
                    StateMessageCount = '10001'
                    ThrottleSec       = '3601'
                    Ensure            = 'Present'
                }

                $getReturnAll = @{
                    SiteCode          = 'Lab'
                    SiteServerName    = 'FSP01.contoso.com'
                    StateMessageCount = '10000'
                    ThrottleSec       = '3600'
                    Ensure            = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode          = 'Lab'
                    SiteServerName    = 'FSP01.contoso.com'
                    StateMessageCount = $null
                    ThrottleSec       = $null
                    Ensure            = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMFallbackStatusPoint
                Mock -CommandName Set-CMFallbackStatusPoint
                Mock -CommandName Remove-CMFallbackStatusPoint
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
                    Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when fallback status point is absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                    Set-TargetResource @getReturnAll
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands when fallback status point exists and expected absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                    Set-TargetResource @inputAbsent
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource throws' {

                It 'Should call expected commands and throw if Get-CMSiteSystemServer throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer -MockWith { throw }

                    { Set-TargetResource @getReturnAll } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if New-CMSiteSystemServer throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName Get-CMSiteSystemServer
                    Mock -CommandName New-CMSiteSystemServer -MockWith { throw }

                    { Set-TargetResource @getReturnAll } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Add-CMFallbackStatusPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                    Mock -CommandName New-CMSiteSystemServer -MockWith { $true }
                    Mock -CommandName Add-CMFallbackStatusPoint -MockWith { throw }

                    { Set-TargetResource @getReturnAll } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                    Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Set-CMFallbackStatusPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Set-CMFallbackStatusPoint -MockWith { throw }

                    { Set-TargetResource @inputMismatch } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                    Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                }

                It 'Should call expected commands and throw if Remove-CMFallbackStatusPoint throws' {
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                    Mock -CommandName Remove-CMFallbackStatusPoint -MockWith { throw }

                    { Set-TargetResource @inputAbsent } | Should -Throw
                    Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                    Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                    Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                    Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                    Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'ConfigMgrCBDsc - DSC_CMFallbackStatusPoint\Test-TargetResource' -Tag 'Test'{
            BeforeAll{
                $inputPresent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'FSP01.contoso.com'
                    Ensure         = 'Present'
                }

                $inputAbsent = @{
                    SiteCode       = 'Lab'
                    SiteServerName = 'FSP01.contoso.com'
                    Ensure         = 'Absent'
                }

                $inputMismatch = @{
                    SiteCode          = 'Lab'
                    SiteServerName    = 'FSP01.contoso.com'
                    StateMessageCount = '10001'
                    ThrottleSec       = '3601'
                    Ensure            = 'Present'
                }

                $getReturnAll = @{
                    SiteCode          = 'Lab'
                    SiteServerName    = 'FSP01.contoso.com'
                    StateMessageCount = '10000'
                    ThrottleSec       = '3600'
                    Ensure            = 'Present'
                }

                $getReturnAbsent = @{
                    SiteCode          = 'Lab'
                    SiteServerName    = 'FSP01.contoso.com'
                    StateMessageCount = $null
                    ThrottleSec       = $null
                    Ensure            = 'Absent'
                }

                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
            }

            Context 'When running Test-TargetResource and Get-TargetResource Returns ' {
                BeforeEach{
                    Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                }

                It 'Should return desired result false when ensure = absent and FSP is present' {

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

                It 'Should return desired result false when ensure = present and FSP is absent' {

                    Test-TargetResource @inputPresent  | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent and FSP is absent' {

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
