<#
.SYNOPSIS
Get Server Information
.DESCRIPTION
This script will get the CPU specifications, memory usage statistics, and OS configuration of any Server or Computer listed in Serverlist.txt.
.NOTES  
The script will execute the commands on multiple machines sequentially using non-concurrent sessions. This will process all servers from Serverlist.txt in the listed order.
The info will be exported to a csv format.
Requires: Serverlist.txt must be created in the same folder where the script is.
File Name  : get-server-info.ps1
Author: Nikolay Petkov
http://power-shell.com/
#>
#Get the server list
#$servers = Get-Content C:\dvilin\Serverlist.txt
#Run the commands for each server in the list
$infoColl = @()
Get-ADComputer -Filter 'Name -like "*r-xenapp-*"'  -Properties * |
ForEach-Object {
    if ((Test-Connection -computer $_.dnshostname -quiet) -eq $True) 
	    {$CPUInfo = Get-WmiObject Win32_Processor -ComputerName $_.dnshostname #Get CPU Information
	    $OSInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $_.dnshostname #Get OS Information
	    #Get Memory Information. The data will be shown in a table as MB, rounded to the nearest second decimal.
	    $OSTotalVirtualMemory = [math]::round($OSInfo.TotalVirtualMemorySize / 1MB, 2)
	    $OSTotalVisibleMemory = [math]::round(($OSInfo.TotalVisibleMemorySize / 1MB), 2)
	    $PhysicalMemory = Get-WmiObject CIM_PhysicalMemory -ComputerName $_.dnshostname | Measure-Object -Property capacity -Sum | % { [Math]::Round(($_.sum / 1GB), 2) }
	    Foreach ($CPU in $CPUInfo)
	    {
		    $infoObject = New-Object PSObject
		    #The following add data to the infoObjects.	
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "ServerName" -value $CPU.SystemName
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "Processor" -value $CPU.Name
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "Model" -value $CPU.Description
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "Manufacturer" -value $CPU.Manufacturer
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "PhysicalCores" -value $CPU.NumberOfCores
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L2CacheSize" -value $CPU.L2CacheSize
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L3CacheSize" -value $CPU.L3CacheSize
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "Sockets" -value $CPU.SocketDesignation
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "LogicalCores" -value $CPU.NumberOfLogicalProcessors
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Name" -value $OSInfo.Caption
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Version" -value $OSInfo.Version
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalPhysical_Memory_GB" -value $PhysicalMemory
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVirtual_Memory_MB" -value $OSTotalVirtualMemory
		    Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVisable_Memory_MB" -value $OSTotalVisibleMemory
		    $infoObject #Output to the screen for a visual feedback.
		    $infoColl += $infoObject
	    }}
    Else {
        $infoObject = New-Object PSObject
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "ServerName" -value $_.dnshostname
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "Processor" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "Model" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "Manufacturer" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "PhysicalCores" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L2CacheSize" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_L3CacheSize" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "Sockets" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "LogicalCores" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Name" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS_Version" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalPhysical_Memory_GB" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVirtual_Memory_MB" -value "0"
        Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalVisable_Memory_MB" -value "0"
        $infoObject #Output to the screen for a visual feedback.
        $infoColl += $infoObject
    }
}
$infoColl | Export-Csv -path C:\dvilin\Server_Inventory_$((Get-Date).ToString('MM-dd-yyyy')).csv -NoTypeInformation #Export the results in csv file.