Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

[System.Windows.Forms.Application]::EnableVisualStyles()

function Normalize-Text {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    return ($Text.ToLowerInvariant() -replace '[^a-z0-9]', '')
}

function Get-SHA1 {
    param([string]$filePath)
    return (Get-FileHash -Path $filePath -Algorithm SHA1).Hash
}

function Get-ZoneIdentifier {
    param([string]$filePath)
    try {
        $ads = Get-Content -Raw -Stream Zone.Identifier $filePath -ErrorAction SilentlyContinue
        if ($ads -match "HostUrl=(.+)") {
            return $matches[1]
        }
    } catch {}
    return $null
}

function Fetch-Modrinth {
    param([string]$hash)
    try {
        $response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($response.project_id) {
            $projectResponse = "https://api.modrinth.com/v2/project/$($response.project_id)"
            $projectData = Invoke-RestMethod -Uri $projectResponse -Method Get -UseBasicParsing -ErrorAction Stop
            return @{
                Name = $projectData.title
                Slug = $projectData.slug
            }
        }
    } catch {}
    return @{
        Name = ""
        Slug = ""
    }
}

function Fetch-Megabase {
    param([string]$hash)
    try {
        $response = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if (-not $response.error) {
            return $response.data
        }
    } catch {}
    return $null
}

$cheatStrings = @(
    "AimAssist","AnchorTweaks","AutoAnchor","AutoCrystal","AutoDoubleHand","AutoHitCrystal",
    "AutoPot","AutoTotem","AutoArmor","InventoryTotem","Hitboxes","JumpReset","LegitTotem",
    "PingSpoof","SelfDestruct","ShieldBreaker","TriggerBot","Velocity","AxeSpam","WebMacro",
    "FastPlace","illegalmodifications","stringcleaner","autoretotem","autoinventorytotem",
    "smarttotem","fasttotem","totempredict","armoroptimizer","autogapple","offhandmanager",
    "autoswap","clickaimassist","legitaimassist","smoothaim","adaptiveaim","stickyaim",
    "autoclicker","fakecps","clicksimulation","clickrandomizer","aimrandomizer",
    "delayrandomizer","attackdelay","switchdelay","attackinvisibles","hitdelay",
    "nomissdelay","delayedhit","hitsync","multipoint","targetstrafe","reach","reachassist",
    "velocitycontrol","antikb","velocityboost","speedmultiplier","speedcontrol","speeddelay",
    "verticalspeed","horizontalspeed","strafecontrol","movementfix","fastfall","glidecontrol",
    "autowtap","smartwtap","autojumpreset","autoswitch","keepSprint","sworddelay","axedelay",
    "onlycritsword","onlycritaxe","autocrit","critassist","slotselection","fakelag","xray",
    "netheritefinder","autoloot","stoponkill","genericautoanchor","smartanchor",
    "anchorprediction","anchorplacer","anchormacro","macroanchor","crystalaura",
    "smartcrystal","instantcrystal","crystalprediction","crystaloptimizer",
    "genericcrystaloptimizer","cwcrystal","autohitcrystal","doubleglowstone",
    "autoshieldbreaker","genericshieldbreaker","disableshields","genericdisableshield",
    "autopotrefill","switchback","equipdelay","heightexpansion","widthexpansion",
    "throwdelay","donutsmpbypass","blatantmode","legitmode","ghostmode","bypassmode",
    "humanizer","antisstool","genericselfdestruct","possibledestruct","deleteusnjournal",
    "logcleaner","attackplayers","syracruseclient","automace","macedamage","maceboost",
    "macecrit","maceaura","macevelocity","macefallboost","macekb","macecombo","maceassist",
    "maceaim","macestrafe","autopearl","pearlcatch","fastpearl","pearlmacro","pearlassist",
    "pearlprediction","pearltracker","pearlaim","pearlthrow","pearlspam","antipearl",
    "pearlcancel","pearlclutch"
) | Sort-Object -Unique

$normalizedCheatMap = @{}
foreach ($item in $cheatStrings) {
    $normalized = Normalize-Text $item
    if ($normalized -and -not $normalizedCheatMap.ContainsKey($normalized)) {
        $normalizedCheatMap[$normalized] = $item
    }
}

