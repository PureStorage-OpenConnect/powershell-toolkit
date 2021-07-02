# Pure Storage PowerShell Toolkit

## Version: 2.0.0.0

### Pure Storage PowerShell Toolkit Release Notes

Version 2 of the Pure Storage PowerShell Toolkit adds several cmdlets for FlashArrays and Windows Server and enhances some legacy functions. For a complete read of changes, please refer to the CHANGELOG.md file.

The Pure Storage PowerShell Toolkit is an open source project that provides cmdlets for Pure Storage FlashArray and Windows Server. The intention of the PowerShell Toolkit is to provide useful cmdlets for customers and the Pure Storage Field Support to use in troubleshooting, monitoring, reporting, best practices, and configuration. The PowerShell Toolkit leverages the Pure Storage PowerShell SDK for some of the cmdlets.

### Release History

* v2.0.0.0 - Latest release
* v1.1911 - Latest GitHub repository release - located in the \v1.1911 folder.
* v1.1903.7 - Last PSGallery v1 release [PSGallery Link](https://www.powershellgallery.com/packages/PureStoragePowerShellToolkit/1903.7)

### Release Compatibility

* This release requires PowerShell 3.0 or higher.
* This release requires .NET 4.5 minimum.
* This release is compatible with the PowerShell SDK 1.7.4.0 and greater.
* This release is not yet compatible with the PowerShell SDK version 2.
* This release requires a 64-bit operating system.

### Install and Uninstall

* This release is compatible with the Pure Storage PowerShell SDK 1.7.4.0 and greater.
* This release requires a 64-bit operating system.

### Install and Uninstall

The Pure Storage PowerShell Toolkit is distrbuted through the [PowerShell Gallery](https://www.powershellgallery.com/packages/PureStoragePowerShellToolkit).


The Pure Storage PowerShell Toolkit is distrbuted through the [PowerShell Gallery](https://www.powershellgallery.com/packages/PureStoragePowerShellToolkit).
The tookit requires the PowerShell SDK. A built-in global function will attempt to download and install it if it is not present.

* [Pure Storage PowerShell Toolkit PSGallery Link](https://www.powershellgallery.com/packages/PureStoragePowerShellToolkit/)
* [Pure Storage PowerShell SDK PSGallery Link](https://www.powershellgallery.com/packages/PureStoragePowerShellSDK/) (Required)

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

To uninstall the module:

```powershell
Uninstall-Module -Module PureStoragePowerShellToolkit
```

### Please contribute!!

We welcome PRs, Issues, and open discussions around the toolkit. Help make the toolkit an invaluable tool!

### Pure Storage Code

[Join the Pure Storage Code Slack team](https://codeinvite.purestorage.com)

