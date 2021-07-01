# Pure Storage PowerShell Toolkit

## Version: 2.0.0.0

### Pure Storage PowerShell Toolkit Release Notes

The new version of the Pure Storage PowerShell Toolkit leverages a number of different cmdlets ranging from core Windows Server, WMI, WSMAN, VMware PowerCLI, SQL Server and .NET assemblies.

The Pure Storage PowerShell Toolkit is an open source project that provides additional cmdlets that leverage core Windows Server, System Center, WMI, WSMAN, SQL Server, Storage and .NET Assemblies. The intention of the PowerShell Toolkit is to provide useful cmdlets for customers and the Pure Storage field to use in troubleshooting, monitoring, reporting, best practices and configuration. The PowerShell Toolkit leverages the Pure Storage PowerShell SDK from some of the cmdlets.

### Updates

* TBD

### Release Compatibility

* This release requires PowerShell 3.0 or higher.
* This release requires .NET 4.5 minimum.
* This release is compatible with the Pure Storage PowerShell SDK 1.7.4.0 and greater.
* This release requires a 64-bit operating system.

### Install and Uninstall

The Pure Storage PowerShell Toolkit is distrbuted through the [PowerShell Gallery](https://www.powershellgallery.com/packages/PureStoragePowerShellToolkit).

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
