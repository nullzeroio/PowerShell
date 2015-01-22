<#
	.SYNOPSIS
		Returns information about the Processor via WMI.

	.DESCRIPTION
		Information about the processor is returned using the Win32_Processor WMI class.

		You can provide a single computer/server name or supply an array/list.

	.PARAMETER  Computers
		Single computer name, list of computers or .txt file containing a list of computers.

	.EXAMPLE
		.\Get-ProcessorInventory.ps1 -Computers (Get-Content C:\ComputerList.txt)

	.EXAMPLE
		.\Get-ProcessorInventory.ps1 -Computers Test-Server.company.com

	.EXAMPLE
		.\Get-ProcessorInventory.ps1 -Computers SERVER1.company.com,SERVER2.company.com | Format-Table -AutoSize

	.EXAMPLE
		.\Get-ProcessorInventory.ps1 -Computers SERVER1.company.com,SERVER2.company.com | Export-Csv C:\ProcInv.csv -NoTypeInformation

	.INPUTS
		System.String

	.OUTPUTS
		Selected.System.Management.ManagementObject

	.NOTES
		#=======================================================
		Author: Kevin Kirkpatrick
		Created: 4/16/14

		Disclaimer: This script comes with no implied warranty or guarantee and is to be used at your own risk. It's recommended that you TEST
		execution of the script against Dev/Test before running against any Production system.

		#========================================================

		TAG:PUBLIC

	.LINK
		https://github.com/vScripter/PowerShell-Scripts

	.LINK
		about_WMi

	.LINK
		about_Wmi_Cmdlets
#>

#Requires -Version 3

[cmdletbinding()]
Param (
	[parameter(Mandatory = $true,
			   ValueFromPipeline = $true,
			   HelpMessage = "Enter the name of a computer or an array of computer names")]
	[system.string[]]$Computers
)

# Set the EA preference to 'Stop' so that Non-Terminating errors will be caught and displayed in the catch block
$ErrorActionPreference = "Stop"

# Cycle through each computer and attempt to query WMI
foreach ($C in $Computers)
{
	# Test the connection to the computer, if it pings, continue on with the query
	if (Test-Connection -ComputerName $C -Count 1 -Quiet)
	{
		try
		{

			#region FormattingHashTables
			#================================

			# Attempt to differentiate if the destination is a VM, or not. In VMware, vProcessors typically return a value of 0 for the L2 Processor Cache.
			# This was not testing with Hyper-V
			$Type = @{
				label = 'Type'
				expression = {
					if ($_.L2CacheSize -eq '0') { "Virtual" }
					else { "Physical" }
				}
			}# end $Type

			# Check to see if HyperThreading is enabled by comparing the number of logical processors with the number of cores
			$HyperThreading = @{
				label = 'HyperthreadingEnabled'
				expression = {
					if ($_.NumberOfLogicalProcessors -gt $_.NumberOfCores) { "Yes" }
					else { "No" }
				}
			}# end $HyperThreading

			# Use hash tables to modify the paramter output names
			$ComputerName = @{ label = 'Computer'; Expression = { $_.PSComputerName } }
			$CoreCount = @{ label = 'CoreCount'; Expression = { $_.NumberOfCores } }
			$LogicalCores = @{ label = 'LogicalProcessors'; expression = { $_.NumberOfLogicalProcessors } }
			$Description = @{ label = 'Description'; Expression = { $_.Name } }
			$Socket = @{ label = 'Socket'; expression = { $_.SocketDesignation } }
			#================================
			#endregion

			# Run the query
			Get-WmiObject -Query "SELECT * FROM win32_processor" -ComputerName $C |
			Select-Object $ComputerName, $Socket, $CoreCount, $LogicalCores, $HyperThreading, $Description, $Type

		}# end try

		catch
		{
			# Catch any errors and write a warning that includes the computer name as well as the error message, which is stored in $_
			Write-Warning "$C - $_"
		}# end catch

	}# end if

	else
	{
		# If the computer was not reachable on the network, display such detail
		Write-Warning "$C is unreachable"

	}# end else

}# end foreach
