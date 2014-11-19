<#
.SYNOPSIS
	Search a computer/s for the install status of a particular Microsoft HotFix (Patch)
.DESCRIPTION
	Search a computer/s for the install status of a particular Microsoft HotFix (Patch)

	You must supply the hotfix name in the format of KBxxxxxxx (EX: KB3011768)
.PARAMETER ComputerName
	Name of computer / computers
.PARAMETER HotFixID
	Name of HotFix to search for
.INPUTS
	System.String
.OUTPUTS
	System.Management.Automation.PSCustomObject
.EXAMPLE
	.\Get-HotFixStatus.ps1 -ComputerName SERVER1.corp.com, SERVER2.corp.com -Verbose | Format-Table -Autosize
.EXAMPLE
	.\Get-HotFixStatus.ps1 -ComputerName (Get-Content C:\ServerList.txt) -Verbose | Export-Csv C:\ServerPatchReport.csv -NoTypeInformation
.NOTES
	20141119	K. Kirkpatrick		Created


	#TAG:PUBLIC

	GitHub:	 https://github.com/vN3rd
	Twitter:  @vN3rd
	Email:	 kevin@pinelabs.co

[-------------------------------------DISCLAIMER-------------------------------------]
 All script are provided as-is with no implicit
 warranty or support. It's always considered a best practice
 to test scripts in a DEV/TEST environment, before running them
 in production. In other words, I will not be held accountable
 if one of my scripts is responsible for an RGE (Resume Generating Event).
 If you have questions or issues, please reach out/report them on
 my GitHub page. Thanks for your support!
[-------------------------------------DISCLAIMER-------------------------------------]
#>


[cmdletbinding(DefaultParameterSetName = "Default")]
param (
	[parameter(Mandatory = $false,
			   Position = 0,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[alias("Comp", "CN")]
	[string[]]$ComputerName = "$(hostname)",

	[parameter(Mandatory = $true,
			   Position = 1,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true,
			   HelpMessage = "Enter full HotFix ID (ex: KB1234567) ")]
	[alias("HotFix", "Patch")]
	[validatepattern('^KB\d{7}$')]
	[string]$HotFixID
)

BEGIN
{
		# Set global EA pref so that all errors are treated as terminating and get caught in the 'catch' block
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

}# BEGIN

PROCESS
{
	foreach ($C in $ComputerName)
	{
			# Create counter variable and increment by 1 for each item in the collection
		$i++

			# Call out variables and set/reset values
		$hotfixQuery = $null
		$objCollection = @()

			# If connectivity to remote system is successful, continue
		if (Test-Connection $C -Count 2 -Quiet)
		{
			try
			{
				Write-Verbose -Message "Searching for HotFix ID $($HotFixID.toupper()) on $($C.toupper())"

				$hotfixQuery = Get-HotFix -Id $HotFixID -ComputerName $C | Select-Object Source, Description, HotFixID, InstalledBy, InstalledOn

					# Create obj for reachable systems
				$objHotFix = [PSCustomObject] @{
					SystemName = $C.ToUpper()
					Description = $hotfixQuery.Description
					HotFixID = $hotfixQuery.HotFixID
					InstalledBy = $hotfixQuery.InstalledBy
					InstalledOn = $hotfixQuery.InstalledOn
					Error = if ($hotfixQuery.HotFixID -eq $null) { "HotFix $($HotFixID.toupper()) does not appear to be installed" }
				}# $objSvc

					# Add the results to the $objCollection array
				$objCollection += $objHotFix

					<# Add the contents of the $objCollection array to the $Results variable. This may seem redundant
					but we are clearing the the $objCollection variable on each interation through foreach, in order
					to maintain data integrety. The $Results variable is storing the summation of all interations #>
				$Results += $objCollection

			} catch
			{
				Write-Warning -Message "$C - $_"

					# Create obj for systems that are reachable but incur an error
				$objWarn = [PSCustomObject] @{
					SystemName = [string]$C
					Error = $_
				}# $objWarn

					# See the comment in the 'try' block for detail on $objCollection & $Results variables
				$objCollection += $objWarn
				$Results += $objCollection

			}# try/catch
		} else
		{
			Write-Warning -Message "$C is unreachable"

				# Create obj for systems that are not reachable
			$objDown = [PSCustomObject] @{
				SystemName = [string]$C
				Error = "$C is unreachable"
			}# $objDown

				# See the comment in the first 'try' block for detail on $objCollection & $Results variables
			$objCollection += $objDown
			$Results += $objCollection

		}# else

			# Write total progress to progress bar
		$TotalServers = $ComputerName.Length
		$PercentComplete = [int](($i / $TotalServers) * 100)
		Write-Progress -Activity "Working..." -CurrentOperation "$PercentComplete% Complete" -Status "Percent Complete" -PercentComplete $PercentComplete

	}# foreach
}# PROCESS

END
{
		# Call the results object
	$Results

}# END