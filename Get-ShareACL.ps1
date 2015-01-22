<#
	.SYNOPSIS
		Returns NTFS and Share permissions for a provided UNC Path

	.DESCRIPTION
		Returns NTFS and Share permissions for a provided UNC Path

		This script/function can be used to report on Share and NTFS permissions for the provided UNC path, multiple UNC paths, or a list of UNC paths.

		It requires the proper access to enumerate the shares and read all of the ACL information (typically administrative permissions are required on the remote system hosting the path)

		It uses WMI to gather share information, so SMB shares hosted on NON-windows systems will return an error.

	.PARAMETER  UNCPath
		Valid UNC Path

	.EXAMPLE
		PS C:> .\Get-ShareACL.ps1 -UNCPath \\servera.loc1.company.com\testshare | Format-Table -AutoSize
	.EXAMPLE
		PS C:> .\Get-ShareACL.ps1 -UNCPath \\servera.loc1.company.com\testshare,\\serverb.loc1.company.com\share1$ | Out-Gridview
	.EXAMPLE
		PS C:> .\Get-ShareACL.ps1 -UNCPath (Get-Content C:\UNCPathList.txt) | Export-Csv C:\ACLAudit.csv -NoTypeInformation -Force
	.INPUTS
		System.String
	.NOTES
		20141017	K. Kirkpatrick		[+] Created

	TAG:PUBLIC
	
	GitHub:	 https://github.com/vScripter
	Twitter:  @vScripter
	Email:	 kevin@vMotioned.com

[-------------------------------------DISCLAIMER-------------------------------------]
 All script are provided as-is with no implicit
 warranty or support. It's always considered a best practice
 to test scripts in a DEV/TEST environment, before running them
 in production. In other words, I will not be held accountable
 if one of my scripts is responsible for an RGE (Resume Generating Event).
 If you have questions or issues, please reach out/report them on
 my GitHub page. Thanks for your support!
[-------------------------------------DISCLAIMER-------------------------------------]

		#TAG:PUBLIC
#>

[cmdletbinding()]
param (
	[parameter(Mandatory = $true, Position = 0)]
	[validatescript({ Test-Path $_ -PathType Container })]
	[string[]]$UNCPath
)

BEGIN
{
	$Results = @()

	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

	function Get-SMBACL
	{
		foreach ($Path in $UNCPath)
		{
			try
			{
				$colNTFS = @()
				$colSMB = @()

				$pathparts = $path.split("\")
				$ComputerName = $pathparts[2]
				$ShareName = $pathparts[3]
				
				Write-Verbose -Message "Gathering NTFS Permissions..."
				
				$acl = Get-Acl $path

				foreach ($accessRule in $acl.Access)
				{
					$objNTFSAcl = [PSCustomObject] @{
						ComputerName = $ComputerName
						ACLType = "NTFS"
						ShareName = $ShareName
						Account = $accessRule.IdentityReference
						Permission = $accessRule.FileSystemRights
					}

					$objNTFSAcl

				}# foreach
				
				Write-Verbose -Message "Gathering SMB/Share Permissions..."
				
				$Share = Get-WmiObject win32_LogicalShareSecuritySetting -Filter "name='$ShareName'" -ComputerName $ComputerName

				if ($Share)
				{
					$ACLS = $Share.GetSecurityDescriptor().Descriptor.DACL
					foreach ($ACL in $ACLS)
					{
						$User = $ACL.Trustee.Name
						if (!($user)) { $user = $ACL.Trustee.SID }
						$Domain = $ACL.Trustee.Domain
						switch ($ACL.AccessMask)
						{
							2032127 { $Perm = "Full Control" }
							1245631 { $Perm = "Change" }
							1179817 { $Perm = "Read" }
						}# switch

						$ntUser = "$Domain\$user"

						$objSMB = [PSCustomObject] @{
							ComputerName = $ComputerName
							ACLType = "SMB"
							Account = $ntUser
							Permission = $Perm
						}

						$objSMB

					}# foreach
				}# if
			} catch
			{
				Write-Warning -Message "Error getting info from $Path"

			}# try/catch
		}# foreach
		
		Write-Verbose -Message "Gathering Results..."
	}# function Get-SMBACL

}# BEGIN


PROCESS
{
	
	Get-SMBACL

}# PROCESS

END
{
	# Clean up work goes here

}# END