function Check-Strings {
    param([string]$filePath)

    $stringsFound = [System.Collections.Generic.HashSet[string]]::new()

    try {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        if (-not $bytes -or $bytes.Length -eq 0) {
            return $stringsFound
        }

        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        $normalizedContent = Normalize-Text $content

        foreach ($normalizedKey in $normalizedCheatMap.Keys) {
            if ($normalizedContent.Contains($normalizedKey)) {
                [void]$stringsFound.Add($normalizedCheatMap[$normalizedKey])
            }
        }
    } catch {}

    return $stringsFound
}

function New-Grid {
    param(
        [string]$Name,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H
    )

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Name = $Name
    $grid.Location = New-Object System.Drawing.Point($X, $Y)
    $grid.Size = New-Object System.Drawing.Size($W, $H)
    $grid.BackgroundColor = [System.Drawing.Color]::FromArgb(18, 18, 24)
    $grid.BorderStyle = 'FixedSingle'
    $grid.GridColor = [System.Drawing.Color]::FromArgb(50, 50, 60)
    $grid.EnableHeadersVisualStyles = $false
    $grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(34, 36, 48)
    $grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(22, 24, 30)
    $grid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $grid.RowHeadersVisible = $false
    $grid.AutoSizeColumnsMode = 'Fill'
    $grid.SelectionMode = 'FullRowSelect'
    $grid.MultiSelect = $false
    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    $grid.AllowUserToDeleteRows = $false
    $grid.AllowUserToResizeRows = $false
    return $grid
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "TESLAPRO Mod Analyzer"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1280, 820)
$form.MinimumSize = New-Object System.Drawing.Size(1200, 760)
$form.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 23)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(1280, 90)
$header.BackColor = [System.Drawing.Color]::FromArgb(20, 24, 34)
$header.Anchor = 'Top,Left,Right'

$title = New-Object System.Windows.Forms.Label
$title.Text = "TESLAPRO MOD ANALYZER"
$title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 22, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(90, 200, 250)
$title.Location = New-Object System.Drawing.Point(24, 14)
$title.AutoSize = $true

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "TESLAPRO  |  Discord = @teamwsf"
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subtitle.ForeColor = [System.Drawing.Color]::Silver
$subtitle.Location = New-Object System.Drawing.Point(28, 54)
$subtitle.AutoSize = $true

$header.Controls.Add($title)
$header.Controls.Add($subtitle)

$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Text = "Mods folder"
$pathLabel.Location = New-Object System.Drawing.Point(24, 110)
$pathLabel.AutoSize = $true
$pathLabel.ForeColor = [System.Drawing.Color]::Gainsboro

$pathBox = New-Object System.Windows.Forms.TextBox
$pathBox.Location = New-Object System.Drawing.Point(24, 135)
$pathBox.Size = New-Object System.Drawing.Size(930, 32)
$pathBox.BackColor = [System.Drawing.Color]::FromArgb(24, 26, 34)
$pathBox.ForeColor = [System.Drawing.Color]::White
$pathBox.BorderStyle = 'FixedSingle'
$pathBox.Text = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(970, 132)
$browseButton.Size = New-Object System.Drawing.Size(110, 36)
$browseButton.BackColor = [System.Drawing.Color]::FromArgb(35, 40, 54)
$browseButton.ForeColor = [System.Drawing.Color]::White
$browseButton.FlatStyle = 'Flat'

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = "Start Scan"
$scanButton.Location = New-Object System.Drawing.Point(1095, 132)
$scanButton.Size = New-Object System.Drawing.Size(140, 36)
$scanButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$scanButton.ForeColor = [System.Drawing.Color]::White
$scanButton.FlatStyle = 'Flat'

$summaryPanel = New-Object System.Windows.Forms.Panel
$summaryPanel.Location = New-Object System.Drawing.Point(24, 185)
$summaryPanel.Size = New-Object System.Drawing.Size(1211, 78)
$summaryPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 24, 34)
$summaryPanel.BorderStyle = 'FixedSingle'
$summaryPanel.Anchor = 'Top,Left,Right'

