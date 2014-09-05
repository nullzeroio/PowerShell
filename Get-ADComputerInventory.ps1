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
#>

#Requires -Version 3
#Requires -Module ActiveDirectory

[cmdletbinding(PositionalBinding = $true)]
param (
	[parameter(Mandatory = $false,
			   HelpMessage = "Enter NT domain name or FQDN of a know domain controller ",
			   Position = 0,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[string[]]$Domain = $env:USERDOMAIN,

	[parameter(Mandatory = $false,
			   HelpMessage = "Enter OS name or wildcard ",
			   Position = 1,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[string]$OperatingSystem = 'Server'
) # end param

BEGIN
{
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop		# Set EA preference to 'Stop' in order to force all errors to be terminating for error handling

	$Properties = @(# Define which properties will be pulled from the computer objects and store them in an array
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

}# end BEGIN

PROCESS
{
	foreach ($D in $Domain)		# iterate through the domains provided and run Get-ADComputer against each
	{
		try		# try/catch block - provide basic error handling as it connects to each domain
		{
			Write-Verbose -Message "Working on $d"

			Get-AdComputer -Server $D -LDAPFilter "(OperatingSystem=*$OperatingSystem*)" -Properties $Properties | Select-Object $Properties

		} catch
		{
			Write-Warning -Message "$D - $_"

		}# end try/catch

	}# end foreach

}# end PROCESS




