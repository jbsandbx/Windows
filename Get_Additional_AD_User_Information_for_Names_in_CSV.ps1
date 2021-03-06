# Import givenName and surName (sn) from csv
# Find additional user information from Active Directory
# Export results to another csv file

# Petri.Paavola@yodamiitti.fi
# 28.3.2019


# Import names from csv file as UTF8
# Save source csv file as UTF8 if you use scandic letters
#
# csv file has to have header which has sn,givenName -attributes
#
# sn,givenName
#
#$UserNamesInCSV = Import-Csv "$PSScriptRoot\userNames.csv"
$UserNamesInCSV = Import-Csv "C:\temp\Powershell\userNames.csv" -Encoding UTF8


# File where to save information
#$outputfile = "$PSScriptRoot\UsersWithAdditionalInformation.csv"
$outputfile = "C:\temp\Powershell\UsersWithAdditionalInformation.csv"

# Base OU where to find users from
# This helps exclude for example admin accounts which have same name
$SearchBaseOU = "OU=users,OU=root,DC=org,DC=contoso,DC=com"


# Initialize variable where user AD information is stored
$ADUserInformation = @()

# Loop each user and get additional information from Active Directory
foreach ($user in $UserNamesInCSV) {
    $givenName = $user.givenName
    $sn = $user.sn

    # Get ADUser information
    $UserInfo = get-aduser -Filter {(givenName -eq $givenName) -AND (sn -eq $sn)} -Properties givenName,sn,DisplayName,sAMAccountName,mail -SearchBase $SearchBaseOU

    # Test if we found 1 or more results
    if($UserInfo -is [ARRAY]) {
        # Search returned multiple user accounts.
        # For example Admin accounts can have same givenName and surName than normal accounts
        #
        # Decide what to do in this case!

        Write-Output "Found multiple users for search: givenName=$givenName sn=$sn"
        Write-Output "$UserInfo"

        # Add user to destination csv without additional information so we know we didn't get results to all users
        $EmptyUserObject = New-Object Object
        $EmptyUserObject | Add-Member -NotePropertyName givenName -NotePropertyValue $givenName
        $EmptyUserObject | Add-Member -NotePropertyName sn -NotePropertyValue $sn

        $ADUserInformation += $EmptyUserObject

    } elseif($UserInfo -eq $null) {
        # Search did not return any results
        #
        # Add user to destination csv without additional information so we know we didn't get results to all users

        Write-Output "Did not find ADUser with information: givenName=$givenName sn=$sn"

        $EmptyUserObject = New-Object Object
        $EmptyUserObject | Add-Member -NotePropertyName givenName -NotePropertyValue $givenName
        $EmptyUserObject | Add-Member -NotePropertyName sn -NotePropertyValue $sn

        $ADUserInformation += $EmptyUserObject

    } else {
        # There was only 1 user account with givenName and surName which is what we are looking for

        # Add user information to array of ADUser objects
        $ADUserInformation += $UserInfo
    }
}

# Export ADUser information to csv-file
# Export as UTF8 so scandic letters work
$ADUserInformation | Select-Object sn,givenName,displayName,sAMAccountName,mail | Export-Csv -Path "$outputfile" -NoTypeInformation -Encoding UTF8
