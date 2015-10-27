
function Invoke-DiceRoll {
	
<#
	.SYNOPSIS
		Simulates a dice roll and returns a number based on the result of rolling the desired number of dice.
	.DESCRIPTION
		Simulates a dice roll and returns a number based on the result of rolling the desired number of dice.
	
		The default dice count is 5, which was driven by the Diceware Passphrase minimum word length recommendation. See the help for the 'New-DicewarePassword' cmdlet/function for more information.
	.PARAMETER  DiceCount
		The number of dice to roll
	.EXAMPLE
		Invoke-DiceRoll -DiceCount 8
		51334144		
	.EXAMPLE
		Invoke-DiceRoll
		31544
	.INPUTS
		System.Int32
	.OUTPUTS
		System.String
	.NOTES
		Author: Kevin Kirkpatrick
		Contact: https://github.com/vScripter 
		Version: 1.0
		Last Updated: 20151027
		Last Updated By: K. Kirkpatrick
		Last Update Notes:
		- Created
#>
	
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[ValidateRange(1, 8)]
		[System.Int32]$DiceCount = 5
	)
	
	BEGIN {
		
		#Requires -Version 3		
		
	} # end BEGIN block
	
	PROCESS {
		
		$i = 0
		
		Write-Verbose -Message "[Invoke-DiceRoll] Rolling dice; generating a {$DiceCount} digit random number."
		try {
			
			$numberResult = $null
			
			for (; $i -lt $DiceCount; $i++) {
				
				$number = $null
				$number = "$(Get-Random -Minimum 1 -Maximum 6)"
				$numberResult += $number
				
			} # end for loop
			
			$numberResult
			
		} catch {
			
			Write-Warning -Message "[Invoke-DiceRoll][ERROR]Error generating random number. $_ "
			
		} # end try/catch		
		
	} # end PROCESS block
	
	END {
		
		Write-Verbose -Message "[Invoke-DiceRoll] Processing Complete"
		
	} # end END block
	
} # end function Invoke-DiceRoll