function New-SummaryLabel {
    param(
        [string]$Title,
        [int]$X,
        [System.Drawing.Color]$Color
    )
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Title
    $lbl.Location = New-Object System.Drawing.Point($X, 14)
    $lbl.Size = New-Object System.Drawing.Size(260, 24)
    $lbl.ForeColor = [System.Drawing.Color]::Silver
    $val = New-Object System.Windows.Forms.Label
    $val.Text = "0"
    $val.Location = New-Object System.Drawing.Point($X, 38)
    $val.Size = New-Object System.Drawing.Size(260, 28)
    $val.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
    $val.ForeColor = $Color
    return @($lbl, $val)
}

$sum1 = New-SummaryLabel "Verified mods" 25 ([System.Drawing.Color]::FromArgb(80, 220, 120))
$sum2 = New-SummaryLabel "Unknown mods" 325 ([System.Drawing.Color]::FromArgb(255, 200, 80))
$sum3 = New-SummaryLabel "Suspicious mods" 625 ([System.Drawing.Color]::FromArgb(255, 90, 90))
$sum4 = New-SummaryLabel "Scanned files" 925 ([System.Drawing.Color]::FromArgb(90, 200, 250))

$summaryPanel.Controls.AddRange(@($sum1[0],$sum1[1],$sum2[0],$sum2[1],$sum3[0],$sum3[1],$sum4[0],$sum4[1]))

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(24, 280)
$tabs.Size = New-Object System.Drawing.Size(1211, 445)
$tabs.Anchor = 'Top,Bottom,Left,Right'
$tabs.Appearance = 'Normal'

$tabVerified = New-Object System.Windows.Forms.TabPage
$tabVerified.Text = "Verified"
$tabVerified.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 23)

$tabUnknown = New-Object System.Windows.Forms.TabPage
$tabUnknown.Text = "Unknown"
$tabUnknown.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 23)

$tabSuspicious = New-Object System.Windows.Forms.TabPage
$tabSuspicious.Text = "Suspicious"
$tabSuspicious.BackColor = [System.Drawing.Color]::FromArgb(15, 17, 23)

$gridVerified = New-Grid "gridVerified" 10 10 1175 395
$gridUnknown = New-Grid "gridUnknown" 10 10 1175 395
$gridSuspicious = New-Grid "gridSuspicious" 10 10 1175 395

$tabVerified.Controls.Add($gridVerified)
$tabUnknown.Controls.Add($gridUnknown)
$tabSuspicious.Controls.Add($gridSuspicious)

$tabs.TabPages.AddRange(@($tabVerified, $tabUnknown, $tabSuspicious))

$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.BackColor = [System.Drawing.Color]::FromArgb(20, 24, 34)
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready."
$statusLabel.ForeColor = [System.Drawing.Color]::White
$statusLabel.Spring = $true

$progressBar = New-Object System.Windows.Forms.ToolStripProgressBar
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Size = New-Object System.Drawing.Size(220, 18)

$statusBar.Items.Add($statusLabel) | Out-Null
$statusBar.Items.Add($progressBar) | Out-Null

$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Text = "Export Results"
$exportButton.Location = New-Object System.Drawing.Point(1095, 735)
$exportButton.Size = New-Object System.Drawing.Size(140, 32)
$exportButton.BackColor = [System.Drawing.Color]::FromArgb(35, 40, 54)
$exportButton.ForeColor = [System.Drawing.Color]::White
$exportButton.FlatStyle = 'Flat'
$exportButton.Anchor = 'Bottom,Right'

$form.Controls.AddRange(@(
    $header, $pathLabel, $pathBox, $browseButton, $scanButton,
    $summaryPanel, $tabs, $exportButton, $statusBar
))

$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Select the mods folder"

$saveDialog = New-Object System.Windows.Forms.SaveFileDialog
$saveDialog.Filter = "Text files (*.txt)|*.txt"
$saveDialog.FileName = "TESLAPRO-Scan-Results.txt"

$scanResults = @{
    Verified   = @()
    Unknown    = @()
    Suspicious = @()
    Total      = 0
    Path       = ""
}

$browseButton.Add_Click({
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathBox.Text = $folderDialog.SelectedPath
    }
})

