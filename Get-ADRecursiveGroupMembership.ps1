<#
.SYNOPSIS
	Return recursive group membership details for a given Active Directory group
.DESCRIPTION
	Return recursive group membership details for a given Active Directory group. Group names should be specified in the form
	of "Domain\Group Name"; ie 'CORP\Domain Admins'.

	The script will take a single or multiple groups.

	There is an optional switch parameter that can be used to include a summary report of total unique members & count.

    This script/function relies on the native AD Module as well as the Quest.ActiveRoles.ADManagement PSSnapin, which is freely available from Quest.
.PARAMETER GroupName
	Name of AD group you wish to gather membership details for
.PARAMETER IncludeUNiqueMembersReport
	Switch parameter that can be used to append a unique members report
.INPUTS
	System.String
.EXAMPLE
	./Get-ADRecursiveGroupMembership.ps1 -GroupName 'CORP\Domain Admins'
.EXAMPLE
	./Get-ADRecursiveGroupMembership.ps1 -GroupName 'CORP\Domain Admins' -IncludeUniqueMembersReport
.EXAMPLE
	./Get-ADRecursiveGroupMembership.ps1 -GroupName 'CORP\Domain Admins' -IncludeUniqueMembersReport -Verbose
	C:\PS> ./Get-ADRecursiveGroupMembership.ps1 -GroupName 'CORP\Domain Admins' -Verbose
	C:\PS> ./Get-ADRecursiveGroupMembership.ps1 -GroupName 'CORPA\Domain Admins','CORPB\Domain Admins'
	C:\PS> ./Get-ADRecursiveGroupMembership.ps1 -GroupName (Get-Content C:\ADGroupMembershipList.txt) -IncludeUniqueMembersReport
.LINK

.NOTES
	20141104 	K. Kirkpatrick		Created
	20141114	K. Kirkpatrick		Updated CBH

	TO-DO
	[ ] Consolidate down to only using the Quest AD PSSnapin, or convert everything to native MSFT AD PowerShell Module

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

#Requires -Module ActiveDirectory

[cmdletbinding()]
param (
	[parameter(Mandatory = $true,
			   Position = 0)]
	[string[]]$GroupName,

	[parameter(Mandatory = $false,
			   Position = 1)]
	[switch]$IncludeUniqueMembersReport
)# param

BEGIN
{

	#$Global:colUniqueUsers = @()

	$Script:Indent = $null

	try # add the Quest PSSnapin
	{
		Write-Verbose -Message "Adding Quest PSSnapin..."

		Add-PSSnapin Quest.ActiveRoles.ADManagement -ErrorAction 'Stop' | Out-Null
	} catch
	{
		Write-Warning -Message "Error adding Quest.ActiveRoles.ADManagement PSSnapin - $_"
	}# try/catch

	function Indent
	{
		param (
			[Int]$Level
		)

		$Script:Indent = $null

		For ($x = 1; $x -le $Level; $x++)
		{
			$Script:Indent += "   "
		}# for
	}# function Indent

	function Get-MySubGroupMembersRecursive
	{
		[cmdletbinding()]
		param (
			$DNs
		)

		ForEach ($DN in $DNs)
		{
			$Object = Get-QADObject $DN

			If ($Object.Type -eq "Group")
			{

				$i++
				Indent $i

				if ($object.members.count -eq 0)
				{
					Write-Output "  $Object (Group)(EMPTY)"
				} else
				{
					Write-Output "  $Object (Group)"
				}# if/else

				$Group = Get-QADGroup $DN

				If ($Group.Members.Length -ge 1)
				{
					Get-MySubGroupMembersRecursive $Group.Members
				}# if

				$i--
				Indent $i

				Clear-Variable Group -ErrorAction SilentlyContinue
			} Else
			{
				$userfound = Get-QADUser $DN | Select-Object NTAccountName, Name

				Write-Output "$indent  $($userfound.NTAccountName) ($($userfound.Name))"

				Clear-Variable userfound -ErrorAction SilentlyContinue
			}# if/else
		}# ForEach
	}# function Get-MySubGroupMembersRecursive

}# BEGIN

PROCESS
{

	ForEach ($ParentGroupName in $GroupName)
	{
		Write-Verbose -Message "Gathering membership details from '$(($ParentGroupName).toupper())'"

		$ParentGroup = $null
		$parentGroupNTAccount = $null
		$FirstMembers = $null
		$member = $null

		$ParentGroup = Get-QADGroup $ParentGroupName
		$parentGroupNTAccount = $ParentGroup.NTAccountName

		Write-Output " "
		Write-Output "$parentGroupNTAccount (Root)"

		If ($ParentGroup -eq $null)
		{
			Write-Warning -Message "Group $ParentGroupName not found."
			break
		} Else
		{
			$FirstMembers = $ParentGroup.Members

			ForEach ($member in $firstmembers)
			{
				Get-MySubGroupMembersRecursive $member
			}# ForEach
		}# if/else

		if ($IncludeUniqueMembersReport)
		{
			Write-Verbose -Message "Gathering unique users..."

			Write-Output " "
			Write-Output "  ----------------------------- "
			Write-Output "       All Unique Members "
			Write-Output "  ----------------------------- "

				# 20141104-KMK - Using the native AD PowerShell module here; I ran into issues adding group
				# members to a globally accessible array. It processes the unique membership fast enough, for now,
				# for it to still be useful
			$domain = ($ParentGroupName).substring(0, 3).toupper()
			$samAccountName = @{ label = 'Account'; expression={ "$domain\$($_.samaccountname)" } }
			$uniqueUsers = Get-ADGroupMember -Server $domain -Identity $ParentGroup.Name -Recursive | Select-Object $SamAccountName,Name

			Write-Output "       Total Users: $(($UniqueUsers).count)  "
			Write-Output "  ----------------------------- "

			foreach ($user in $uniqueUsers)
			{
				Write-Output "  $($user.Account)	 ($($user.Name))"
			}

			Write-Verbose -Message "Done!"
		} else
		{
			Write-Verbose -Message "Done!"
		}# if/else
	}# foreach

}#PROCESS

END
{

}# END