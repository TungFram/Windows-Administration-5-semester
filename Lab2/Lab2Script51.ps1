param (
    [string]$Path2CsvFile,
    [string]$Delimiter
)

function PrintOperationBegin {
    param (
        [string]$string
    )
    Write-Host $string -BackgroundColor DarkYellow -ForegroundColor Black
}

function PrintOperationSuccess {
    param (
        [string]$string
    )
    Write-Host $string -BackgroundColor DarkGreen -ForegroundColor Black
}

function PrintInfo {
    param (
        [string]$string
    )
    Write-Host $string -BackgroundColor Cyan -ForegroundColor White
}

function PrintCheck {
    param (
        [string]$string
    )
    Write-Host $string -BackgroundColor DarkMagenta -ForegroundColor Black
}

function PrintAlert {
    param (
        [string]$string
    )
    Write-Host $string -BackgroundColor Red -ForegroundColor Black
}

function PrintNewLine {
    Write-Host ""
}




$CreatedOuCounter = 0
$CreatedGroupsCounter = 0
$CreatedUserCounter = 0
$Log = ""

if (!(Test-Path $Path2CsvFile -PathType Leaf)) {
    PrintAlert "Can't open the file: file is not exist!"
    break
}

Import-Module ActiveDirectory

$Users = Import-CSV -Path $Path2CsvFile -Delimiter $Delimiter -Encoding UTF8

$FQDN = [System.Net.Dns]::GetHostEntry((hostname)).HostName
# [System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).HostName

$ComputerName, $Domain, $CommonDomainComponent = $FQDN -split '.', 0, "simplematch"
$DomainName = $Domain + "." + $CommonDomainComponent

# Write-Host $DomainName # ad-training.loc
# Write-Host fqdn = $FQDN # DESKTOP-AD-SRV.ad-training.loc


