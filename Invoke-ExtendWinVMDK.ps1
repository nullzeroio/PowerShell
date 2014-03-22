#========================================================================
# Created with: SAPIEN Technologies, Inc., PowerShell Studio 2012 v3.1.31
# Created on:   3/21/2014 2:53 PM
# Created by:   Kevin Kirkpatrick
# Organization: 
# Filename:     
#========================================================================

<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER <>

.INPUTS

.EXAMPLE

.EXAMPLE

#>

[cmdletbinding()]
param()

function WindowsPartitions {
[cmdletbinding()]
param
([parameter(mandatory=$true)][string]$Server
)

#Define Hash Table Variables
$ErrorActionPreference = "SilentlyContinue"
$SizeInGB=@{Name="Size(GB)"; Expression={"{0:N2}" -f ($_.Size/1GB)}}
$FreespaceInGB=@{Name="Freespace(GB)"; Expression={"{0:N2}" -f ($_.Freespace/1GB)}}
$PercentFree=@{name="PercentFree(%)";Expression={[int](($_.FreeSpace/$_.Size)*100)}}


# Query WMI; Select objects to report on, display output in auto-formatted table
Get-WmiObject -query "SELECT SystemName,Caption,VolumeName,Size,Freespace FROM win32_logicaldisk WHERE DriveType=3" -computer $Server |
Select-Object SystemName,Caption,VolumeName,$SizeInGB,$FreespaceInGB,$PercentFree |
sort-object "PercentFree(%)","SystemName" | Format-Table -AutoSize		
}



if($global:DefaultVIServer -eq $null)
{
	Write-Warning "You are not currently connected to a vCenter Server. Connect before proceeding."
	}# end if

else
{
	#$VIServerName = ($global:DefaultVIServer).Name
	Write-Warning "Currently Connected to $(($global:DefaultVIServer).Name)"

	$VMName = Read-Host -Prompt "Enter the name of the VM"
	$GuestDNSName = (get-vm $VMName).guest.get_hostname()
	Get-HardDisk -VM $VMName | Select-Object Name,CapacityGB,Filename | Format-Table -AutoSize
	
	$HardDiskNumber = Read-Host -Prompt "Enter the number of the Hard Disk you wish to extend (ex: 1)"
	$CheckPartition = Read-Host -Prompt "Would you like to check and display the current partition configuration? (Y/N)
	(Windows ONLY - requires admin access) "
	if($CheckPartition -eq 'Y'){WindowsPartitions -Server $GuestDNSName}else{}
	$NewSizeGB = Read-Host -Prompt "Enter the new total size in GB (must be larger than current size)"
	$GuestVolumeLetter = Read-Host -Prompt "Enter the guest volume letter that will be expanded (ex: C)"	

	Get-HardDisk -VM $VMName | Where-Object Name -eq "Hard Disk $HardDiskNumber" | Set-HardDisk -CapacityGB $NewSizeGB
	
	$GuestOSName = (Get-VM $VMName).guest.OSFullName
	
	
	if ($GuestOSName -like '*Server 2008*')
	{
		Write-Warning "Looks like the guest is running an OS that supports remote expansion."
		$Continue = Read-Host -Prompt "Ready to extend guest partition. Continue? (Y/N)"
		
		if($Continue -eq 'Y')	
		{
			$script = "echo select vol $GuestVolumeLetter > c:\diskpart.txt && echo rescan >> c:\diskpart.txt && echo extend >> c:\diskpart.txt && diskpart.exe /s c:\diskpart.txt"
			$scriptstring = $script
		
			Write-Warning "Enter guest OS credentials..."
			Start-Sleep -Seconds 2
			
			$cred = Get-Credential
			Invoke-VMScript -VM $VMName -ScriptText $scriptstring -GuestCredential $cred -ScriptType bat
			
			}# end if
	
		else
		{
			Write-Warning "The guest OS is either not Windows or has not been tested to support remote expansion using diskpart.exe"	
			}# end else
		
		}# end if
	
	else
		{
		Write-Warning "Guest OS expansion cancelled. At this point, the vmdk was extended but the guest will not see the new space until "
			}# end else
	
Write-Warning "Script Complete. Verify VM expansion was completed successfully"
	}# end else