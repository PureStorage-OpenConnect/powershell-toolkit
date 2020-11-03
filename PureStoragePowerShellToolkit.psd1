<#
	===========================================================================
	Created by:   	opensource@purestorage.com
	Organization: 	Pure Storage, Inc.
	Filename:     	PureStoragePowerShellToolkit.psd1
	Copyright:		(c) 2020 Pure Storage, Inc.
	Module Name: 	PureStoragePowerShellToolkit
	Description: 	PowerShell Script Module Manifest (.psd1)
	-------------------------------------------------------------------------
	Disclaimer
 	The sample script and documentation are provided AS IS and are not supported by
	the author or the author's employer, unless otherwise agreed in writing. You bear
	all risk relating to the use or performance of the sample script and documentation.
	The author and the author's employer disclaim all express or implied warranties
	(including, without limitation, any warranties of merchantability, title, infringement
	or fitness for a particular purpose). In no event shall the author, the author's employer
	or anyone else involved in the creation, production, or delivery of the scripts be liable
	for any damages whatsoever arising out of the use or performance of the sample script and
	documentation (including, without limitation, damages for loss of business profits,
	business interruption, loss of business information, or other pecuniary loss), even if
	such person has been advised of the possibility of such damages.
	===========================================================================
#>

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\PureStoragePowerShellToolkit.psm1'

# Version number of this module.
ModuleVersion = '2.0.0.0'

# Supported PSEditions
#CompatiblePSEditions = 'Desktop'

# ID used to uniquely identify this module
GUID = 'e7b43c4e-8e89-4e4f-9112-18d19107ada9'

# Author of this module
Author = 'opensource@purestorage.com'

# Company or vendor of this module
CompanyName = 'Pure Storage, Inc.'

# Copyright statement for this module
Copyright = '(c) 2020 Pure Storage, Inc. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Pure Storage PowerShell Toolkit.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
DotNetFrameworkVersion = '4.5'

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
# FunctionsToExport = @()

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
# AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'PureStorage'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PureStorage-OpenConnect/PowerShell-Toolkit/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PureStorage-OpenConnect/PowerShell-Toolkit'

        # A URL to an icon representing this module.
        IconUri = 'https://github.com/PureStorage-OpenConnect/PowerShell-Toolkit/blob/master/Installer/icon.ico'

        # ReleaseNotes of this module
        ReleaseNotes = 'Pure Storage PowerShell Toolkit.'

        # External dependent modules of this module
        # ExternalModuleDependencies = ''

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