function New-DicewarePassword {
	
<#
	.SYNOPSIS
		This function will generate/return a Diceware Password.
	.DESCRIPTION
		This function will generate/return a Diceware Password.
		
		Diceware involves, literally, rolling dice and matching the resulting numbers to a list containing 7,776 English words, each identified by a five-digit number.
	
		For more information on what the 'Diceware Passphrase' concept is, see the following link: http://world.std.com/~reinhold/diceware.html
	
		This function was inspired by the concepts and methods of creating Diceware Passphrases. That said, this function cannot guarantee 100% unique unique results for a few reasons:
			1. I had to substite out the double-quote charater (") associated with number/entry 66634 with double-colons (::); I had issues returning a single, double-quote charater, based on how PowerShell handles quoations
			2. Since a computer is handling the 'digital' dice rolls, one could argue that a bug in some system code, or at some other low level of computation, a computer (potentially) follows a discoverable algorithm...that's as far as I'll go, on that.	
	
		Overall, this should still be a good tool to generate more complex, and easy to remember, passwords than you may have previously used.
	
		There are several 'Security Levels' that you can choose from, which equates to the total number of words utilized. In the Diceware FAQ, it states that "Six words may be breakable by an organization with a very large budget, such as a large country's 
		security agency. Seven words and longer are unbreakable with any known technology, but may be within the range of large organizations by around 2030. Eight words should be completely secure through 2050."
	
		Some additional good resources/articles:
		http://arstechnica.com/business/2015/10/this-11-year-old-is-selling-cryptographically-secure-passwords-for-2-each/
		http://arstechnica.com/information-technology/2014/03/diceware-passwords-now-need-six-random-words-to-thwart-hackers/
	.PARAMETER  FetchType
		Specify if you want to import the file from the web or from a local file path
	.PARAMETER  URI
		URI of web-hosted file
	.PARAMETER  Path
		Full path to file location
	.PARAMETER  SecurityLevel
		Desired Security Level.
	
		Average = 5 words
		High = 6 words
		Extreme = 7 words
		UnHackable = 8 words
	.EXAMPLE
		New-DicewarePassword -Verbose
	
		This assumes a URI has been hard coded into the function and will attempt to pull the .CSV Diceware word list from a web-hosted file
	.EXAMPLE
		New-DicewarePassword -FetchType Web -URI 'https://server01/dicewarewordlist.csv'
	.EXAMPLE
		New-DicewarePassword -FetchType Local -Path C:\dicewarewordlist.csv		
	.INPUTS
		System.String
	.OUTPUTS
		System.Management.Automation.PSCustomObject
	.NOTES
		Author: Kevin Kirkpatrick
		Contact: https://github.com/vScripter 
		Version: 1.0
		Last Updated: 20151027
		Last Updated By: K. Kirkpatrick
		Last Update Notes:
		- Created
#>
	
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[ValidateSet('Local', 'Web')]
		[System.String]$FetchType = 'Web',
		
		[Parameter(Position = 1, ParameterSetName = 'Web')]
		[ValidateScript({ (Invoke-WebRequest -Uri $URI).StatusCode -eq 200 })]
		[System.String]$URI = 'https://db.tt/ctx3DNqN',
		
		[Parameter(Position = 2, ParameterSetName = 'Local')]
		[ValidateScript({ Test-Path -LiteralPath $Path -PathType Leaf })]
		[System.String]$Path,
		
		[Parameter(Position = 3)]
		[ValidateSet('Average', 'High', 'Extreme', 'UnHackable')]
		[System.String]$SecurityLevel = 'Average'
	)
	
	BEGIN {
		
		#Requires -Version 3
		
		if ($URI) {
			
			Write-Verbose -Message "[New-DicewarePassword] Calling REST 'Get' method from URI {$URI}. I will then import and store the Diceware Word List"
			try {
				
				$wordList = $null
				$wordList = Invoke-RestMethod -Uri $URI -Method Get -ErrorAction Stop | ConvertFrom-Csv -ErrorAction Stop
				
			} catch {
				
				Write-Warning -Message "[New-DicewarePassword][ERROR] Importing and storing Diceware Word List from URI {$URI}. $_ "
				
				
			} # end try/catch
			
		} elseif ($Path) {
			
			Write-Verbose -Message "[New-DicewarePassword] Importing and storing Diceware Word List from Path {$Path}"
			try {
				
				$wordList = $null
				$wordList = Import-Csv -LiteralPath $Path -ErrorAction Stop
				
			} catch {
				
				Write-Warning -Message "[New-DicewarePassword][ERROR] Importing and storing Diceware Word List from Path {$Path}. $_ "
				
				
			} # end try/catch
			
		} # end if/elseif
		
		
		Write-Verbose -Message "[New-DicewarePassword] Security level of {$SecurityLevel} has been selected. Translating dice roll count."
		try {
			
			[void][int]$diceRollCount
			$diceRollCount = switch ($SecurityLevel) {
				Average { 5 }
				High { 6 }
				Extreme { 7 }
				UnHackable { 8 }
			} # end switch
			
			Write-Verbose -Message "[New-DicewarePassword] Dice will be rolled {$diceRollCount} time/s"
			
		} catch {
			
			Write-Warning -Message "[New-DicewarePassword][ERROR] Unable to translate dice roll count. $_ "
			
			
		} # end try/catch		
		
		
	} # end BEGIN block
	
	PROCESS {
		
		Write-Verbose -Message "[New-DicewarePassword] Generating a {$diceRollCount} word Diceware Password based on Security Preference {$($SecurityLevel)}."
		try {
			
			$i = 0
			$result1 = $null
			$result2 = $null
			
			for (; $i -lt $diceRollCount; $i++) {
				
				$word = $null
				$diceRoll = $null
				
				$diceRoll = xInvoke-DiceRoll -ErrorAction Stop
				$word = ($wordList | Where-Object { $_.Number -eq $diceRoll }).Word
				
				$result1 += " $word"
				$result2 += $word
				
			} # end for loop
			
			$objPassWord = @()
			$objPassWord = [PSCustomObject] @{
				PassWord = $result2.Trim()
				SpacedPassWord = $result1.Trim()
			}
			$objPassWord
			
		} catch {
			
			Write-Warning -Message "[New-DicewarePassword][ERROR] Could not generate Diceware Password. $_ "
			
			
		} # end try/catch
		
	} # end PROCESS block
	
	END {
		
		Write-Verbose -Message "[New-DicewarePassword] Processing Complete"
		
	} # end END block
	
} # end function New-DicewarePassword


Export-ModuleMember -Function *