$group = Get-AdGroup "App CallAdministrator Users"

Get-ADUser -Filter {(MemberOf -recursivematch $group.DistinguishedName) -and (Enabled -eq $true)} -Properties * |ft displayName -AutoSize   | Out-File D:\dmitry.v.ilin\AppCallAdministratorUser.txt -Encoding "UTF8"