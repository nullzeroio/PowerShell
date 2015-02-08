<#
.SYNOPSIS
	Report back information on the local built-in 'Administrator' account
.DESCRIPTION
	Report back information on the local built-in 'Administrator' account.

	The query looks for local accounts that have a SID ending in -500
.PARAMETER ComputerName
	Name of computer you wish to report on
.INPUTS
	System.String
.OUTPUTS
	System.Management.Automation.PSCustomObject
.EXAMPLE
	.\Get-LocalAdmin.ps1 -ComputerName SERVER01.corp.com -Verbose | Format-Table -AutoSize
.EXAMPLE
	.\Get-LocalAdmin.ps1 -ComputerName (Get-Content C:\Servers.txt) -Verbose | Export-Csv C:\LocalAdminAccountAudit.csv -NoTypeInformation
.NOTES
	20150204	K. Kirkpatrick
	[+] Created

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
.LINK
	http://support.microsoft.com/kb/243330?wa=wsignin1.0
#>

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true,
			   Position = 0)]
	[System.String[]]$ComputerName
)

BEGIN {


} # end BEGIN block


PROCESS {

	Foreach ($computer in $ComputerName) {
		$objLocalAdmin = @()
		$PrincipalContext = $null
		$UserPrincipal = $null
		$Searcher = $null
		$results = $null

		Write-Verbose -Message "Working on $computer"
		try {
			Add-Type -AssemblyName System.DirectoryServices.AccountManagement
			$PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $computer)
			$UserPrincipal = New-Object System.DirectoryServices.AccountManagement.UserPrincipal($PrincipalContext)
			$Searcher = New-Object System.DirectoryServices.AccountManagement.PrincipalSearcher
			$Searcher.QueryFilter = $UserPrincipal
			$results = $Searcher.FindAll() | Where-Object { $_.Sid -Like "*-500" }

			$objLocalAdmin = [PSCustomObject] @{
				ComputerName = $computer
				Name = $Results.Name
				SID = $Results.SID
				Description = $Results.Description
				Enabled = $Results.Enabled
				PasswordNeverExpires = $Results.PasswordNeverExpires
				PasswordNotRequired = $Results.PasswordNotRequired
				LastLogon = $Results.LastLogon
				LastPasswordSet = $Results.LastPasswordSet
				UserCannotChangePassword = $Results.UserCannotChangePassword
			} # end $objLocalAdmin

			$objLocalAdmin

		} catch {
			Write-Warning -Message "[$computer] $($_.Exception.Message)"

			$objLocalAdmin = [PSCustomObject] @{
				ComputerName = $computer
				Name = "ERROR - $_"
				SID = 'N/A'
				Description = 'N/A'
				Enabled = 'N/A'
				PasswordNeverExpires = 'N/A'
				PasswordNotRequired = 'N/A'
				LastLogon = 'N/A'
				LastPasswordSet = 'N/A'
				UserCannotChangePassword = 'N/A'
			} # end $objLocalAdmin

			$objLocalAdmin

		} # end try/catch
	} # end foreach $computer

} # end PROCESS block

END {

	# clean up here

} # end END block