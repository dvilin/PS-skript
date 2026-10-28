# ================= НАСТРОЙКИ =================
# Перед запуском замените FILESERVER, USER_FOLDER и USERNAME, а также проверьте сетевые каталоги.
# Логин пользователя для каталога export.dbf\users\<логин>
$UserLogin = "USERNAME"

# Имя каталога пользователя в исходном DFS-пути
$ExchangeUser = "USER_FOLDER"

# Дату можно задать вручную (формат: "09.07.2026") или оставить $null — тогда возьмётся сегодняшняя
$CustomDate = $null  # например: "09.07.2026" или $null

# Базовые сетевые пути
$BaseShare     = "\\FILESERVER\dfs\exchange\in\it2\$ExchangeUser"
$DestArchive   = "\\FILESERVER\group\archive\2026"
$DestDbf       = "\\FILESERVER\dfs\export\import.dbf\terror"
$DestTerrorXml = "\\FILESERVER\dfs\export\work\TERROR\XML"
$SourceUserFiles = "\\FILESERVER\dfs\export\export.dbf\users\$UserLogin"
# =============================================

$ErrorActionPreference = "Stop"

# --- Формируем дату и пути ---
if ($CustomDate) {
    $Date = [datetime]::ParseExact($CustomDate, "dd.MM.yyyy", $null)
} else {
    $Date = Get-Date
}

$DateStr   = $Date.ToString("dd.MM.yyyy")
$Year      = $Date.ToString("yyyy")
$YearMonth = $Date.ToString("yyyyMM")
$MonthEng  = $Date.ToString("MMM", [cultureinfo]::GetCultureInfo("en-US"))
$Day       = $Date.ToString("dd")

$SourceFolder = "$BaseShare\$Year\$YearMonth\$MonthEng$Day\terr"
$TerrBase     = "$BaseShare\$Year\terr_base"

$ArchiveName = "$DateStr-v 2.2.zip"
$XmlName     = "$DateStr-v 2.2.xml"
$FinalXml    = "TERROR.XML"

$SourceArchivePath = Join-Path $SourceFolder $ArchiveName
$SourceXmlPath     = Join-Path $SourceFolder $XmlName
$DestArchivePath   = Join-Path $DestArchive $ArchiveName
$DestDbfPath       = Join-Path $DestDbf $XmlName
$DestTerrorPath    = Join-Path $DestTerrorXml $FinalXml

Write-Host "=== Параметры ===" -ForegroundColor Cyan
Write-Host "Дата:             $DateStr"
Write-Host "Исходная папка:   $SourceFolder"
Write-Host "Каталог пользователя: $UserLogin"
Write-Host "================="

