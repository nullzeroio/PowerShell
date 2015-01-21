<#
.SYNOPSIS
    Get Windows Disk Space Details
.DESCRIPTION
    This sript pulls disk space details using CIM, as opposed to WMI.

    It will first check to see if WSMAN is supported on the remote system. If it is, the computer name is added to an array that contains all
    verified systems. If it is not supported, a warning will be displayed and that computer will be omitted from the query.

    In order to add legacy support, there is a -UseDCOM switch parameter which changes the protocol from WINRM (default) to DCOM

    Once the function compltes execution, the open CIM sessions are cleaned up/collapsed
.EXAMPLE
    .\Get-WindowsDiskSpace -ComputerName server1,server2 | Format-Table -AutoSize

SystemName  Caption VolumeName Size(GB) Freespace(GB) PercentFree(%)
----------  ------- ---------- -------- ------------- --------------
server1 C:                 50.00    25.49                     51
server1 D:      Data       20.00    19.88                     99
server2 C:                 50.00    27.32                     55
server2 E:      Data       50.00    42.39                     85

====================
Output from servers that all support WSMAN
.EXAMPLE
    .\Get-WindowsDiskSpace -ComputerName server1,badserver1 | Format-Table -AutoSize
WARNING: badserver1 - WSMAN Connection Failure

SystemName  Caption VolumeName Size(GB) Freespace(GB) PercentFree(%)
----------  ------- ---------- -------- ------------- --------------
server1 C:                 50.00    25.49                     51
server1 D:      Data       20.00    19.88                     99

====================
Output warning when a server that does not support WSMAN is supplied
.PARAMETER ComputerName
    Computer or list of computers
.PARAMETER UseDCOM
    Connect via DCOM instead of WINRM
.NOTES
    20140915    K. Kirkpatrick      [+] Created
	20141118	K. Kirkpatrick		[+] Moved to 'Dev'; still need to improve behavior to fall back to WMI for legacy server OSes

    TODO: Dynamic fall-back to WMI

	TAG:PUBLIC

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

[cmdletbinding(PositionalBinding = $true,
			   DefaultParameterSetName = "Default")]
param (
	[parameter(mandatory = $true,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true,
			   Position = 0)]
	[alias("comp")]
	[string[]]$ComputerName,

	[parameter(mandatory = $false,
			   Position = 1)]
	[Switch]$UseDCOM
)

BEGIN
{
	#Import-Module CimCmdlets

	$ErrorActionPreference = "Stop"

	try
	{
		foreach ($C in $ComputerName)
		{
			$TestConn = Test-WSMan -ComputerName $C -ErrorAction SilentlyContinue

			if ($TestConn -eq $null)
			{
				Write-Warning -Message "$C - WSMAN Connection Failure"
			} else
			{
				[string[]]$WSMANCompArray += $C
			}
		}# end foreach

		if ($UseDCOM)
		{
			Write-Verbose -Message "Opening CIM Sessions via DCOM protocol"
			$CimSession = New-CimSession -Name 'DiskQuery' -ComputerName $WSMANCompArray -SessionOption (New-CimSessionOption -Protocol DCOM)
		} else
		{
			Write-Verbose -Message "Opening CIM Sessions via WINRM protocol"
			$CimSession = New-CimSession -Name 'DiskQuery' -ComputerName $WSMANCompArray
		}
	} catch
	{
		Write-Warning -Message "Create Session Error: $_"
	}
}# end BEGIN

PROCESS
{
	try
	{
		foreach ($C in $CimSession)
		{
			Write-Verbose -Message "Working on $($C.ComputerName) via $($C.Protocol) protocol..."

			$SizeInGB = @{ Name = "Size(GB)"; Expression = { "{0:N2}" -f ($_.Size/1GB) } }
			$FreespaceInGB = @{ Name = "Freespace(GB)"; Expression = { "{0:N2}" -f ($_.Freespace/1GB) } }
			$PercentFree = @{ name = "PercentFree(%)"; Expression = { [int](($_.FreeSpace/$_.Size) * 100) } }

			Get-CimInstance -ComputerName "$($C.ComputerName)" 'win32_logicaldisk' -Namespace 'root\cimv2' -Property SystemName, Caption, VolumeName, Size, Freespace, DriveType |
			Where-Object { $_.drivetype -eq '3' } |
			Select-Object SystemName, Caption, VolumeName, $SizeInGB, $FreespaceInGB, $PercentFree

		}# end foreach
	} catch
	{
		Write-Warning -Message "$_"
	}# end try/catch
}# end PROCESS

END
{
	Remove-CimSession -Name 'DiskQuery'
}# end END
