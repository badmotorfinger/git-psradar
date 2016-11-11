﻿#
# Module manifest for module 'Get-PsRadar'
#
# Generated by: Vince Panuccio
#
# Generated on: 7/11/2015
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Git-PsRadar.psm1'

# Version number of this module.
ModuleVersion = '1.1.0'

# ID used to uniquely identify this module
GUID = '23f8b0ef-e319-4c31-b797-e1204d0e7eb7'

# Author of this module
Author = 'Vince Panuccio'

# Description of the functionality provided by this module
Description = 'A heads up display for git, enabled during a PowerShell session when entering a git repositoy. A PowerShell port of git-radar.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

FileList = 'Git-PsRadar.psm1'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

HelpInfoURI = 'https://github.com/vincpa/git-psradar'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('git', 'cli')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/vincpa/git-psradar/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/vincpa/git-psradar'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Fixed a bug which causes the prompt to not display the current path when in any other provider other than the FileSystem provider.'

    } # End of PSData hashtable

} # End of PrivateData hashtable



# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
