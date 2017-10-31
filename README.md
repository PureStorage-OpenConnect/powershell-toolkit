# Pure Storage PowerShell-Toolkit

Pure Storage PowerShell Toolkit 4.0 Release Notes
The Pure Storage PowerShell Toolkit provides ...

RELEASE COMPATIBILITY

* This release requires PowerShell 3.0 or higher.
* This release requires .NET 4.5 minimum.
* This release is compatible with the Pure Storage PowerShell SDK 1.7.4.0 and greater.
* This release requires a 64-bit operating system. 

INSTALL AND UNINSTALL

The Pure Storage PowerShell Toolkit is distrbuted through the PowerShell Gallery (https://www.powershellgallery.com). 

* [Pure Storage PowerShell Toolkit](https://www.powershellgallery.com/packages/PureStoragePowerShellToolkit/)
* [Pure Storage PowerShell SDK](https://www.powershellgallery.com/packages/PureStoragePowerShellSDK/) (Required)

To install the Pure Storage PowerShell Toolkit open up an elevated Windows PowerShell session and type:

```powershell
Install-Module -Name PureStoragePowerShellToolkit 
```

To verify the installation:
```powershell
Get-Module -Name PureStoragePowerShellToolkit
```

To see the available cmdlets:
```powershell
Get-Command -Module PureStoragePowerShellToolkit
```