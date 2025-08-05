#####created by Javid Ibrahimov#####
Import-Module -Name .\IdentityAuth.psm1
cls
[string]$subdomain = Read-Host 'Please provide your tenant subdomain'
[string]$platformURL = "https://platform-discovery.cyberark.cloud/api/identity-endpoint/" + $subdomain

$identity = Invoke-RestMethod -Uri $platformURL -Method Get
[string]$identityURL = $identity.endpoint
[string]$identityUser = Read-Host 'Please provide your username'

$logonToken = Get-IdentityHeader -IdentityTenantURL $identityURL -IdentityUserName $identityUser
function StringModificator
    {
        param ([string]$string, [char]$character)
        $LastIndex = $string.LastIndexOf($character)
        if ($LastIndex -ne -1) {$ResultString = $string.Substring($LastIndex +1)}
        else {$ResultString = $string}
        return $ResultString
    }

[string]$URLlink = $identityURL + "/Policy/GetNicePlinks"
$PoliciesLink = Invoke-RestMethod -Uri $URLlink -Method Get -Headers $logonToken -ContentType "application/json"
$Links = $PoliciesLink.Result.Results.entities.key
$settings = @()
foreach ($link in $Links)
    {
        [string]$URLblock = $identityURL + "/Policy/GetPolicyBlock?name=" + $link
        $PolicyBlock = Invoke-RestMethod -Uri $URLblock -Method GET -Headers $logonToken -ContentType "application/json"
        #$PolicyBlock.Result | export-csv "Policies.csv" -Append -NoTypeInformation
        $PolicyName = $PolicyBlock.Result.Path
        $PolicyName = StringModificator -string $PolicyBlock.Result.Path -character '/'
        $temp = @()
        #$PolicyBlock.Result.AuthProfiles | Export-Csv $PolicyName"AuthenticationProfile.csv" -NoTypeInformation
        $PolicyBlock.Result.Settings | gm -MemberType NoteProperty | % {
        $temp += $_.Definition}
        foreach ($t in $temp)
            {
            [string]$name=''
            $value=''
            $newName=''
            $name = StringModificator -string $t -character '/'
            $name = StringModificator -string $name -character ' '
            $LastEQIndex = $name.Lastindexof('=')
            if ($LastEQIndex -ne -1)
                {
                    $newName = $name.Substring(0,$LastEQIndex)
                    $value = $name.Substring($LastEQIndex +1)
                    }else{
                    $newName = ''
                    $value = ''
                    }
            #Write-Host $newName '=' $value
            $settings +=[PSCustomObject]@{
            PolicyName = $PolicyName
            PolicyDescription = $PolicyBlock.Result.Description
            ParameterName = $newName
            ParameterValue = $value
            }
            }
}

$FileAuthProfiles = $subdomain + '_All_AuthProfiles.csv'
if (Test-Path -path 'AuthenticationProfiles')
    {if (Test-Path -Path $FileAuthProfiles){Remove-Item -Path $path2}}
else {mkdir 'AuthenticationProfiles'}

foreach ($authProfile in $PolicyBlock.Result.AuthProfiles) 
    {
        [string]$challenges = ''
        foreach ($challenge in $authProfile.challenges)
            {
                $challenges += $challenge + ';'
            }
        $challenges = $challenges.Replace(',',' or ')
        $ap = @()
        $ap +=[PSCustomObject]@{
        UUID = $authProfile.Uuid
        Name = $authProfile.Name
        Duration_in_Minutes = $authProfile.DurationInMinutes
        Challenges = $Challenges
        SingleChallengeMechanism = $authProfile.SingleChallengeMechanisms
        AdditionalData = $authProfile.AdditionalData
        }
        $path = 'AuthenticationProfiles\' + $ap.uuid + '.csv'
        $ap | Export-Csv $path  -NoTypeInformation
        $ap | export-csv  $FileAuthProfiles -NoTypeInformation -Append

    }
$FileDirectorySrvs = $subdomain + '_DirectoryServices.csv'
$PolicyBlock.Result.DirectoryServices | export-csv -Path $FileDirectorySrvs -NoTypeInformation
$FilePolicies = $subdomain + '_Policies.csv'
$settings | Export-Csv $FilePolicies -NoTypeInformation