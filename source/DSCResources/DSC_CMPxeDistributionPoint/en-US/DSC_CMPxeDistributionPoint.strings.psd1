ConvertFrom-StringData @'
    RetrieveSettingValue = Getting results for Configuration Manager collection.
    DistroPointInstall   = The Distribution Point role on {0} is not installed, run DSC_CMDistibutionPoint to install the role.
    PxePassword          = Expected Pxe password to be set.
    TestState            = Test-TargetResource compliance check returned: {0}.
    PxeThrow             = Can not specify PXE settings when PXE is currently or setting to $false, please set EnablePxe to $true.
    NonWdsThrow          = You can not enable nonWDSPxe while multicast is set to enabled.
    SettingValue         = Setting value: {0} to {1}.
    SetPxePassword       = Expected a Pxe password to be used, setting Pxe password.
'@
