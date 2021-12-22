cls
$pc = hostname 
$date = Get-Date 
$user = whoami
$v = $pc +";"+$user+";"+$date
out-file  -Append \\t2ru\ZRfolders\Scripts\GPOscripts\logon.txt -InputObject $v
