Get-ADComputer -Filter 'Name -like "wszr-*"'
$serials = $computers.Name | 
Foreach-Object {Get-WMIObject Win32_Bios -ComputerName $_ -ErrorAction SilentlyContinue | 
Select-Object PSComputerName,SerialNumber}
Export-Csv -Path 'C:\dvilin\serials.csv' -NoTypeInformation -InputObject $serials