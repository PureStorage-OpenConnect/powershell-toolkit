<#	
	===========================================================================
	 Created by:   	barkz@purestorage.com
	 Organization: 	Pure Storage, Inc.
	 Filename:     	PowerShell-Toolkit.psd1
	 Copyright:		(c) 2016 Pure Storage, Inc.
	-------------------------------------------------------------------------
	Module Name: PowerShell-Toolkit

	Disclaimer
 	The sample script and documentation are provided AS IS and are not supported by 
	the author or the author’s employer, unless otherwise agreed in writing. You bear 
	all risk relating to the use or performance of the sample script and documentation. 
	The author and the author’s employer disclaim all express or implied warranties 
	(including, without limitation, any warranties of merchantability, title, infringement 
	or fitness for a particular purpose). In no event shall the author, the author’s employer 
	or anyone else involved in the creation, production, or delivery of the scripts be liable 
	for any damages whatsoever arising out of the use or performance of the sample script and 
	documentation (including, without limitation, damages for loss of business profits, 
	business interruption, loss of business information, or other pecuniary loss), even if 
	such person has been advised of the possibility of such damages.
	===========================================================================
#>

@{
	
	# Script module or binary module file associated with this manifest.
	RootModule = 'PowerShell-Toolkit.psm1'
	
	# Version number of this module; major.minor[.build[.revision]]
	ModuleVersion = '3.1.0.0'
	
	# ID used to uniquely identify this module
	GUID = '80ed4b74-cd66-4428-b4dd-db839991c2d6'
	
	# Author of this module
	Author = 'barkz@purestorage.com'
	
	# Company or vendor of this module
	CompanyName = 'Pure Storage Inc.'
	
	# Copyright statement for this module
	Copyright = '(c) 2016 Pure Storage, Inc. All rights reserved.'
	
	# Description of the functionality provided by this module
	Description = 'Pure Storage PowerShell Toolkit 3.x built on the PureStorge PowerShell SDK 1.5.4.0.'
		
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '3.0'
	
	# Name of the Windows PowerShell host required by this module
	PowerShellHostName = ''
	
	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion = ''
	
	# Minimum version of Microsoft .NET Framework required by this module
	DotNetFrameworkVersion = '4.5'
	
	# Minimum version of the common language runtime (CLR) required by this module
	CLRVersion = ''
	
	# Processor architecture (None, X86, Amd64) required by this module
	ProcessorArchitecture = 'None'
	
	# Modules that must be imported into the global environment prior to importing this module
	RequiredModules = 'PureStoragePowerShellSDK'
	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies = @()
	
	# Script files (.ps1) that are run in the caller's environment prior to importing this module.
	ScriptsToProcess = @()
	
	# Type files (.ps1xml) to be loaded when importing this module
	TypesToProcess = @()
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @()
	
	# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
	NestedModules = @()
	
	# Functions to export from this module
	FunctionsToExport = '*'
	
	# Cmdlets to export from this module
	CmdletsToExport = '*'
	
	# Variables to export from this module
	VariablesToExport = '*'
	
	# Aliases to export from this module
	AliasesToExport = '*'
	
	# List of all modules packaged with this module
	ModuleList = @()
	
	# List of all files packaged with this module
	FileList = @()
	
	# Private data to pass to the module specified in ModuleToProcess
	PrivateData = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()
			
			# A URL to the license for this module.
			# LicenseUri = ''
			
			# A URL to the main website for this project.
			# ProjectUri = ''
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			# ReleaseNotes = ''
		}		
	}
	
	# HelpInfo URI of this module
	HelpInfoURI = 'http://connect.pure1.purestorage.com/powershell/PureStoragePowerShellToolkit'
	
	# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
	DefaultCommandPrefix = ''
	
}