$exportButton.Add_Click({
    if (-not $scanResults.Path) {
        [System.Windows.Forms.MessageBox]::Show("No scan results available yet.", "TESLAPRO", "OK", "Information") | Out-Null
        return
    }

    if ($saveDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        return
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("TESLAPRO MOD ANALYZER")
    $lines.Add("Path: $($scanResults.Path)")
    $lines.Add("Scanned files: $($scanResults.Total)")
    $lines.Add("Verified: $($scanResults.Verified.Count)")
    $lines.Add("Unknown: $($scanResults.Unknown.Count)")
    $lines.Add("Suspicious: $($scanResults.Suspicious.Count)")
    $lines.Add("")

    $lines.Add("[ VERIFIED ]")
    foreach ($item in $scanResults.Verified) {
        $lines.Add("$($item.ModName) | $($item.FileName) | $($item.Source)")
    }
    $lines.Add("")

    $lines.Add("[ UNKNOWN ]")
    foreach ($item in $scanResults.Unknown) {
        $lines.Add("$($item.FileName) | $($item.ZoneId)")
    }
    $lines.Add("")

    $lines.Add("[ SUSPICIOUS ]")
    foreach ($item in $scanResults.Suspicious) {
        $dep = if ($item.DepFileName) { $item.DepFileName } else { "" }
        $lines.Add("$($item.FileName) | $dep | $([string]::Join(', ', $item.StringsFound))")
    }

    [System.IO.File]::WriteAllLines($saveDialog.FileName, $lines)
    [System.Windows.Forms.MessageBox]::Show("Results exported successfully.", "TESLAPRO", "OK", "Information") | Out-Null
})

$scanButton.Add_Click({
    $mods = $pathBox.Text.Trim()

    if (-not (Test-Path $mods -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("Invalid mods folder path.", "TESLAPRO", "OK", "Warning") | Out-Null
        return
    }

    $scanButton.Enabled = $false
    $browseButton.Enabled = $false
    $exportButton.Enabled = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    try {
        $statusLabel.Text = "Preparing scan..."
        $progressBar.Value = 0
        [System.Windows.Forms.Application]::DoEvents()

        $gridVerified.DataSource = $null
        $gridUnknown.DataSource = $null
        $gridSuspicious.DataSource = $null

        $verifiedMods = @()
        $unknownMods = @()
        $cheatMods = @()

        $jarFiles = Get-ChildItem -Path $mods -Filter *.jar -File -ErrorAction SilentlyContinue

        if (-not $jarFiles -or $jarFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No .jar files found in the selected folder.", "TESLAPRO", "OK", "Information") | Out-Null
            return
        }

        $totalMods = $jarFiles.Count
        $current = 0

        foreach ($file in $jarFiles) {
            $current++
            $statusLabel.Text = "Hash verification: $current / $totalMods - $($file.Name)"
            $progressBar.Value = [Math]::Min([int](($current / $totalMods) * 60), 60)
            [System.Windows.Forms.Application]::DoEvents()

            $hash = Get-SHA1 -filePath $file.FullName

            $modDataModrinth = Fetch-Modrinth -hash $hash
            if ($modDataModrinth.Slug) {
                $verifiedMods += [PSCustomObject]@{
                    ModName  = $modDataModrinth.Name
                    FileName = $file.Name
                    Source   = "Modrinth"
                }
                continue
            }

            $modDataMegabase = Fetch-Megabase -hash $hash
            if ($modDataMegabase.name) {
                $verifiedMods += [PSCustomObject]@{
                    ModName  = $modDataMegabase.Name
                    FileName = $file.Name
                    Source   = "Megabase"
                }
                continue
            }

            $zoneId = Get-ZoneIdentifier $file.FullName
            $unknownMods += [PSCustomObject]@{
                FileName = $file.Name
                FilePath = $file.FullName
                ZoneId   = $zoneId
            }
        }

        if ($unknownMods.Count -gt 0) {
            $tempDir = Join-Path $env:TEMP "teslapromodanalyzer_gui"
            $deepCurrent = 0
            $deepTotal = $unknownMods.Count

            try {
                if (Test-Path $tempDir) {
                    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
                }

                New-Item -ItemType Directory -Path $tempDir | Out-Null

                foreach ($mod in @($unknownMods)) {
                    $deepCurrent++
                    $statusLabel.Text = "Deep scan: $deepCurrent / $deepTotal - $($mod.FileName)"
                    $progressBar.Value = [Math]::Min(60 + [int](($deepCurrent / $deepTotal) * 40), 100)
                    [System.Windows.Forms.Application]::DoEvents()

                    $modStrings = Check-Strings $mod.FilePath
                    if ($modStrings.Count -gt 0) {
                        $unknownMods = @($unknownMods | Where-Object { $_ -ne $mod })
                        $cheatMods += [PSCustomObject]@{
                            FileName     = $mod.FileName
                            DepFileName  = $null
                            StringsFound = ($modStrings | Sort-Object)
                        }
                        continue
                    }

                    $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($mod.FileName)
                    $extractPath = Join-Path $tempDir $fileNameWithoutExt

                    if (Test-Path $extractPath) {
                        Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
                    }

                    New-Item -ItemType Directory -Path $extractPath | Out-Null

                    try {
                        [System.IO.Compression.ZipFile]::ExtractToDirectory($mod.FilePath, $extractPath)
                    } catch {
                        continue
                    }

                    $depJarsPath = Join-Path $extractPath "META-INF\jars"
                    if (-not (Test-Path $depJarsPath)) {
                        continue
                    }

                    $depJars = Get-ChildItem -Path $depJarsPath -File -ErrorAction SilentlyContinue
                    foreach ($jar in $depJars) {
                        $depStrings = Check-Strings $jar.FullName
                        if (-not $depStrings -or $depStrings.Count -eq 0) {
                            continue
                        }

                        $unknownMods = @($unknownMods | Where-Object { $_ -ne $mod })
                        $cheatMods += [PSCustomObject]@{
                            FileName     = $mod.FileName
                            DepFileName  = $jar.Name
                            StringsFound = ($depStrings | Sort-Object)
                        }
                    }
                }
            } finally {
                if (Test-Path $tempDir) {
                    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
                }
            }
        }

        $verifiedTable = New-Object System.Data.DataTable
        [void]$verifiedTable.Columns.Add("Mod Name")
        [void]$verifiedTable.Columns.Add("File Name")
        [void]$verifiedTable.Columns.Add("Source")
        foreach ($item in $verifiedMods | Sort-Object ModName, FileName) {
            [void]$verifiedTable.Rows.Add($item.ModName, $item.FileName, $item.Source)
        }

        $unknownTable = New-Object System.Data.DataTable
        [void]$unknownTable.Columns.Add("File Name")
        [void]$unknownTable.Columns.Add("Downloaded From")
        foreach ($item in $unknownMods | Sort-Object FileName) {
            [void]$unknownTable.Rows.Add($item.FileName, $item.ZoneId)
        }

        $suspiciousTable = New-Object System.Data.DataTable
        [void]$suspiciousTable.Columns.Add("File Name")
        [void]$suspiciousTable.Columns.Add("Embedded Jar")
        [void]$suspiciousTable.Columns.Add("Matches")
        foreach ($item in $cheatMods | Sort-Object FileName, DepFileName) {
            [void]$suspiciousTable.Rows.Add(
                $item.FileName,
                $item.DepFileName,
                [string]::Join(", ", $item.StringsFound)
            )
        }

        $gridVerified.DataSource = $verifiedTable
        $gridUnknown.DataSource = $unknownTable
        $gridSuspicious.DataSource = $suspiciousTable

        $sum1[1].Text = [string]$verifiedMods.Count
        $sum2[1].Text = [string]$unknownMods.Count
        $sum3[1].Text = [string]$cheatMods.Count
        $sum4[1].Text = [string]$totalMods

        $scanResults.Verified = $verifiedMods
        $scanResults.Unknown = $unknownMods
        $scanResults.Suspicious = $cheatMods
        $scanResults.Total = $totalMods
        $scanResults.Path = $mods

        $statusLabel.Text = "Scan complete."
        $progressBar.Value = 100
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $($_.Exception.Message)", "TESLAPRO", "OK", "Error") | Out-Null
        $statusLabel.Text = "Error during scan."
    }
    finally {
        $scanButton.Enabled = $true
        $browseButton.Enabled = $true
        $exportButton.Enabled = $true
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
})

[void]$form.ShowDialog()