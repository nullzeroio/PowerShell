#requires -Version 3

function Send-SlackMessage {
    <#  
            .SYNOPSIS
            Sends a chat message to a Slack organization
            .DESCRIPTION
            The Post-ToSlack cmdlet is used to send a chat message to a Slack channel, group, or person.
            Slack requires a token to authenticate to an org. Either place a file named token.txt in the same directory as this cmdlet,
            or provide the token using the -token parameter. For more details on Slack tokens, use Get-Help with the -Full arg.
            .NOTES
            Written by Chris Wahl for community usage
            Twitter: @ChrisWahl
            GitHub: chriswahl
            .EXAMPLE
            Post-ToSlack -channel '#general' -message 'Hello everyone!' -botname 'The Borg'
            This will send a message to the #General channel, and the bot's name will be The Borg.
            .EXAMPLE
            Post-ToSlack -channel '#general' -message 'Hello everyone!' -token '1234567890'
            This will send a message to the #General channel using a specific token 1234567890, and the bot's name will be default (PowerShell Bot).
            .LINK
            Validate or update your Slack tokens:
            https://api.slack.com/tokens
            Create a Slack token:
            https://api.slack.com/web
            More information on Bot Users:
            https://api.slack.com/bot-users
    #>
	
	Param (
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Slack channel')]
		[ValidateNotNullorEmpty()]
		[String]$Channel,
		
		[Parameter(Mandatory = $true, Position = 1, HelpMessage = 'Chat message')]
		[ValidateNotNullorEmpty()]
		[String]$Message,
		
		[Parameter(Mandatory = $false, Position = 2, HelpMessage = 'Slack API token')]
		[ValidateNotNullorEmpty()]
		[String]$token,
		
		[Parameter(Mandatory = $false, Position = 3, HelpMessage = 'Optional name for the bot')]
		[String]$BotName = 'PowerShell Bot'
	)
	
	Process {
		
		# Static parameters
		if (!$token) {
			$token = Get-Content -Path "$PSScriptRoot\token.txt"
		}
		$uri = 'https://slack.com/api/chat.postMessage'
		
		# Build the body as per https://api.slack.com/methods/chat.postMessage
		$body = @{
			token = $token
			channel = $Channel
			text = $Message
			username = $BotName
			parse = 'full'
		}
		
		# Call the API
		try {
			Invoke-RestMethod -Uri $uri -Body $body
		} catch {
			throw 'Unable to call the API'
		}
		
	} # End of process
} # End of function

function Get-SlackUsers {
    <#  
           
    #>
	
	Param (
		[Parameter(Mandatory = $false, Position = 2, HelpMessage = 'Slack API token')]
		[ValidateNotNullorEmpty()]
		[String]$token
	)
	
	Process {
		
		# Static parameters
		if (!$token) {
			$token = Get-Content -Path "$PSScriptRoot\token.txt"
		}
		
		$uri = 'https://slack.com/api/users.list'
		
		$body = @{
			token = $token
			channel = $Channel
			parse = 'full'
		} # end $body
		
		# Call the API
		try {
			
			$slackUserQuery = $null
			$objSlackUsers = @()
			
			$slackUserQuery = (Invoke-RestMethod -Uri $uri -Body $body).Members
			
			foreach ($sUser in $slackUserQuery) {
				
				$objSlackUser = @()
				$objSlackUser = [PSCustomObject] @{
					FirstName = $sUser.profile.first_name
					LastName = $sUser.profile.last_name
					RealName = $sUser.real_Name
					Email = $sUser.profile.email
					ID = $sUser.id
					Status = $sUser.status
					TimeZone = $sUser.tz_label
					Deleted = $sUser.deleted
					IsBot = $sUser.is_bot
					IsAdmin = $sUser.is_admin
					IsOwner = $sUser.is_owner
					IsPrimaryOwner = $sUser.is_primary_owner
					IsRestricted = $sUser.is_restricted
					IsUltraRestricted = $sUser.is_ultra_restricted
					HasFiles = $sUser.has_files
					Has2Fa = $sUser.has_2fa
				}
				$objSlackUser
				
			} # end foreach $sUser
			
		} catch {
			
			throw 'Unable to call the API'
			
		}
		
	} # End of process
	
} # End of function

