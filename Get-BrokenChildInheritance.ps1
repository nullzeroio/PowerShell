#========================================================================
# Created with: SAPIEN Technologies, Inc., PowerShell Studio 2012 v3.1.29
# Created on:   2/2/2014 11:06 AM
# Created by:   Steven Slocum & Kevin Kirkpatrick
# Organization:
# Filename:     Get-BrokenChildInheritance.ps1
#========================================================================

<#
.SYNOPSIS
 Recurse through a directory structure and for the directories where inheritance is broken and get the ACL details.

.DESCRIPTION
Recurse through a directory structure and for the directories where inheritance is broken and get the ACL details.

This script will produce inaccurate results if you do not have access to all directories and sub directories.

Running SubInAcl may be required.

.PARAMETER <RootPath>

.INPUTS
 None. This script does not accept pipeline input.

.EXAMPLE
./Get-BrokenChildInheritance.ps1 -RootPath 'C:\Test Source' -Verbose

This will recurse through the sub directories within the C:\Test Source directory. Use the -Verbose switch to output details about what the script is currently doing.

.NOTES

TAG:PUBLIC
#>

[cmdletbinding()]
param(
[parameter(mandatory=$true)][String]$RootPath
)

# Set the exported file name and path
$ExportFile = 'C:\Directory Permissions.csv'

Write-Verbose "Deleting current file, if it exists..."

# If the export file exists, delete it
if(Test-Path $ExportFile)
	{
		Remove-Item $ExportFile -Force
	}

# Setup hash tables for collecting and formatting data
	# Check if inheritance is broken. This is a boolean True/False value
$inheritance = @{Label = 'Broken Inheritance';Expression = {$_.getaccesscontrol().AreAccessRulesProtected}}
	# Get the ACL of the directory.  'Access' is the property value we want to read, but due to the type of object it is, we
	# need to call the .tostring() method immidiately after, in order to grab the string data, which is why it appears as 'accesstostring.'
	# instead of 'access.tostring.'
$permission = @{Label = 'Group';Expression = {$_.getaccesscontrol().Accesstostring.split()}}
	# Get the full path of the directory
$fullpath = @{Label='Path';expression={$_.fullname}}

Write-Verbose "Recursing through all child directories..."

# Use Get-ChildItem to recurse through the directories under the selected root path and pass the 'directory' attribute through the pipeline
# to the select statement/hash tables and then export the data to .csv
get-childitem -attributes directory -recurse $rootpath | Select-Object $fullpath,$inheritance,lastwritetime,$permission |
Where-Object 'Broken Inheritance' -eq "TRUE" | Export-Csv $ExportFile -Append -NoTypeInformation -Force

Write-Verbose "Opening File..."

# Open the file
Invoke-Item $ExportFile

Write-Verbose "Done!"
