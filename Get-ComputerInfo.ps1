<#
    .SYNOPSIS
        Lists basic Computer/Server information from WMI queries.

    .DESCRIPTION
        Lists basic Computer/Server information from WMI queries.

        This script accepts a single computer as input, or multiple computers. If no value is given, 'localhost' us used as the default value.

    .PARAMETER  Computer
        Name of computer or server. Preferably, use Fully Qualified Domain Names

    .EXAMPLE
        .\Get-ComputerInfo.ps1

    .EXAMPLE
        .\Get-ComputerInfo.ps1 -Computer compa.something.com

    .Example
        .\Get-ComputerInfo.ps1 -Computer compa.company.com,compb.company.com

    .Example
        .\Get-ComputerInfo.ps1 -Computer (Get-Content C:\ListOfComputers.txt)

    .NOTES
        20141010	K. Kirkpatrick		[+] Updated the way the custom object is created - [PSCustomObject]
        20141013    K. Kirkpatrick      [+] Added uptime property; cleaned up some commented out code

        TAG:PUBLIC
    .LINK
        about_WMI

    .LINK
        about_Wmi_Cmdlets

#>


[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [System.string[]] $Computer = 'localhost'
)

BEGIN
{
	Set-StrictMode -Version Latest

	$Results = $null
}# BEGIN

PROCESS
{

	foreach ($C in $Computer)
	{
		#region clear variables

			# Make sure variable names are cleared upon each iteration
		$ServerCollection = @()
		$wmiWin32CompSys = $null
		$wmiWin32OpSys = $null
		$wmiWin32BIOS = $null
		$wmiWin32SysEncl = $null
		$ComputerShortName = $null
		$ComputerIPv4 = $null
		#endregion

		if (Test-Connection $C -Count 2 -Quiet)
		{
			try
			{
				Write-Verbose -Message "Working on $C..."

				$wmiWin32CompSys = Get-WmiObject -Query "SELECT Caption,Domain,Model FROM win32_computersystem" -ComputerName $C
				$wmiWin32OpSys = Get-WmiObject -Query "SELECT LastBootupTime,Description,Caption FROM Win32_operatingsystem" -ComputerName $C
				$wmiWin32BIOS = Get-WmiObject -Query "SELECT Manufacturer,SerialNumber FROM win32_BIOS" -ComputerName $C
				$wmiWin32SysEncl = Get-WmiObject -Query "SELECT SMBIOSAssetTag FROM win32_SystemEnclosure" -ComputerName $C
				$ComputerShortName = $wmiWin32CompSys.Caption
				$ComputerIPv4 = Get-WmiObject -Query "SELECT * FROM Win32_NetworkAdapterConfiguration" -ComputerName $C | Where-Object { $_.IPEnabled -eq $true }
                $UptimeData = (get-date) - $wmiWin32OpSys.converttodatetime($wmiWin32OpSys.lastbootuptime)

				$ObjServer = [PSCustomObject] @{
					ComputerName = $ComputerShortName.ToUpper()
					Domain = $wmiWin32CompSys.Domain
					IPAddress = $ComputerIPv4.IPAddress[0]
					SubnetMask = $ComputerIPv4.ipsubnet[0]
					DefaultGateway = $ComputerIPv4.DefaultIPGateway[0]
					PrimaryDNS = $ComputerIPv4.DNSServerSearchOrder[0]
					SecondaryDNS = $ComputerIPv4.DNSServerSearchOrder[1]
					Uptime = $UptimeData.Days
                    Model = $wmiWin32CompSys.Model
					Description = $wmiWin32OpSys.Description
					OperatingSystem = $wmiWin32OpSys.Caption
					Manufacturer = $wmiWin32BIOS.Manufacturer
					SerialNumber = $wmiWin32BIOS.SerialNumber
					AssetTag = $wmiWin32SysEncl.SMBIOSAssetTag
				}# end $ObjServer

				$ServerCollection += $ObjServer
				$Results += $ServerCollection

			} catch
			{
				Write-Warning -Message "$C - $_"
			}# end try/catch
		}# end if

		else
		{
			Write-Warning -Message "$C is unreachable"
		}# end else
	}# end foreach
}# PROCESS

END
{
    $UptimeFormat = @{ label = "Uptime(Days)"; expression = { $PSItem.Uptime } }

	# Call the results
	$Results |
    Select-Object ComputerName,Domain,IPAddress,SubnetMask,DefaultGateway,PrimaryDNS,SecondaryDNS,$UptimeFormat,Model,Description,OperatingSystem,Manufacturer,SerialNumber,AssetTag
}# END