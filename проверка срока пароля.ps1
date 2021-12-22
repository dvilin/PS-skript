Import-Module ActiveDirectory 
Add-Type -assembly System.Windows.Forms 
$maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge | Select Days 
$main_form = New-Object System.Windows.Forms.Form 
$main_form.Text ='Проверка срока пароля' 
$main_form.Width = 120 
$main_form.Height = 200 
$main_form.AutoSize = $true 
$main_form.StartPosition = "CenterScreen" 

$TextBox = New-Object System.Windows.Forms.TextBox 
$TextBox.Location = New-Object System.Drawing.Point(100,10) 
$TextBox.Text = 'Введите логин' 
$main_form.Controls.Add($TextBox) 
$result = New-Object System.Windows.Forms.Button 
$result.Location = New-Object System.Drawing.Size(200,10) 
$result.Size = New-Object System.Drawing.Size(30,20) 
$result.Text = "OK" 
$main_form.Controls.Add($result) 
$ListBox = New-Object System.Windows.Forms.ListBox 
$ListBox.Location = New-Object System.Drawing.Point(15,50) 
$ListBox.Width = 300 
$ListBox.Height = 120 

$main_form.Controls.add($ListBox) 

#кнопка OK
$result.Add_Click({ 
$s = $null 
if (($TextBox.Text -match "[\w]") -or ($TextBox.Text -ne 'Введите логин')){ 
[string]$accounSearch = '*'+ $TextBox.Text + '*' 
[array]$s = Get-ADUser -Filter {(samaccountname -like $accounSearch) -or ( name -like $accounSearch )} -properties 'PasswordExpired','PasswordLastSet','PasswordNeverExpires' |` 
sort-object 'name','samaccountname' | Select-Object name,samaccountname,PasswordExpired,PasswordLastSet,PasswordNeverExpires 
} 
if ($s.count -ge 1){ 

      if ($s.count -le 5 ){ 
      $ListBox.Items.Clear() 
      $ListBox.AutoSize = $true 
      $ListBox.Width = 300 
      $ListBox.Height = 120 
      $main_form.Width = 50 
      $main_form.Height = 300 
} 
else{   $ListBox.AutoSize = $false 
      $ListBox.Items.Clear() 
      $ListBox.Width = 300 
      $ListBox.Height = 520 
      $main_form.Width = 50 
      $main_form.Height = 300 
} 
      $s | % { 
      $User = $_ 
      $ListBox.Items.Add("Пользователь" +" " + $User.name); 
      $ListBox.Items.Add("Пароль изменен" + " " + (get-date ($User.PasswordLastSet) -f ("dd.MM.yyy HH:mm:ss"))); 
      $ListBox.Items.Add("Максимальный срок действия пароля (дней)" + " " + $maxPasswordAgeTimeSpan.Days); 
      $ListBox.Items.Add("Пароль истекает" + " " + (get-date (Get-Date $User.PasswordLastSet).adddays(+$maxPasswordAgeTimeSpan.Days) -f ("dd.MM.yyy HH:mm:ss"))); 
      $ListBox.Items.Add('-------------------------------------------------------------------------------------------') 
}} 
else{ 
$ListBox.Items.Clear() 
$ListBox.Items.Add("Введите верный логин") 
} 
}) 
$main_form.ShowDialog()|Out-null 