foreach ($User in $Users) {
    $First_name = $User.First_name
    $Last_name = $User.Last_name
    $Patronymic = $User.Patronymic
    $Post = $User.Post
    $Department = $User.Department
    $Email = $User.Email
    $Phone = $User.Phone
    $Login = $User.Login
    $SoursePassword = [string]$User.Password
    $Ou_name = $User.Ou_name
    $Group_names = $User.Group_names
    $Path_to_home_folder = $User.Path_to_home_folder
    $Path_to_profile = $User.Path_to_profile

    $DisplayName = $First_name + " " + $Last_name
    $Username = $Last_name + $First_name[0] + $Patronymic[0]
    $UserPrincipalName = $Login + "@" + $DomainName
    $Password = ConvertTo-SecureString $SoursePassword -AsPlainText -Force

    $DistinguishedPath2Ou = "$($(Get-ADDomain).DistinguishedName)"
    $DistinguishedPath2OuSubs = "OU=$($Ou_name),$($DistinguishedPath2Ou)"
    $DistinguishedPath2OuUser = "CN=$($Username),$($DistinguishedPath2OuSubs)"

    $UserObj = $Null
    try {
        $UserObj = Get-ADUser -Identity $DistinguishedPath2OuUser
    }
    catch {
        PrintNewLine
        PrintCheck "User ($($DisplayName)) does not exist. This user will be created."
    }
 
    if (!($Null -eq $UserObj)) {
        PrintInfo "Sorry, but user $($Last_name) $($First_name) $($Patronymic) already exist."
        continue
    }

    # Write-Host typeof((Get-ADOrganizationalUnit -Identity "$($DistinguishedPath2Ou)"))
    # # (![adsi]::Exists("LDAP://OU=$($Ou_name),DC=$($Domain),DC=$($CommonDomainComponent)"))
    # if (!(Get-ADOrganizationalUnit -Identity "$($DistinguishedPath2Ou)")) {
    #     $newOu = New-ADOrganizationalUnit -Name $Ou_name -Path $DistinguishedPath2Ou -PassThru
    # }


    try {
        PrintNewLine
        PrintOperationBegin "Creating organization unit..."
        New-ADOrganizationalUnit -Name $Ou_name -Path $DistinguishedPath2Ou
        PrintOperationSuccess "Organization unit created."
        $CreatedOuCounter += 1
        $Log += "Organization unit: $($Ou_name) created.`n"
    }
    catch {
        PrintNewLine
        PrintInfo "Specified organization unit already exist, working..."
    }


    $Path2MainFolder = "C:\UsersHome\$($Username)"
    PrintNewLine
    PrintOperationBegin "Creating main folder..."
    New-Item -Path $Path2MainFolder -ItemType Directory -Force -ea Stop
    try {
        PrintOperationBegin "Sharing the main folder..."
        New-SmbShare -Name "$($Username)$" -Path $Path2MainFolder -ea Stop
        PrintOperationSuccess "Main folder was created and shared."
    }
    catch {
        PrintInfo "Main folder is alredy shared, working..."
    }


    $HomeFolderMask = "X:"
    $Path2HomeFolder = $Path_to_home_folder
    $DefaultPath2HomeFolder = "C:\UsersHome\$Username\HomeFolder"
    if (($Null -eq $Path2HomeFolder) -or ($Path2HomeFolder -eq "")) {
        $Path2HomeFolder = $DefaultPath2HomeFolder
    }
    elseif (!(Test-Path -Path $Path_to_home_folder)) {
        $Path2HomeFolder = $DefaultPath2HomeFolder
    } 
    elseif (!(Test-Path -IsValid -Path $Path_to_home_folder)) {
        $Path2HomeFolder = $DefaultPath2HomeFolder
    }

    # New-SmbMapping -LocalPath "C:\UsersHome\$($Username)\HomeFolder" -RemotePath $Path2HomeFolder -UserName $Username -Password $SoursePassword -Persistent $True -SaveCredentials -HomeFolder -ea Stop

    PrintNewLine
    PrintOperationBegin "Creating user home folder..."
    New-Item -Path $Path2HomeFolder -ItemType Directory -Force -ea Stop
    PrintOperationSuccess "User home folder was created."

    # try {
    #     Write-Host "Sharing user home folder..."
    #     New-SmbShare -Path $Path2HomeFolder -ea Stop
    # }
    # catch {
    #     Write-Host "User home folder is alredy shared"
    # }
    

    $Path2Profile = $Path_to_profile
    $DefaultPath2Profile = "C:\UsersHome\$Username\Profile"
    if (($Null -eq $Path2Profile) -or ($Path2Profile -eq "")) {
        $Path2Profile = $DefaultPath2Profile
    } 
    elseif (!(Test-Path -Path $Path2Profile)) {
        $Path2Profile = $DefaultPath2Profile
    } 
    elseif (!(Test-Path -IsValid -Path $Path2Profile)) {
        $Path2Profile = $DefaultPath2Profile
    }

    PrintNewLine
    PrintOperationBegin "Creating user profile folder..."
    New-Item -Path $Path2Profile -ItemType Directory -Force -ea Stop
    PrintOperationSuccess "User profile folder created."

    PrintNewLine
    PrintNewLine
    PrintOperationBegin "Creating user..."
    $_Name = $Username
    $_GivenName = "$($First_name) $($Patronymic)" 
    $_Surname = $Last_name 
    $_DisplayName = $DisplayName 
    $_UserPrincipalName = $UserPrincipalName 
    $_SamAccountName = $Username 
    $_Title = $Post 
    $_Department = $Department 
    $_EmailAddress = $Email 
    $_MobilePhone = $Phone 
    $_AccountPassword = $Password 
    $_PasswordNeverExpires = $true
    $_Path = $DistinguishedPath2OuSubs #"OU=$($Ou_name),DC=$($Domain),DC=$($CommonDomainComponent)" 
    $_Enabled = $true
    $_HomeDrive = $HomeFolderMask
    $_HomeDirectory = $Path2HomeFolder
    $_ProfilePath = $Path2Profile

    New-ADUser -Name $_Name -GivenName $_GivenName -Surname $_Surname -DisplayName $_DisplayName -UserPrincipalName $_UserPrincipalName -SamAccountName $_SamAccountName -Title $_Title -Department $_Department -EmailAddress $_EmailAddress -MobilePhone $_MobilePhone -AccountPassword $_AccountPassword -PasswordNeverExpires $_PasswordNeverExpires -Path $_Path -Enabled $_Enabled -HomeDirectory $_HomeDirectory -HomeDrive $_HomeDrive -ProfilePath $_ProfilePath
    
    Get-ADUser -Identity $DistinguishedPath2OuUser
    PrintOperationSuccess "User $($DisplayName) was created."
    $CreatedUserCounter += 1
    $Log += "User: $($DisplayName) created.`n"


    $Group_names += ",gAllUsers"
    foreach ($groupname in ($Group_names -split ',', 0, "simplematch")) {
        $Path2Group = $Null
        PrintNewLine
        PrintNewLine
        if(!(Get-ADGroup -Filter { Name -eq $groupname })) {
            PrintCheck "Group $($groupname) does not exist."
            PrintOperationBegin "Creating group..."
            $Path2Group = $DistinguishedPath2OuSubs 
            
            New-ADGroup -Name $groupname -GroupCategory Security -GroupScope Global -Path $Path2Group
            PrintOperationSuccess "Group was created."
            $CreatedGroupsCounter += 1
            $Log += "Group: $($groupname) created.`n"
        } else 
        {
            PrintInfo "Group $($groupname) is alredy exist."
        }

        PrintNewLine
        PrintOperationBegin "Adding $($DisplayName) to $($groupname) group..."
        $members = Get-ADGroupMember -Identity $groupname -Recursive | Select-Object -ExpandProperty UserPrincipalName
        if ($members -notcontains $DistinguishedPath2OuUser) {
            Add-ADGroupMember $groupname -Members $Username
            PrintOperationSuccess "$($DisplayName) was added to $($groupname) group."
        } else 
        {
            PrintInfo "$($DisplayName) is already in this group."
        }
    }


    PrintNewLine
    PrintNewLine
    $UserObj = Get-ADUser -Identity $DistinguishedPath2OuUser
    
    PrintOperationBegin "Setting permissions to main folder..."
    $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
    $FileSystemRights  = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute
    $InheritanceFlags  = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit
    $PropagationFlags  = [System.Security.AccessControl.PropagationFlags]::InheritOnly

    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($UserObj.SID, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)

    $ACL = Get-Acl $Path2MainFolder
    # Отключаем наследование правил:
    $ACL.SetAccessRuleProtection($True, $True) # 1st True = является ли этот объект защищенным, 2nd True = нужно ли скопировать NTFS разрешения.
    $ACL.AddAccessRule($AccessRule)
    Set-Acl -Path $Path2MainFolder -AclObject $ACL -ea Stop
    PrintOperationSuccess "Permissions to main folder are ready."


    PrintNewLine
    PrintOperationBegin "Setting permissions to user home folder..."
    $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
    $FileSystemRights  = [System.Security.AccessControl.FileSystemRights]::Modify
    $InheritanceFlags  = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
    $PropagationFlags  = [System.Security.AccessControl.PropagationFlags]::InheritOnly

    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($UserObj.SID, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)

    $ACL = Get-Acl $Path2HomeFolder
    $ACL.SetAccessRuleProtection($True, $True)
    $ACL.AddAccessRule($AccessRule)
    Set-Acl -Path $Path2HomeFolder -AclObject $ACL -ea Stop
    PrintOperationSuccess "Permissions to to user home folder are ready."


    PrintNewLine
    PrintOperationBegin "Setting permissions to user profile folder..."
    $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
    $FileSystemRights  = [System.Security.AccessControl.FileSystemRights]::Modify
    $InheritanceFlags  = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
    $PropagationFlags  = [System.Security.AccessControl.PropagationFlags]::InheritOnly

    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($UserObj.SID, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)

    $ACL = Get-Acl $Path2Profile
    $ACL.SetAccessRuleProtection($True, $True)
    $ACL.AddAccessRule($AccessRule)
    Set-Acl -Path $Path2Profile -AclObject $ACL -ea Stop
    PrintOperationSuccess "Permissions to user profile folder are ready."
}



$Html = "<html>`n" + $Log + "`nUsers created: $($CreatedUserCounter).`nGroups created: $($CreatedGroupsCounter).`nOrganization units created: $($CreatedOuCounter).`n" + "</html>"
Set-Content -Path "Creation_log.html" -Value $Html









