# Pure Storage PowerShell-Toolkit

Pure Storage PowerShell Toolkit 4.0 Release Notes
The Pure Storage PowerShell Toolkit provides ...

RELEASE COMPATIBILITY
This release requires PowerShell 3.0 or higher.
This release requires .NET 4.5 minimum.
This release is compatible with the Pure Storage PowerShell SDK 1.7.4.0 and greater.
This release requires a 64-bit operating system. 

INSTALL AND UNINSTALL
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

The PowerShell Toolkit can be uninstalled from "Programs and Features" of the Control Panel.

All releases of the Pure Storage PowerShell Toolkit will be distributing through the PowerShell Gallery, https://powershellgallery.com.