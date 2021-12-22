$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = "LDAP://ou=Dismissed,ou=Users,ou=CC-Rostov,ou=Branches,dc=corp,dc=tele2,dc=ru"
$objSearcher.Filter = "(&(objectCategory=person))"
$users = $objSearcher.FindAll()
# Количество учетных записей
$users.Count 
$users | ForEach-Object {
   $user = $_.Properties
   New-Object PsObject -Property @{
   givenName = [string]$user.givenName
   sn = [string]$user.sn
   displayName = [string]$user.displayName
   description = [string]$user.description
    }
} | Export-Csv -NoClobber -Encoding utf8 -Path  c:\dilin\diss.csv