# ================= ЛОГИКА =================
try {
    # 1. Проверка архива
    Write-Host "`nШаг 1: Проверка архива"
    if (-not (Test-Path $SourceArchivePath)) {
        throw "Архив не найден: $SourceArchivePath"
    }
    Write-Host "[OK] Архив найден" -ForegroundColor Green

    # 2. Копирование архива (если нет)
    Write-Host "`nШаг 2: Копирование архива в $DestArchive"
    if (Test-Path $DestArchivePath) {
        Write-Host "[ПРОПУСК] Архив уже существует" -ForegroundColor Yellow
    } else {
        Copy-Item -Path $SourceArchivePath -Destination $DestArchivePath -Force
        Write-Host "[OK] Архив скопирован" -ForegroundColor Green
    }

    # 3. Распаковка
    Write-Host "`nШаг 3: Распаковка архива"
    Expand-Archive -Path $SourceArchivePath -DestinationPath $SourceFolder -Force
    Write-Host "[OK] Архив распакован" -ForegroundColor Green

    # 4. Проверка XML
    Write-Host "`nШаг 4: Проверка XML"
    if (-not (Test-Path $SourceXmlPath)) {
        throw "XML не найден: $SourceXmlPath"
    }
    Write-Host "[OK] XML найден" -ForegroundColor Green

    # 5. Копирование XML (если нет)
    Write-Host "`nШаг 5: Копирование XML в $DestDbf"
    if (Test-Path $DestDbfPath) {
        Write-Host "[ПРОПУСК] XML уже существует" -ForegroundColor Yellow
    } else {
        Copy-Item -Path $SourceXmlPath -Destination $DestDbfPath -Force
        Write-Host "[OK] XML скопирован" -ForegroundColor Green
    }

    # 6. Переименование
    Write-Host "`nШаг 6: Переименование в $FinalXml"
    $TerrorXmlPath = Join-Path $SourceFolder $FinalXml
    if (Test-Path $TerrorXmlPath) {
        Remove-Item -Path $TerrorXmlPath -Force
        Write-Host "[INFO] Старый $FinalXml удалён" -ForegroundColor Yellow
    }
    Rename-Item -Path $SourceXmlPath -NewName $FinalXml -Force
    Write-Host "[OK] Файл переименован" -ForegroundColor Green

    # 7. Копирование TERROR.XML
    Write-Host "`nШаг 7: Копирование $FinalXml в $DestTerrorXml"
    Copy-Item -Path $TerrorXmlPath -Destination $DestTerrorXml -Force
    Write-Host "[OK] Файл скопирован" -ForegroundColor Green

    # 8. Копирование дополнительных файлов из terr_base
    Write-Host "`nШаг 8: Копирование дополнительных файлов из $TerrBase"
    $PassportPath = Join-Path $TerrBase "PASSPORT.zip"
    $RtfSourcePath = Join-Path $TerrBase "terror_od_27.10.2026.rtf"
    foreach ($SourcePath in @($PassportPath, $RtfSourcePath)) {
        if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
            throw "Не найден обязательный файл: $SourcePath"
        }
    }
    Copy-Item -LiteralPath $PassportPath -Destination $SourceFolder -Force
    Write-Host "[OK] Скопирован PASSPORT.zip в $SourceFolder" -ForegroundColor Green

    # Word меняет видимый текст RTF, не повреждая его кодировку и форматирование.
    if ($RtfSourcePath -notmatch 'terror_od_(\d{2}\.\d{2}\.\d{4})\.rtf$') {
        throw "Не удалось извлечь исходную дату из имени RTF: $RtfSourcePath"
    }
    $TemplateDateStr = $Matches[1]
    $TemplateDate = [datetime]::ParseExact($TemplateDateStr, "dd.MM.yyyy", $null)
    $TemplateNextDateStr = $TemplateDate.AddDays(1).ToString("dd.MM.yyyy")
    $NextDateStr = $Date.AddDays(1).ToString("dd.MM.yyyy")
    $RtfDestName = "terror_od_$DateStr.rtf"
    $RtfDestPath = Join-Path $SourceFolder $RtfDestName

    $Word = $null
    $Document = $null
    try {
        $Word = New-Object -ComObject Word.Application
        $Word.Visible = $false
        $Word.DisplayAlerts = 0
        $Document = $Word.Documents.Open($RtfSourcePath, $false, $true)

        $Find = $Document.Content.Find
        $Find.ClearFormatting()
        $Find.Replacement.ClearFormatting()
        $Find.Text = $TemplateDateStr
        $Find.Replacement.Text = $DateStr
        $Find.Forward = $true
        $Find.Wrap = 1
        $Find.Format = $false
        $Find.MatchCase = $true
        $Find.MatchWholeWord = $false
        $Find.Execute($TemplateDateStr, $false, $false, $false, $false, $false, $true, 1, $false, $DateStr, 2) | Out-Null

        $Find = $Document.Content.Find
        $Find.ClearFormatting()
        $Find.Replacement.ClearFormatting()
        $Find.Text = $TemplateNextDateStr
        $Find.Replacement.Text = $NextDateStr
        $Find.Forward = $true
        $Find.Wrap = 1
        $Find.Format = $false
        $Find.MatchCase = $true
        $Find.MatchWholeWord = $false
        $Find.Execute($TemplateNextDateStr, $false, $false, $false, $false, $false, $true, 1, $false, $NextDateStr, 2) | Out-Null

        $Document.SaveAs2($RtfDestPath, 6)
        Write-Host "[OK] RTF с обновлёнными датами сохранён как $RtfDestName в $SourceFolder" -ForegroundColor Green
    }
    finally {
        if ($Document -ne $null) { $Document.Close(0) }
        if ($Word -ne $null) { $Word.Quit() }
    }

    # 9. Ожидание подтверждения готовности сводного отчёта
    Write-Host "`nОжидание подтверждения: «Сводный отчет готов?»"
    Add-Type -AssemblyName System.Windows.Forms
    do {
        $Choice = [System.Windows.Forms.MessageBox]::Show(
            "Сводный отчет готов?`r`n`r`nНажмите «Да», чтобы скопировать cln_terror.txt и cust_terror.txt. При выборе «Нет» вопрос появится снова.",
            "Подтверждение",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
    } while ($Choice -ne [System.Windows.Forms.DialogResult]::Yes)

    if ($Choice -eq [System.Windows.Forms.DialogResult]::Yes) {
        # 10. Копирование файлов пользователя
        Write-Host "`nШаг 10: Копирование файлов пользователя $UserLogin в $DestDbf"
        $UserFileNames = @("cln_terror.txt", "cust_terror.txt")
        foreach ($FileName in $UserFileNames) {
            $SourcePath = Join-Path $SourceUserFiles $FileName
            if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
                throw "Не найден обязательный файл: $SourcePath"
            }
            Move-Item -LiteralPath $SourcePath -Destination $DestDbf -Force
            Write-Host "[OK] Файл $FileName перенесён в $DestDbf" -ForegroundColor Green
        }
    }

    Write-Host "`n=== Скрипт успешно завершён ===" -ForegroundColor Green
}
catch {
    Write-Host "`n!!! ОШИБКА: $_" -ForegroundColor Red
    exit 1
}
