$scriptName = $PSCommandPath
write-host Hello, this is $scriptName
write-host "`nLet's create user and group!`n"


$str = $null
While ($true)
{	
	write-host "Please, enter 4 symbols: "
	$str = Read-Host
	$str = $str -replace '[^a-zA-Z0-9]', ''
	write-host "You entered: $str"

	$len = $str.ToCharArray().Count
	write-host "lengt of this string: $len"

	if ($len -eq 4) 
	{
		write-host "Count of symbols is four, it's correct.`n"
		break;
	}
}

while ($true) {
	$FirstPassword = Read-Host "Enter user password" -AsSecureString
	$SecondPassword = Read-Host "Confirm password" -AsSecureString

	$fstPwText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($FirstPassword))
	$sndPwText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecondPassword))

	if ($fstPwText.compareTo($sndPwText) -ne 0)
	{
		Write-Host "Fitst password and second password is not equal, please, try again.`n"
	}
	else 
	{
		Write-Host "Creating new local user...`n"
		Break;
	}
}

Remove-Variable fstPwText
Remove-Variable sndPwText
$groupName = "GPart3$str"
$userName = "UPart3$str"

New-LocalUser -AccountNeverExpires -Name $userName -Password $FirstPassword -Confirm

Write-Host "Creating new local group...`n"
New-LocalGroup $groupName -Confirm

Write-Host "Adding new user to the new group...`n"
Add-LocalGroupMember -Group $groupName -Member $userName -Confirm
Enable-LocalUser -Name $userName 

Write-Host "Success!"
Start-Process C:\Console\L1C1.msc

