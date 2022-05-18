# Pure Storage PowerShell Toolkit

![GitHub all releases](https://img.shields.io/github/downloads/PureStorage-Connect/PowerShellSDK/total?color=orange&label=GitHub%20downloads&logo=powershell&style=plastic) ![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PureStoragePowerShellSDK?color=orange&label=PSGallery%20downloads&logo=powershell&style=plastic)
[![PSScriptAnalyzer](https://github.com/PureStorage-OpenConnect/powershell-toolkit/actions/workflows/psanalyzer-codecheck.yml/badge.svg?branch=dev)](https://github.com/PureStorage-OpenConnect/powershell-toolkit/actions/workflows/psanalyzer-codecheck.yml)

The Pure Storage PowerShell Toolkit is an open source project that provides cmdlets for Pure Storage FlashArray and Windows Server. The intention of the PowerShell Toolkit is to provide useful cmdlets for customers and the Pure Storage Field Support to use in troubleshooting, monitoring, reporting, best practices, and configuration. The PowerShell Toolkit leverages the Pure Storage PowerShell SDK for some of the cmdlets.

### Pure Storage PowerShell Toolkit Release Notes

For a complete read of changes, please refer to the CHANGELOG.md file.

### Release History

- v2.0.4.0
- v2.0.3.3
- v2.0.3.1
- v2.0.2.0
- v2.0.1.0
- v2.0.0.0
- v1911.0
- v1903.7

### Release Compatibility

- This release requires PowerShell 5.1 or higher.
- This release requires .NET 4.5 minimum.
- This release is compatible with the PowerShell SDK 1.7.4.0 and greater.
- This release is not yet compatible with the PowerShell SDK version 2.
- This release requires a 64-bit operating system.

### Install and Uninstall

The very latest versions of the Toolkit are always available in this repository and in the PowerShell Gallery. There may be multiple branches that may contain alpha or beta code. The default "dev" branch contains "stable" code. The Pure Storage PowerShell Toolkit is also distrbuted through the [PowerShell Gallery](https://www.powershellgallery.com/packages/PureStoragePowerShellToolkit).

The tookit requires the PureStoragePowerShellSDK module by default for any functions that connect to a FlashArray. Other modules are also used for further functionaility with SQL, Excel output, etc. A built-in global function will attempt to download and install them if they are not present when the cmdlet is launched.

- [Pure Storage PowerShell SDK](https://www.powershellgallery.com/packages/PureStoragePowerShellSDK/) (Required)

To install the Pure Storage PowerShell Toolkit, open up an elevated Windows PowerShell session and type:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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

We welcome Pull Requests, issues, and open discussions around the toolkit. Help make the toolkit an invaluable tool!

### Pure Storage Code

[Join the Pure Storage Code Slack team](https://codeinvite.purestorage.com)
