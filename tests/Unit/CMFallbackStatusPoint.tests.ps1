[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

BeforeAll {
    $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMFallbackStatusPoint'

    # Import Stub function
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue

    # Import DscResource.Test Module
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    # Variables used for each Initialize-TestEnvironment
    $initalize = @{
        DSCModuleName   = 'ConfigMgrCBDsc'
        DSCResourceName = 'DSC_CMFallbackStatusPoint'
        ResourceType    = 'Mof'
        TestType        = 'Unit'
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMFallbackStatusPoint\Get-TargetResource' -Tag 'Get'{
    BeforeAll{
        $testEnvironment = Initialize-TestEnvironment @initalize

        $getInput = @{
            SiteCode       = 'Lab'
            SiteServerName = 'FSP01.contoso.com'
        }

        $getFspReturn = @{
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

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When retrieving fallback status point settings' {

        It 'Should return desired result when fallback status point is not currently installed' {
            Mock -CommandName Get-CMFallbackStatusPoint

            $result = Get-TargetResource @getInput
            $result                   | Should -BeOfType System.Collections.HashTable
            $result.SiteCode          | Should -Be -ExpectedValue 'Lab'
            $result.SiteServerName    | Should -Be -ExpectedValue 'FSP01.contoso.com'
            $result.StateMessageCount | Should -BeNullOrEmpty
            $result.ThrottleSec       | Should -BeNullOrEmpty
            $result.Ensure            | Should -Be -ExpectedValue 'Absent'
        }

        It 'Should return desired result when fallback status point is currently installed' {
            Mock -CommandName Get-CMFallbackStatusPoint -MockWith { $getFspReturn }

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
        $testEnvironment = Initialize-TestEnvironment @initalize

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

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint
        Mock -CommandName Set-Location
        Mock -CommandName Get-CMSiteSystemServer
        Mock -CommandName New-CMSiteSystemServer
        Mock -CommandName Add-CMFallbackStatusPoint
        Mock -CommandName Set-CMFallbackStatusPoint
        Mock -CommandName Remove-CMFallbackStatusPoint
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When Set-TargetResource runs successfully' {

        It 'Should call expected commands for when changing settings' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Set-TargetResource @inputMismatch
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Remove-CMFallbackStatusPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands when fallback status point is absent' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

            Set-TargetResource @getReturnAll
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke Add-CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Remove-CMFallbackStatusPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands when fallback status point exists and expected absent' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

            Set-TargetResource @inputAbsent
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMFallbackStatusPoint -Exactly 1 -Scope It
        }
    }

    Context 'When Set-TargetResource throws' {

        It 'Should call expected commands and throw if Get-CMSiteSystemServer throws' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
            Mock -CommandName Get-CMSiteSystemServer -MockWith { throw }

            { Set-TargetResource @getReturnAll } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMFallbackStatusPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if New-CMSiteSystemServer throws' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
            Mock -CommandName New-CMSiteSystemServer -MockWith { throw }

            { Set-TargetResource @getReturnAll } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke Add-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMFallbackStatusPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if Add-CMFallbackStatusPoint throws' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
            Mock -CommandName New-CMSiteSystemServer -MockWith { $true }
            Mock -CommandName Add-CMFallbackStatusPoint -MockWith { throw }

            { Set-TargetResource @getReturnAll } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 1 -Scope It
            Should -Invoke Add-CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMFallbackStatusPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if Set-CMFallbackStatusPoint throws' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
            Mock -CommandName Set-CMFallbackStatusPoint -MockWith { throw }

            { Set-TargetResource @inputMismatch } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Remove-CMFallbackStatusPoint -Exactly 0 -Scope It
        }

        It 'Should call expected commands and throw if Remove-CMFallbackStatusPoint throws' {
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
            Mock -CommandName Remove-CMFallbackStatusPoint -MockWith { throw }

            { Set-TargetResource @inputAbsent } | Should -Throw
            Should -Invoke Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint -Exactly 1 -Scope It
            Should -Invoke Set-Location -Exactly 2 -Scope It
            Should -Invoke Get-TargetResource -Exactly 1 -Scope It
            Should -Invoke Get-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke New-CMSiteSystemServer -Exactly 0 -Scope It
            Should -Invoke Add-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Set-CMFallbackStatusPoint -Exactly 0 -Scope It
            Should -Invoke Remove-CMFallbackStatusPoint -Exactly 1 -Scope It
        }
    }
}

Describe 'ConfigMgrCBDsc - DSC_CMFallbackStatusPoint\Test-TargetResource' -Tag 'Test'{
    BeforeAll{
        $testEnvironment = Initialize-TestEnvironment @initalize

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

        Mock -CommandName Import-ConfigMgrPowerShellModule -ModuleName DSC_CMFallbackStatusPoint
        Mock -CommandName Set-Location
    }
    AfterAll {
        Restore-TestEnvironment -TestEnvironment $testEnvironment
    }

    Context 'When running Test-TargetResource and Get-TargetResource Returns ' {
        BeforeEach{
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
        }

        It 'Should return desired result false when ensure = absent and FSP is present' {

            Test-TargetResource @inputAbsent | Should -BeFalse
        }

        It 'Should return desired result true when all returned values match inputs' {

            Test-TargetResource @getReturnAll | Should -BeTrue
        }

        It 'Should return desired result false when there is a mismatch between returned values and inputs' {

            Test-TargetResource @inputMismatch | Should -BeFalse
        }
    }

    Context 'When running Test-TargetResource and Get-TargetResource Returns absent' {
        BeforeEach{
            Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
        }

        It 'Should return desired result false when ensure = present and FSP is absent' {

            Test-TargetResource @inputPresent  | Should -BeFalse
        }

        It 'Should return desired result true when ensure = absent and FSP is absent' {

            Test-TargetResource @inputAbsent | Should -BeTrue
        }
    }
}
