<#
.SYNOPSIS
	Get all AD computers running a supplied operating system in the specified domain.
.DESCRIPTION
	Get all AD computers running a supplied operating system in the specified domain.

	Some pre-formatting was done to organize columns but export formatting should be done via the pipeline using your export option of choice.

	This script also assumes that you have the proper access to at least read/query Active Directory
.PARAMETER Domain
	Enter the domain or domains that you wish to report on; by default it will select the domain the current user is in
.PARAMETER OperatingSystem
	Enter the OS name you wish to return systems from; the default is 'Server'
.EXAMPLE
	.\Get-ADComputerInventory.ps1 -Domain CorpDomainA -OperatingSystem 'Server' -Verbose

	This should return all objects running a windows server OS
.EXAMPLE
	.\Get-ADComputerInventory.ps1 -Domain CorpDomainA,CorpDomainB -OperatingSystem '7' -Verbose | Format-Table Name,Location,OperatingSystem -AutoSize

	This should return all objects running Windows 7 across two domains CorpDomainA & CorpDomainB
.INPUTS
	System.String
.OUTPUTS
	Selected.Microsoft.ActiveDirectory.Management.ADComputer
.NOTES
	20140904	K. Kirkpatrick	Updated

	#TAG:PUBLIC
		
			GitHub: https://github.com/vScripter
			Twitter: @vScripter
			Email: kevin@vmotioned.com
			Blog: www.vMotioned.com
	
	[-------------------------------------DISCLAIMER-------------------------------------]
	 All script are provided as-is with no implicit
	 warranty or support. It's always considered a best practice
	 to test scripts in a DEV/TEST environment, before running them
	 in production. In other words, I will not be held accountable
	 if one of my scripts is responsible for an RGE (Resume Generating Event).
	 If you have questions or issues, please reach out/report them on
	 my GitHub page. Thanks for your support!
	[-------------------------------------DISCLAIMER-------------------------------------]
	
.LINK
	https://github.com/vScripter
#>

#Requires -Version 3
#Requires -Module ActiveDirectory

[cmdletbinding(PositionalBinding = $true)]
param (
	[parameter(Mandatory = $false,
			   HelpMessage = "Enter NT domain name or FQDN of a know domain controller ",
			   Position = 0)]
	[string[]]$Domain = $env:USERDOMAIN,

	[parameter(Mandatory = $false,
			   HelpMessage = "Enter OS name or wildcard ",
			   Position = 1)]
	[string]$OperatingSystem = 'Server'
) # end param

BEGIN {
	
	# Define which properties will be pulled from the computer objects and store them in an array
	$Properties = @(		
	'Name',
	'DNSHostName',
	'Location',
	'IPv4Address',
	'Description',
	'OperatingSystem',
	'OperatingSystemServicePack',
	'Enabled',
	'LastLogonDate',
	'logonCount',
	'Created',
	'PasswordLastSet',
	'CanonicalName')

} # end BEGIN block

PROCESS
{
	foreach ($D in $Domain)
	{
		try	
		{
			Write-Verbose -Message "Working on $d"

			Get-AdComputer -Server $D -LDAPFilter "(OperatingSystem=*$OperatingSystem*)" -Properties $Properties -ErrorAction 'Stop' | Select-Object $Properties

		} catch
		{
			Write-Warning -Message "$D - $_"

		} # end try/catch

	} # end foreach
	
} # end PROCESS block

END {
	#
} # end END block




