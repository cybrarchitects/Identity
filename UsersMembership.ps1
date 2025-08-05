#####created by Javid Ibrahimov#####
Import-Module -Name .\IdentityAuth.psm1
cls
[string]$subdomain = Read-Host 'Please provide your tenant subdomain'
[string]$platformURL = "https://platform-discovery.cyberark.cloud/api/identity-endpoint/" + $subdomain

$identity = Invoke-RestMethod -Uri $platformURL -Method Get
[string]$identityURL = $identity.endpoint
[string]$identityUser = Read-Host 'Please provide your username'

$logonToken = Get-IdentityHeader -IdentityTenantURL $identityURL -IdentityUserName $identityUser

[string]$ReportURL = $identityURL + "/redrock/query"

$sqlRequest = "@/lib/all_roles_with_members.js"

$body = @{ 
    Script = $sqlRequest
    } | convertto-json

$GetMembershipReports = Invoke-RestMethod -Uri $ReportURL -Method POST -Headers $logonToken -body $body -ContentType "application/json"

$UserRoleMember = $GetMembershipReports.Result.Results
$URMreport = @()

foreach ($i in $UserRoleMember.row)
{
    foreach ($m in $i.Members)
    {
        $URMreport += [PSCustomObject]@{ 
        RoleName = $i.Name
        RoleDescription = $i.Description
        RoleID = $i.Id
        Member = $m}
    }
    
}
$Filename = $subdomain + '_UserMembership.csv'
$URMreport | export-csv $Filename -NoTypeInformation