function Get-SlackUserInfo {
    <#  
           
    #>
	
	Param (
		[Parameter(Mandatory = $false, Position = 0, HelpMessage = 'Slack API token')]
		[ValidateNotNullorEmpty()]
		[String]$Token,
		
		[Parameter(Mandatory = $false, Position = 1, HelpMessage = 'Slack User ID')]
		[ValidateNotNullorEmpty()]
		[String]$UserID
	)
	
	Process {
		
		# Static parameters
		if (!$token) {
			$token = Get-Content -Path "$PSScriptRoot\token.txt"
		}
		
		$uri = 'https://slack.com/api/users.info'
		
		$body = @{
			token = $Token
			user = $UserID
			parse = 'full'
		} # end $body
		
		# Call the API
		try {
			
			$slackUserQuery = $null			
			$slackUserQuery = (Invoke-RestMethod -Uri $uri -Body $body -ErrorAction Stop).User
			
			foreach ($sUser in $slackUserQuery) {
				
				$objSlackUser = @()
				$objSlackUser = [PSCustomObject] @{
					SlackName = $sUser.name
					FirstName = $sUser.profile.first_name
					LastName = $sUser.profile.last_name
					RealName = $sUser.real_Name
					Email = $sUser.profile.email
					ID = $sUser.id
					Status = $sUser.status
					TimeZone = $sUser.tz_label
					Deleted = $sUser.deleted
					IsBot = $sUser.is_bot
					IsAdmin = $sUser.is_admin
					IsOwner = $sUser.is_owner
					IsPrimaryOwner = $sUser.is_primary_owner
					IsRestricted = $sUser.is_restricted
					IsUltraRestricted = $sUser.is_ultra_restricted
					HasFiles = $sUser.has_files
					Has2Fa = $sUser.has_2fa
				}
				$objSlackUser
				
			} # end foreach $sUser
			
		} catch {
			
			throw 'Unable to call the API'
			
		}
		
	} # End of process
	
} # End of function

function Get-SlackHistory {
    <#  
           
    #>
	
	Param (
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Slack channel')]
		[ValidateNotNullorEmpty()]
		[String]$Channel,
		
		[Parameter(Mandatory = $false, Position = 1, HelpMessage = 'Number of responses to return (default is 100)')]
		[int32]$Count,
		
		[Parameter(Mandatory = $false, Position = 2, HelpMessage = 'Slack API token')]
		[ValidateNotNullorEmpty()]
		[String]$Token,
		
		[Parameter(Mandatory = $false, Position = 3, HelpMessage = 'Optional name for the bot')]
		[String]$BotName = 'PowerShell Bot'
	)
	
	Process {
		
		# Static parameters
		if (!$token) {
			$token = Get-Content -Path "$PSScriptRoot\token.txt"
		}
		$uri = 'https://slack.com/api/channels.history'
		
		if ($Count) {
			
			$body = @{
				token = $token
				channel = $Channel
				count = $count
				username = $BotName
				parse = 'full'
			} # end $body
			
		} else {
			
			$body = @{
				token = $token
				parse = 'full'
			} # end $body
			
		} # end if/else
		
		# Call the API
		try {
			Invoke-RestMethod -Uri $uri -Body $body
		} catch {
			throw 'Unable to call the API'
		}
		
	} # End of process
} # End of function

function Get-SlackChannels {
    <#  
           
    #>
	
	Param (
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Slack API token')]
		[ValidateNotNullorEmpty()]
		[String]$Token
	)
	
	Process {
		
		$uri = 'https://slack.com/api/channels.list'
		
		$body = @{
			token = $token
			parse = 'full'
		} # end $body
		
		
		# Call the API
		try {
			
			$slackChannelQuery = $null
			$slackChannelQuery = Invoke-RestMethod -Uri $uri -Body $body -ErrorAction Stop
			
			foreach ($sChannel in $slackChannelQuery) {
				
				$objSlackChannel = @()
				$objSlackChannel = [PSCustomObject] @{
					ID = $sChannel.id
					Name = $sChannel.name
					Creator = (Get-SlackUserInfo -Token $Token -UserID $_.Created).SlackName
					IsArchived = $sChannel.is_archived
					IsGeneral = $sChannel.is_general
					IsMember = $sChannel.is_member
					Members = ($sChannel.members | ForEach-Object { Get-SlackUserInfo -Token $sToken -UserID $_ }) -join ', '
					Topic = $sChannel.topic.Value
					Purpose = $sChannel.purpose.value
				}
				$objSlackChannel
				
			} # end foreach
			
		} catch {
			
			throw 'Unable to call the API'
			
		}
		
	} # End of process
	
} # End of function