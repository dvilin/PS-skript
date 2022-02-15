$zr_xenapp_servers=get-adcomputer -filter `
'name -like "t2zr-xenapp-*" -or Name -like "BO-*" -or Name -like "MONITOR-*" -or Name -like "ATSALE-*" -or Name -like "WSZR-STOPER-*" -or Name -like "WSZR-TCS-*" -or Name -like "WSZR-TSALE-*" -or Name -like "WSZR-EXP-*" -or Name -like "WSZR-TRAINER-*" -or Name -like "WSZS-LEADING-*" -or Name -like "WSZR-SSERV-*" -or Name -like "WSZI-OBO-*" -or Name -like "WSZR-WEBSHOP-*"' `
-properties *

$txt_path_invoiceclient_bercutdb2 = "\\corp.doman.ru\folders\scripts\num_version_2.txt"
$txt_path_invoiceclient_bercutdb3 = "\\corp.doman.ru\folders\scripts\num_version_3.txt"
$txt_path_invoiceclient_bercutdb4 = "\\corp.doman.ru\folders\scripts\num_version_4.txt"
$txt_path_invoiceclient_bercutdb5 = "\\corp.doman.ru\folders\scripts\num_version_5.txt"

$num_version_client_bercutdb2=get-content $txt_path_invoiceclient_bercutdb2 -totalcount 1
$num_version_client_bercutdb3=get-content $txt_path_invoiceclient_bercutdb3 -totalcount 1
$num_version_client_bercutdb4=get-content $txt_path_invoiceclient_bercutdb4 -totalcount 1
$num_version_client_bercutdb5=get-content $txt_path_invoiceclient_bercutdb5 -totalcount 1

$path_distrib_invoiceclient = "\\corp.doman.ru\folders\" + $num_version_client_bercutdb2

$zr_xenapp_servers | foreach-object {
$path_xenapp_programfiles = "\\"+$_.name+"\c$\program files\"
$path_xenapp = "\\"+$_.name+"\c$\program files\"+$num_version_client_bercutdb2
#$rem = "\\"+$_.name+"\c$\program files\*"
if (!(test-path -path $path_xenapp_programfiles)) {
    write-host $_.name "хост недоступен"
}
else {
    if(!(test-path -path $path_xenapp)){
        write-host $path_xenapp "каталог не найден, попытка копировать каталог"
        copy-item -recurse -path $path_distrib_invoiceclient -destination $path_xenapp 
		#Remove-Item –path $rem -Recurse
    }
    else {
        write-host "не обновлено, каталог" $path_xenapp "был создан ранее"
        #Remove-Item –path $rem -Recurse
    }
}
}