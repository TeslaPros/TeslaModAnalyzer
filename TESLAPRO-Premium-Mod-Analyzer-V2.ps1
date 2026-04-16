Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

[System.Windows.Forms.Application]::EnableVisualStyles()

# =========================
# Core helpers
# =========================

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

# =========================
# Theme
# =========================

$script:IsDarkTheme = $true

function Get-Theme {
    if ($script:IsDarkTheme) {
        return @{
            FormBack      = [System.Drawing.Color]::FromArgb(12,15,22)
            SidebarBack   = [System.Drawing.Color]::FromArgb(16,22,34)
            HeaderBack    = [System.Drawing.Color]::FromArgb(16,22,34)
            CardBack      = [System.Drawing.Color]::FromArgb(22,26,38)
            PanelBack     = [System.Drawing.Color]::FromArgb(18,22,32)
            InputBack     = [System.Drawing.Color]::FromArgb(24,28,38)
            GridBack      = [System.Drawing.Color]::FromArgb(18,22,32)
            GridHeader    = [System.Drawing.Color]::FromArgb(30,36,48)
            GridLine      = [System.Drawing.Color]::FromArgb(52,56,68)
            Fore          = [System.Drawing.Color]::White
            Muted         = [System.Drawing.Color]::Silver
            Accent        = [System.Drawing.Color]::FromArgb(80,190,255)
            Green         = [System.Drawing.Color]::FromArgb(60,220,120)
            Yellow        = [System.Drawing.Color]::FromArgb(255,200,70)
            Red           = [System.Drawing.Color]::FromArgb(255,90,90)
            BtnNeutral    = [System.Drawing.Color]::FromArgb(35,40,54)
            BtnPrimary    = [System.Drawing.Color]::FromArgb(0,120,215)
            BtnDanger     = [System.Drawing.Color]::FromArgb(75,45,45)
        }
    } else {
        return @{
            FormBack      = [System.Drawing.Color]::FromArgb(242,245,250)
            SidebarBack   = [System.Drawing.Color]::FromArgb(225,232,242)
            HeaderBack    = [System.Drawing.Color]::FromArgb(230,236,244)
            CardBack      = [System.Drawing.Color]::White
            PanelBack     = [System.Drawing.Color]::White
            InputBack     = [System.Drawing.Color]::FromArgb(250,250,252)
            GridBack      = [System.Drawing.Color]::White
            GridHeader    = [System.Drawing.Color]::FromArgb(235,240,246)
            GridLine      = [System.Drawing.Color]::FromArgb(210,215,225)
            Fore          = [System.Drawing.Color]::FromArgb(25,30,40)
            Muted         = [System.Drawing.Color]::FromArgb(90,95,105)
            Accent        = [System.Drawing.Color]::FromArgb(0,102,204)
            Green         = [System.Drawing.Color]::FromArgb(30,170,80)
            Yellow        = [System.Drawing.Color]::FromArgb(215,150,20)
            Red           = [System.Drawing.Color]::FromArgb(210,60,60)
            BtnNeutral    = [System.Drawing.Color]::FromArgb(225,230,238)
            BtnPrimary    = [System.Drawing.Color]::FromArgb(0,120,215)
            BtnDanger     = [System.Drawing.Color]::FromArgb(225,200,200)
        }
    }
}

# =========================
# UI builders
# =========================

function New-Panel {
    param($X,$Y,$W,$H,$BackColor)
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point($X,$Y)
    $p.Size = New-Object System.Drawing.Size($W,$H)
    $p.BackColor = $BackColor
    return $p
}

function New-Card {
    param(
        [string]$Title,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [System.Drawing.Color]$Accent
    )

    $theme = Get-Theme

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($X,$Y)
    $panel.Size = New-Object System.Drawing.Size($W,$H)
    $panel.BackColor = $theme.CardBack
    $panel.BorderStyle = 'FixedSingle'

    $bar = New-Object System.Windows.Forms.Panel
    $bar.Location = New-Object System.Drawing.Point(0,0)
    $bar.Size = New-Object System.Drawing.Size(6,$H)
    $bar.BackColor = $Accent

    $title = New-Object System.Windows.Forms.Label
    $title.Text = $Title
    $title.Location = New-Object System.Drawing.Point(18,14)
    $title.Size = New-Object System.Drawing.Size(($W-30),22)
    $title.ForeColor = $theme.Muted
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $value = New-Object System.Windows.Forms.Label
    $value.Text = "0"
    $value.Location = New-Object System.Drawing.Point(18,40)
    $value.Size = New-Object System.Drawing.Size(($W-30),34)
    $value.ForeColor = $Accent
    $value.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 18, [System.Drawing.FontStyle]::Bold)

    $panel.Controls.AddRange(@($bar,$title,$value))
    return @($panel,$value,$bar,$title)
}

function New-Grid {
    param([string]$Name,[int]$X,[int]$Y,[int]$W,[int]$H)

    $theme = Get-Theme

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Name = $Name
    $grid.Location = New-Object System.Drawing.Point($X,$Y)
    $grid.Size = New-Object System.Drawing.Size($W,$H)
    $grid.BackgroundColor = $theme.GridBack
    $grid.BorderStyle = 'FixedSingle'
    $grid.GridColor = $theme.GridLine
    $grid.EnableHeadersVisualStyles = $false
    $grid.ColumnHeadersDefaultCellStyle.BackColor = $theme.GridHeader
    $grid.ColumnHeadersDefaultCellStyle.ForeColor = $theme.Fore
    $grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $grid.DefaultCellStyle.BackColor = $theme.GridBack
    $grid.DefaultCellStyle.ForeColor = $theme.Fore
    $grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0,120,215)
    $grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $grid.RowHeadersVisible = $false
    $grid.AutoSizeColumnsMode = 'Fill'
    $grid.SelectionMode = 'FullRowSelect'
    $grid.MultiSelect = $false
    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    $grid.AllowUserToDeleteRows = $false
    $grid.AllowUserToResizeRows = $false
    $grid.AllowUserToResizeColumns = $true
    return $grid
}

function Set-DoubleBuffered {
    param([object]$Control)
    try {
        $type = $Control.GetType()
        $prop = $type.GetProperty("DoubleBuffered",[System.Reflection.BindingFlags] "Instance,NonPublic")
        if ($prop) {
            $prop.SetValue($Control,$true,$null)
        }
    } catch {}
}

# =========================
# Form
# =========================

$form = New-Object System.Windows.Forms.Form
$form.Text = "TESLAPRO Premium Mod Analyzer V2"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1560, 980)
$form.MinimumSize = New-Object System.Drawing.Size(1420, 900)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$theme = Get-Theme
$form.BackColor = $theme.FormBack
$form.ForeColor = $theme.Fore

$sidebar = New-Panel 0 0 220 980 $theme.SidebarBack
$sidebar.Anchor = 'Top,Bottom,Left'

$logo = New-Object System.Windows.Forms.Label
$logo.Text = "TESLAPRO"
$logo.Location = New-Object System.Drawing.Point(24,24)
$logo.Size = New-Object System.Drawing.Size(180,34)
$logo.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 22, [System.Drawing.FontStyle]::Bold)
$logo.ForeColor = $theme.Accent

$logoSub = New-Object System.Windows.Forms.Label
$logoSub.Text = "Premium Analyzer V2"
$logoSub.Location = New-Object System.Drawing.Point(26,60)
$logoSub.Size = New-Object System.Drawing.Size(170,20)
$logoSub.ForeColor = $theme.Muted

function New-SideButton {
    param([string]$Text,[int]$Y)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Location = New-Object System.Drawing.Point(18,$Y)
    $b.Size = New-Object System.Drawing.Size(184,42)
    $b.FlatStyle = 'Flat'
    $b.BackColor = $theme.BtnNeutral
    $b.ForeColor = $theme.Fore
    $b.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    return $b
}

$btnDashboard = New-SideButton "Dashboard" 120
$btnScan      = New-SideButton "Scan Center" 168
$btnResults   = New-SideButton "Results Center" 216
$btnHistory   = New-SideButton "Scan History" 264
$btnSettings  = New-SideButton "Settings" 312

$sidebarFooter = New-Object System.Windows.Forms.Label
$sidebarFooter.Text = "Discord = @teamwsf"
$sidebarFooter.Location = New-Object System.Drawing.Point(24,900)
$sidebarFooter.Size = New-Object System.Drawing.Size(160,20)
$sidebarFooter.ForeColor = $theme.Muted
$sidebarFooter.Anchor = 'Bottom,Left'

$sidebar.Controls.AddRange(@(
    $logo,$logoSub,$btnDashboard,$btnScan,$btnResults,$btnHistory,$btnSettings,$sidebarFooter
))

$mainHost = New-Panel 220 0 1340 980 $theme.FormBack
$mainHost.Anchor = 'Top,Bottom,Left,Right'

# =========================
# Pages
# =========================

$pageDashboard = New-Panel 0 0 1340 980 $theme.FormBack
$pageDashboard.Anchor = 'Top,Bottom,Left,Right'

$pageScan = New-Panel 0 0 1340 980 $theme.FormBack
$pageScan.Anchor = 'Top,Bottom,Left,Right'
$pageScan.Visible = $false

$pageResults = New-Panel 0 0 1340 980 $theme.FormBack
$pageResults.Anchor = 'Top,Bottom,Left,Right'
$pageResults.Visible = $false

$pageHistory = New-Panel 0 0 1340 980 $theme.FormBack
$pageHistory.Anchor = 'Top,Bottom,Left,Right'
$pageHistory.Visible = $false

$pageSettings = New-Panel 0 0 1340 980 $theme.FormBack
$pageSettings.Anchor = 'Top,Bottom,Left,Right'
$pageSettings.Visible = $false

$mainHost.Controls.AddRange(@($pageDashboard,$pageScan,$pageResults,$pageHistory,$pageSettings))

# =========================
# Shared state
# =========================

$allVerified = @()
$allUnknown = @()
$allSuspicious = @()
$scanPath = ""
$totalFiles = 0
$scanHistory = New-Object System.Collections.Generic.List[object]

# =========================
# Dashboard
# =========================

$dashHeader = New-Panel 20 18 1285 92 $theme.HeaderBack
$dashHeader.Anchor = 'Top,Left,Right'
$dashHeader.BorderStyle = 'FixedSingle'

$dashTitle = New-Object System.Windows.Forms.Label
$dashTitle.Text = "Dashboard"
$dashTitle.Location = New-Object System.Drawing.Point(22,16)
$dashTitle.Size = New-Object System.Drawing.Size(320,34)
$dashTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 24, [System.Drawing.FontStyle]::Bold)
$dashTitle.ForeColor = $theme.Accent

$dashSub = New-Object System.Windows.Forms.Label
$dashSub.Text = "Overview of your latest TESLAPRO scan activity"
$dashSub.Location = New-Object System.Drawing.Point(24,54)
$dashSub.Size = New-Object System.Drawing.Size(500,20)
$dashSub.ForeColor = $theme.Muted

$dashHeader.Controls.AddRange(@($dashTitle,$dashSub))

$dCard1 = New-Card "Verified Mods" 20 130 300 92 $theme.Green
$dCard2 = New-Card "Unknown Mods" 340 130 300 92 $theme.Yellow
$dCard3 = New-Card "Suspicious Mods" 660 130 300 92 $theme.Red
$dCard4 = New-Card "Scanned Files" 980 130 325 92 $theme.Accent

$dashQuickPanel = New-Panel 20 244 620 300 $theme.PanelBack
$dashQuickPanel.BorderStyle = 'FixedSingle'

$quickTitle = New-Object System.Windows.Forms.Label
$quickTitle.Text = "Quick Actions"
$quickTitle.Location = New-Object System.Drawing.Point(18,16)
$quickTitle.Size = New-Object System.Drawing.Size(220,24)
$quickTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
$quickTitle.ForeColor = $theme.Fore

$dashStartScan = New-Object System.Windows.Forms.Button
$dashStartScan.Text = "Start New Scan"
$dashStartScan.Location = New-Object System.Drawing.Point(22,60)
$dashStartScan.Size = New-Object System.Drawing.Size(170,42)
$dashStartScan.FlatStyle = 'Flat'
$dashStartScan.BackColor = $theme.BtnPrimary
$dashStartScan.ForeColor = [System.Drawing.Color]::White

$dashGoResults = New-Object System.Windows.Forms.Button
$dashGoResults.Text = "Open Results Center"
$dashGoResults.Location = New-Object System.Drawing.Point(208,60)
$dashGoResults.Size = New-Object System.Drawing.Size(180,42)
$dashGoResults.FlatStyle = 'Flat'
$dashGoResults.BackColor = $theme.BtnNeutral
$dashGoResults.ForeColor = $theme.Fore

$dashExport = New-Object System.Windows.Forms.Button
$dashExport.Text = "Export Latest Results"
$dashExport.Location = New-Object System.Drawing.Point(404,60)
$dashExport.Size = New-Object System.Drawing.Size(190,42)
$dashExport.FlatStyle = 'Flat'
$dashExport.BackColor = $theme.BtnNeutral
$dashExport.ForeColor = $theme.Fore

$dashInfo = New-Object System.Windows.Forms.Label
$dashInfo.Text = "Use the dashboard for a quick overview, then switch to Scan Center or Results Center for more control."
$dashInfo.Location = New-Object System.Drawing.Point(22,124)
$dashInfo.Size = New-Object System.Drawing.Size(560,60)
$dashInfo.ForeColor = $theme.Muted

$dashLatestTitle = New-Object System.Windows.Forms.Label
$dashLatestTitle.Text = "Latest Scan Summary"
$dashLatestTitle.Location = New-Object System.Drawing.Point(22,200)
$dashLatestTitle.Size = New-Object System.Drawing.Size(220,24)
$dashLatestTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 12, [System.Drawing.FontStyle]::Bold)
$dashLatestTitle.ForeColor = $theme.Fore

$dashLatestBox = New-Object System.Windows.Forms.TextBox
$dashLatestBox.Location = New-Object System.Drawing.Point(22,232)
$dashLatestBox.Size = New-Object System.Drawing.Size(570,36)
$dashLatestBox.ReadOnly = $true
$dashLatestBox.BackColor = $theme.InputBack
$dashLatestBox.ForeColor = $theme.Fore
$dashLatestBox.BorderStyle = 'FixedSingle'

$dashQuickPanel.Controls.AddRange(@(
    $quickTitle,$dashStartScan,$dashGoResults,$dashExport,$dashInfo,$dashLatestTitle,$dashLatestBox
))

$dashHistoryPanel = New-Panel 660 244 645 300 $theme.PanelBack
$dashHistoryPanel.BorderStyle = 'FixedSingle'

$dashHistoryTitle = New-Object System.Windows.Forms.Label
$dashHistoryTitle.Text = "Recent History"
$dashHistoryTitle.Location = New-Object System.Drawing.Point(18,16)
$dashHistoryTitle.Size = New-Object System.Drawing.Size(200,24)
$dashHistoryTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
$dashHistoryTitle.ForeColor = $theme.Fore

$dashHistoryList = New-Object System.Windows.Forms.ListBox
$dashHistoryList.Location = New-Object System.Drawing.Point(18,52)
$dashHistoryList.Size = New-Object System.Drawing.Size(605,226)
$dashHistoryList.BackColor = $theme.InputBack
$dashHistoryList.ForeColor = $theme.Fore
$dashHistoryList.BorderStyle = 'FixedSingle'

$dashHistoryPanel.Controls.AddRange(@($dashHistoryTitle,$dashHistoryList))

$pageDashboard.Controls.AddRange(@(
    $dashHeader,
    $dCard1[0],$dCard2[0],$dCard3[0],$dCard4[0],
    $dashQuickPanel,$dashHistoryPanel
))

# =========================
# Scan Center
# =========================

$scanHeader = New-Panel 20 18 1285 92 $theme.HeaderBack
$scanHeader.Anchor = 'Top,Left,Right'
$scanHeader.BorderStyle = 'FixedSingle'

$scanTitle = New-Object System.Windows.Forms.Label
$scanTitle.Text = "Scan Center"
$scanTitle.Location = New-Object System.Drawing.Point(22,16)
$scanTitle.Size = New-Object System.Drawing.Size(320,34)
$scanTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 24, [System.Drawing.FontStyle]::Bold)
$scanTitle.ForeColor = $theme.Accent

$scanSub = New-Object System.Windows.Forms.Label
$scanSub.Text = "Choose a mods folder, configure preferences and start a scan"
$scanSub.Location = New-Object System.Drawing.Point(24,54)
$scanSub.Size = New-Object System.Drawing.Size(560,20)
$scanSub.ForeColor = $theme.Muted

$scanHeader.Controls.AddRange(@($scanTitle,$scanSub))

$scanTopPanel = New-Panel 20 128 1285 110 $theme.PanelBack
$scanTopPanel.Anchor = 'Top,Left,Right'
$scanTopPanel.BorderStyle = 'FixedSingle'

$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Text = "Mods folder"
$pathLabel.Location = New-Object System.Drawing.Point(18,14)
$pathLabel.Size = New-Object System.Drawing.Size(120,20)
$pathLabel.ForeColor = $theme.Muted

$pathBox = New-Object System.Windows.Forms.TextBox
$pathBox.Location = New-Object System.Drawing.Point(18,42)
$pathBox.Size = New-Object System.Drawing.Size(860,30)
$pathBox.BackColor = $theme.InputBack
$pathBox.ForeColor = $theme.Fore
$pathBox.BorderStyle = 'FixedSingle'
$pathBox.Text = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(892,40)
$browseButton.Size = New-Object System.Drawing.Size(100,34)
$browseButton.FlatStyle = 'Flat'
$browseButton.BackColor = $theme.BtnNeutral
$browseButton.ForeColor = $theme.Fore

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = "Start Scan"
$scanButton.Location = New-Object System.Drawing.Point(1004,40)
$scanButton.Size = New-Object System.Drawing.Size(120,34)
$scanButton.FlatStyle = 'Flat'
$scanButton.BackColor = $theme.BtnPrimary
$scanButton.ForeColor = [System.Drawing.Color]::White

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear"
$clearButton.Location = New-Object System.Drawing.Point(1138,40)
$clearButton.Size = New-Object System.Drawing.Size(65,34)
$clearButton.FlatStyle = 'Flat'
$clearButton.BackColor = $theme.BtnDanger
$clearButton.ForeColor = $theme.Fore

$rescanButton = New-Object System.Windows.Forms.Button
$rescanButton.Text = "Rescan"
$rescanButton.Location = New-Object System.Drawing.Point(1215,40)
$rescanButton.Size = New-Object System.Drawing.Size(55,34)
$rescanButton.FlatStyle = 'Flat'
$rescanButton.BackColor = $theme.BtnNeutral
$rescanButton.ForeColor = $theme.Fore

$scanTopPanel.Controls.AddRange(@($pathLabel,$pathBox,$browseButton,$scanButton,$clearButton,$rescanButton))

$scanOptionsPanel = New-Panel 20 255 1285 170 $theme.PanelBack
$scanOptionsPanel.Anchor = 'Top,Left,Right'
$scanOptionsPanel.BorderStyle = 'FixedSingle'

$optTitle = New-Object System.Windows.Forms.Label
$optTitle.Text = "Scan Options"
$optTitle.Location = New-Object System.Drawing.Point(18,14)
$optTitle.Size = New-Object System.Drawing.Size(160,24)
$optTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
$optTitle.ForeColor = $theme.Fore

$chkDeepScan = New-Object System.Windows.Forms.CheckBox
$chkDeepScan.Text = "Enable deep scan for embedded jars"
$chkDeepScan.Location = New-Object System.Drawing.Point(22,52)
$chkDeepScan.Size = New-Object System.Drawing.Size(300,24)
$chkDeepScan.Checked = $true
$chkDeepScan.ForeColor = $theme.Fore
$chkDeepScan.BackColor = [System.Drawing.Color]::Transparent

$chkUseModrinth = New-Object System.Windows.Forms.CheckBox
$chkUseModrinth.Text = "Use Modrinth verification"
$chkUseModrinth.Location = New-Object System.Drawing.Point(22,84)
$chkUseModrinth.Size = New-Object System.Drawing.Size(240,24)
$chkUseModrinth.Checked = $true
$chkUseModrinth.ForeColor = $theme.Fore
$chkUseModrinth.BackColor = [System.Drawing.Color]::Transparent

$chkUseMegabase = New-Object System.Windows.Forms.CheckBox
$chkUseMegabase.Text = "Use Megabase verification"
$chkUseMegabase.Location = New-Object System.Drawing.Point(22,116)
$chkUseMegabase.Size = New-Object System.Drawing.Size(240,24)
$chkUseMegabase.Checked = $true
$chkUseMegabase.ForeColor = $theme.Fore
$chkUseMegabase.BackColor = [System.Drawing.Color]::Transparent

$chkShowPopups = New-Object System.Windows.Forms.CheckBox
$chkShowPopups.Text = "Show result popup after scan"
$chkShowPopups.Location = New-Object System.Drawing.Point(340,52)
$chkShowPopups.Size = New-Object System.Drawing.Size(240,24)
$chkShowPopups.Checked = $true
$chkShowPopups.ForeColor = $theme.Fore
$chkShowPopups.BackColor = [System.Drawing.Color]::Transparent

$chkAutoOpenResults = New-Object System.Windows.Forms.CheckBox
$chkAutoOpenResults.Text = "Automatically open Results Center"
$chkAutoOpenResults.Location = New-Object System.Drawing.Point(340,84)
$chkAutoOpenResults.Size = New-Object System.Drawing.Size(280,24)
$chkAutoOpenResults.Checked = $true
$chkAutoOpenResults.ForeColor = $theme.Fore
$chkAutoOpenResults.BackColor = [System.Drawing.Color]::Transparent

$chkSaveHistory = New-Object System.Windows.Forms.CheckBox
$chkSaveHistory.Text = "Save scans in history"
$chkSaveHistory.Location = New-Object System.Drawing.Point(340,116)
$chkSaveHistory.Size = New-Object System.Drawing.Size(180,24)
$chkSaveHistory.Checked = $true
$chkSaveHistory.ForeColor = $theme.Fore
$chkSaveHistory.BackColor = [System.Drawing.Color]::Transparent

$scanHint = New-Object System.Windows.Forms.Label
$scanHint.Text = "Tip: if your CMD command runs this remotely, keep the script name in GitHub exactly the same as your raw URL."
$scanHint.Location = New-Object System.Drawing.Point(700,64)
$scanHint.Size = New-Object System.Drawing.Size(540,60)
$scanHint.ForeColor = $theme.Muted

$scanOptionsPanel.Controls.AddRange(@(
    $optTitle,$chkDeepScan,$chkUseModrinth,$chkUseMegabase,
    $chkShowPopups,$chkAutoOpenResults,$chkSaveHistory,$scanHint
))

$scanProgressPanel = New-Panel 20 442 1285 120 $theme.PanelBack
$scanProgressPanel.BorderStyle = 'FixedSingle'
$scanProgressPanel.Anchor = 'Top,Left,Right'

$scanProgressTitle = New-Object System.Windows.Forms.Label
$scanProgressTitle.Text = "Scan Status"
$scanProgressTitle.Location = New-Object System.Drawing.Point(18,14)
$scanProgressTitle.Size = New-Object System.Drawing.Size(160,24)
$scanProgressTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
$scanProgressTitle.ForeColor = $theme.Fore

$scanStatusText = New-Object System.Windows.Forms.TextBox
$scanStatusText.Location = New-Object System.Drawing.Point(22,48)
$scanStatusText.Size = New-Object System.Drawing.Size(1240,30)
$scanStatusText.ReadOnly = $true
$scanStatusText.BackColor = $theme.InputBack
$scanStatusText.ForeColor = $theme.Fore
$scanStatusText.BorderStyle = 'FixedSingle'
$scanStatusText.Text = "Ready."

$scanProgressBar = New-Object System.Windows.Forms.ProgressBar
$scanProgressBar.Location = New-Object System.Drawing.Point(22,84)
$scanProgressBar.Size = New-Object System.Drawing.Size(1240,20)
$scanProgressBar.Minimum = 0
$scanProgressBar.Maximum = 100
$scanProgressBar.Value = 0

$scanProgressPanel.Controls.AddRange(@($scanProgressTitle,$scanStatusText,$scanProgressBar))

$pageScan.Controls.AddRange(@($scanHeader,$scanTopPanel,$scanOptionsPanel,$scanProgressPanel))

# =========================
# Results Center
# =========================

$resHeader = New-Panel 20 18 1285 92 $theme.HeaderBack
$resHeader.Anchor = 'Top,Left,Right'
$resHeader.BorderStyle = 'FixedSingle'

$resTitle = New-Object System.Windows.Forms.Label
$resTitle.Text = "Results Center"
$resTitle.Location = New-Object System.Drawing.Point(22,16)
$resTitle.Size = New-Object System.Drawing.Size(320,34)
$resTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 24, [System.Drawing.FontStyle]::Bold)
$resTitle.ForeColor = $theme.Accent

$resSub = New-Object System.Windows.Forms.Label
$resSub.Text = "Search, filter, export and inspect scan results"
$resSub.Location = New-Object System.Drawing.Point(24,54)
$resSub.Size = New-Object System.Drawing.Size(460,20)
$resSub.ForeColor = $theme.Muted

$resHeader.Controls.AddRange(@($resTitle,$resSub))

$resFiltersPanel = New-Panel 20 128 1285 76 $theme.PanelBack
$resFiltersPanel.Anchor = 'Top,Left,Right'
$resFiltersPanel.BorderStyle = 'FixedSingle'

$searchLabel = New-Object System.Windows.Forms.Label
$searchLabel.Text = "Search"
$searchLabel.Location = New-Object System.Drawing.Point(18,16)
$searchLabel.Size = New-Object System.Drawing.Size(55,20)
$searchLabel.ForeColor = $theme.Muted

$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Location = New-Object System.Drawing.Point(74,14)
$searchBox.Size = New-Object System.Drawing.Size(280,30)
$searchBox.BackColor = $theme.InputBack
$searchBox.ForeColor = $theme.Fore
$searchBox.BorderStyle = 'FixedSingle'

$filterLabel = New-Object System.Windows.Forms.Label
$filterLabel.Text = "Category"
$filterLabel.Location = New-Object System.Drawing.Point(370,16)
$filterLabel.Size = New-Object System.Drawing.Size(65,20)
$filterLabel.ForeColor = $theme.Muted

$filterCombo = New-Object System.Windows.Forms.ComboBox
$filterCombo.Location = New-Object System.Drawing.Point(438,14)
$filterCombo.Size = New-Object System.Drawing.Size(150,30)
$filterCombo.DropDownStyle = 'DropDownList'
[void]$filterCombo.Items.AddRange(@("All","Verified","Unknown","Suspicious"))
$filterCombo.SelectedIndex = 0

$sortLabel = New-Object System.Windows.Forms.Label
$sortLabel.Text = "Sort"
$sortLabel.Location = New-Object System.Drawing.Point(604,16)
$sortLabel.Size = New-Object System.Drawing.Size(40,20)
$sortLabel.ForeColor = $theme.Muted

$sortCombo = New-Object System.Windows.Forms.ComboBox
$sortCombo.Location = New-Object System.Drawing.Point(646,14)
$sortCombo.Size = New-Object System.Drawing.Size(180,30)
$sortCombo.DropDownStyle = 'DropDownList'
[void]$sortCombo.Items.AddRange(@("File Name (A-Z)","File Name (Z-A)","Source","Matches Count"))
$sortCombo.SelectedIndex = 0

$showOnlyDownloaded = New-Object System.Windows.Forms.CheckBox
$showOnlyDownloaded.Text = "Only downloaded-source unknown mods"
$showOnlyDownloaded.Location = New-Object System.Drawing.Point(850,16)
$showOnlyDownloaded.Size = New-Object System.Drawing.Size(280,24)
$showOnlyDownloaded.ForeColor = $theme.Fore
$showOnlyDownloaded.BackColor = [System.Drawing.Color]::Transparent

$resFiltersPanel.Controls.AddRange(@(
    $searchLabel,$searchBox,$filterLabel,$filterCombo,$sortLabel,$sortCombo,$showOnlyDownloaded
))

$rCard1 = New-Card "Verified Mods" 20 220 300 88 $theme.Green
$rCard2 = New-Card "Unknown Mods" 340 220 300 88 $theme.Yellow
$rCard3 = New-Card "Suspicious Mods" 660 220 300 88 $theme.Red
$rCard4 = New-Card "Scanned Files" 980 220 325 88 $theme.Accent

$resultsTabs = New-Object System.Windows.Forms.TabControl
$resultsTabs.Location = New-Object System.Drawing.Point(20,325)
$resultsTabs.Size = New-Object System.Drawing.Size(1285,420)
$resultsTabs.Anchor = 'Top,Bottom,Left,Right'
$resultsTabs.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$tabVerified = New-Object System.Windows.Forms.TabPage
$tabVerified.Text = "Verified"
$tabVerified.BackColor = $theme.FormBack

$tabUnknown = New-Object System.Windows.Forms.TabPage
$tabUnknown.Text = "Unknown"
$tabUnknown.BackColor = $theme.FormBack

$tabSuspicious = New-Object System.Windows.Forms.TabPage
$tabSuspicious.Text = "Suspicious"
$tabSuspicious.BackColor = $theme.FormBack

$gridVerified = New-Grid "gridVerified" 10 10 1248 372
$gridUnknown = New-Grid "gridUnknown" 10 10 1248 372
$gridSuspicious = New-Grid "gridSuspicious" 10 10 1248 372

Set-DoubleBuffered $gridVerified
Set-DoubleBuffered $gridUnknown
Set-DoubleBuffered $gridSuspicious

$tabVerified.Controls.Add($gridVerified)
$tabUnknown.Controls.Add($gridUnknown)
$tabSuspicious.Controls.Add($gridSuspicious)
$resultsTabs.TabPages.AddRange(@($tabVerified,$tabUnknown,$tabSuspicious))

$resDetailsPanel = New-Panel 20 760 1285 110 $theme.PanelBack
$resDetailsPanel.Anchor = 'Bottom,Left,Right'
$resDetailsPanel.BorderStyle = 'FixedSingle'

$detailsTitle = New-Object System.Windows.Forms.Label
$detailsTitle.Text = "Details"
$detailsTitle.Location = New-Object System.Drawing.Point(16,10)
$detailsTitle.Size = New-Object System.Drawing.Size(90,20)
$detailsTitle.ForeColor = $theme.Muted
$detailsTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10, [System.Drawing.FontStyle]::Bold)

$detailsBox = New-Object System.Windows.Forms.TextBox
$detailsBox.Location = New-Object System.Drawing.Point(16,34)
$detailsBox.Size = New-Object System.Drawing.Size(930,30)
$detailsBox.ReadOnly = $true
$detailsBox.BackColor = $theme.InputBack
$detailsBox.ForeColor = $theme.Fore
$detailsBox.BorderStyle = 'FixedSingle'

$openLocationButton = New-Object System.Windows.Forms.Button
$openLocationButton.Text = "Open File Location"
$openLocationButton.Location = New-Object System.Drawing.Point(965,32)
$openLocationButton.Size = New-Object System.Drawing.Size(140,34)
$openLocationButton.FlatStyle = 'Flat'
$openLocationButton.BackColor = $theme.BtnNeutral
$openLocationButton.ForeColor = $theme.Fore

$copyMatchesButton = New-Object System.Windows.Forms.Button
$copyMatchesButton.Text = "Copy Suspicious Matches"
$copyMatchesButton.Location = New-Object System.Drawing.Point(1118,32)
$copyMatchesButton.Size = New-Object System.Drawing.Size(150,34)
$copyMatchesButton.FlatStyle = 'Flat'
$copyMatchesButton.BackColor = $theme.BtnNeutral
$copyMatchesButton.ForeColor = $theme.Fore

$resDetailsPanel.Controls.AddRange(@(
    $detailsTitle,$detailsBox,$openLocationButton,$copyMatchesButton
))

$pageResults.Controls.AddRange(@(
    $resHeader,$resFiltersPanel,
    $rCard1[0],$rCard2[0],$rCard3[0],$rCard4[0],
    $resultsTabs,$resDetailsPanel
))

# =========================
# History
# =========================

$histHeader = New-Panel 20 18 1285 92 $theme.HeaderBack
$histHeader.BorderStyle = 'FixedSingle'
$histHeader.Anchor = 'Top,Left,Right'

$histTitle = New-Object System.Windows.Forms.Label
$histTitle.Text = "Scan History"
$histTitle.Location = New-Object System.Drawing.Point(22,16)
$histTitle.Size = New-Object System.Drawing.Size(320,34)
$histTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 24, [System.Drawing.FontStyle]::Bold)
$histTitle.ForeColor = $theme.Accent

$histSub = New-Object System.Windows.Forms.Label
$histSub.Text = "Recent scans saved by TESLAPRO"
$histSub.Location = New-Object System.Drawing.Point(24,54)
$histSub.Size = New-Object System.Drawing.Size(400,20)
$histSub.ForeColor = $theme.Muted

$histHeader.Controls.AddRange(@($histTitle,$histSub))

$historyPanel = New-Panel 20 128 1285 742 $theme.PanelBack
$historyPanel.BorderStyle = 'FixedSingle'
$historyPanel.Anchor = 'Top,Bottom,Left,Right'

$historyTitle = New-Object System.Windows.Forms.Label
$historyTitle.Text = "Saved scans"
$historyTitle.Location = New-Object System.Drawing.Point(18,14)
$historyTitle.Size = New-Object System.Drawing.Size(220,24)
$historyTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
$historyTitle.ForeColor = $theme.Fore

$historyList = New-Object System.Windows.Forms.ListBox
$historyList.Location = New-Object System.Drawing.Point(18,48)
$historyList.Size = New-Object System.Drawing.Size(1248,670)
$historyList.BackColor = $theme.InputBack
$historyList.ForeColor = $theme.Fore
$historyList.BorderStyle = 'FixedSingle'
$historyList.Anchor = 'Top,Bottom,Left,Right'

$historyPanel.Controls.AddRange(@($historyTitle,$historyList))
$pageHistory.Controls.AddRange(@($histHeader,$historyPanel))

# =========================
# Settings
# =========================

$setHeader = New-Panel 20 18 1285 92 $theme.HeaderBack
$setHeader.BorderStyle = 'FixedSingle'
$setHeader.Anchor = 'Top,Left,Right'

$setTitle = New-Object System.Windows.Forms.Label
$setTitle.Text = "Settings"
$setTitle.Location = New-Object System.Drawing.Point(22,16)
$setTitle.Size = New-Object System.Drawing.Size(320,34)
$setTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 24, [System.Drawing.FontStyle]::Bold)
$setTitle.ForeColor = $theme.Accent

$setSub = New-Object System.Windows.Forms.Label
$setSub.Text = "Appearance and startup behavior"
$setSub.Location = New-Object System.Drawing.Point(24,54)
$setSub.Size = New-Object System.Drawing.Size(400,20)
$setSub.ForeColor = $theme.Muted

$setHeader.Controls.AddRange(@($setTitle,$setSub))

$settingsPanel = New-Panel 20 128 1285 420 $theme.PanelBack
$settingsPanel.BorderStyle = 'FixedSingle'

$settingsTitle = New-Object System.Windows.Forms.Label
$settingsTitle.Text = "General Settings"
$settingsTitle.Location = New-Object System.Drawing.Point(18,14)
$settingsTitle.Size = New-Object System.Drawing.Size(220,24)
$settingsTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
$settingsTitle.ForeColor = $theme.Fore

$chkDarkTheme = New-Object System.Windows.Forms.CheckBox
$chkDarkTheme.Text = "Use dark theme"
$chkDarkTheme.Location = New-Object System.Drawing.Point(22,56)
$chkDarkTheme.Size = New-Object System.Drawing.Size(180,24)
$chkDarkTheme.Checked = $true
$chkDarkTheme.ForeColor = $theme.Fore
$chkDarkTheme.BackColor = [System.Drawing.Color]::Transparent

$chkAutoScan = New-Object System.Windows.Forms.CheckBox
$chkAutoScan.Text = "Auto scan on startup"
$chkAutoScan.Location = New-Object System.Drawing.Point(22,88)
$chkAutoScan.Size = New-Object System.Drawing.Size(200,24)
$chkAutoScan.Checked = $false
$chkAutoScan.ForeColor = $theme.Fore
$chkAutoScan.BackColor = [System.Drawing.Color]::Transparent

$chkOpenResultsAfterScan = New-Object System.Windows.Forms.CheckBox
$chkOpenResultsAfterScan.Text = "Open Results Center after scan"
$chkOpenResultsAfterScan.Location = New-Object System.Drawing.Point(22,120)
$chkOpenResultsAfterScan.Size = New-Object System.Drawing.Size(250,24)
$chkOpenResultsAfterScan.Checked = $true
$chkOpenResultsAfterScan.ForeColor = $theme.Fore
$chkOpenResultsAfterScan.BackColor = [System.Drawing.Color]::Transparent

$chkRememberPath = New-Object System.Windows.Forms.CheckBox
$chkRememberPath.Text = "Remember selected path during session"
$chkRememberPath.Location = New-Object System.Drawing.Point(22,152)
$chkRememberPath.Size = New-Object System.Drawing.Size(300,24)
$chkRememberPath.Checked = $true
$chkRememberPath.ForeColor = $theme.Fore
$chkRememberPath.BackColor = [System.Drawing.Color]::Transparent

$settingsNote = New-Object System.Windows.Forms.Label
$settingsNote.Text = "Theme changes apply immediately. Auto-scan uses the path currently shown in Scan Center."
$settingsNote.Location = New-Object System.Drawing.Point(22,196)
$settingsNote.Size = New-Object System.Drawing.Size(620,40)
$settingsNote.ForeColor = $theme.Muted

$settingsPanel.Controls.AddRange(@(
    $settingsTitle,$chkDarkTheme,$chkAutoScan,$chkOpenResultsAfterScan,$chkRememberPath,$settingsNote
))

$pageSettings.Controls.AddRange(@($setHeader,$settingsPanel))

# =========================
# Footer status
# =========================

$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.BackColor = $theme.HeaderBack

$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready."
$statusLabel.ForeColor = $theme.Fore
$statusLabel.Spring = $true

$progressBar = New-Object System.Windows.Forms.ToolStripProgressBar
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Size = New-Object System.Drawing.Size(220,18)

$exportMenu = New-Object System.Windows.Forms.ToolStripDropDownButton
$exportMenu.Text = "Export"
$exportMenu.ForeColor = $theme.Fore
[void]$exportMenu.DropDownItems.Add("Export TXT")
[void]$exportMenu.DropDownItems.Add("Export CSV")
[void]$exportMenu.DropDownItems.Add("Export JSON")

$statusBar.Items.Add($statusLabel) | Out-Null
$statusBar.Items.Add($progressBar) | Out-Null
$statusBar.Items.Add($exportMenu) | Out-Null

$form.Controls.AddRange(@($sidebar,$mainHost,$statusBar))

# =========================
# Dialogs
# =========================

$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Select the mods folder"

$saveDialog = New-Object System.Windows.Forms.SaveFileDialog

# =========================
# Utility functions
# =========================

function Show-Page {
    param([string]$PageName)

    $pageDashboard.Visible = $false
    $pageScan.Visible = $false
    $pageResults.Visible = $false
    $pageHistory.Visible = $false
    $pageSettings.Visible = $false

    switch ($PageName) {
        "Dashboard" { $pageDashboard.Visible = $true }
        "Scan"      { $pageScan.Visible = $true }
        "Results"   { $pageResults.Visible = $true }
        "History"   { $pageHistory.Visible = $true }
        "Settings"  { $pageSettings.Visible = $true }
    }
}

function Update-Cards {
    $dCard1[1].Text = [string]$allVerified.Count
    $dCard2[1].Text = [string]$allUnknown.Count
    $dCard3[1].Text = [string]$allSuspicious.Count
    $dCard4[1].Text = [string]$totalFiles

    $rCard1[1].Text = [string]$allVerified.Count
    $rCard2[1].Text = [string]$allUnknown.Count
    $rCard3[1].Text = [string]$allSuspicious.Count
    $rCard4[1].Text = [string]$totalFiles

    if ($scanPath) {
        $dashLatestBox.Text = "Path: $scanPath | Scanned: $totalFiles | Verified: $($allVerified.Count) | Unknown: $($allUnknown.Count) | Suspicious: $($allSuspicious.Count)"
    } else {
        $dashLatestBox.Text = ""
    }
}

function Build-TableVerified {
    param($items)
    $table = New-Object System.Data.DataTable
    [void]$table.Columns.Add("Mod Name")
    [void]$table.Columns.Add("File Name")
    [void]$table.Columns.Add("Source")
    foreach ($i in $items) {
        [void]$table.Rows.Add($i.ModName,$i.FileName,$i.Source)
    }
    return $table
}

function Build-TableUnknown {
    param($items)
    $table = New-Object System.Data.DataTable
    [void]$table.Columns.Add("File Name")
    [void]$table.Columns.Add("Downloaded From")
    foreach ($i in $items) {
        [void]$table.Rows.Add($i.FileName,$i.ZoneId)
    }
    return $table
}

function Build-TableSuspicious {
    param($items)
    $table = New-Object System.Data.DataTable
    [void]$table.Columns.Add("File Name")
    [void]$table.Columns.Add("Embedded Jar")
    [void]$table.Columns.Add("Matches")
    [void]$table.Columns.Add("Matches Count")
    foreach ($i in $items) {
        [void]$table.Rows.Add($i.FileName,$i.DepFileName,[string]::Join(", ",$i.StringsFound),$i.StringsFound.Count)
    }
    return $table
}

function Apply-FilterAndSort {
    $search = $searchBox.Text.Trim().ToLowerInvariant()
    $category = $filterCombo.SelectedItem
    $sort = $sortCombo.SelectedItem
    $onlyDownloaded = $showOnlyDownloaded.Checked

    $verified = @($allVerified)
    $unknown = @($allUnknown)
    $suspicious = @($allSuspicious)

    if ($search) {
        $verified = @($verified | Where-Object {
            ($_.ModName -and $_.ModName.ToLowerInvariant().Contains($search)) -or
            ($_.FileName -and $_.FileName.ToLowerInvariant().Contains($search)) -or
            ($_.Source -and $_.Source.ToLowerInvariant().Contains($search))
        })

        $unknown = @($unknown | Where-Object {
            ($_.FileName -and $_.FileName.ToLowerInvariant().Contains($search)) -or
            ($_.ZoneId -and $_.ZoneId.ToLowerInvariant().Contains($search))
        })

        $suspicious = @($suspicious | Where-Object {
            ($_.FileName -and $_.FileName.ToLowerInvariant().Contains($search)) -or
            ($_.DepFileName -and $_.DepFileName.ToLowerInvariant().Contains($search)) -or
            ([string]::Join(", ", $_.StringsFound).ToLowerInvariant().Contains($search))
        })
    }

    if ($onlyDownloaded) {
        $unknown = @($unknown | Where-Object { -not [string]::IsNullOrWhiteSpace($_.ZoneId) })
    }

    switch ($sort) {
        "File Name (A-Z)" {
            $verified = @($verified | Sort-Object FileName)
            $unknown = @($unknown | Sort-Object FileName)
            $suspicious = @($suspicious | Sort-Object FileName)
        }
        "File Name (Z-A)" {
            $verified = @($verified | Sort-Object FileName -Descending)
            $unknown = @($unknown | Sort-Object FileName -Descending)
            $suspicious = @($suspicious | Sort-Object FileName -Descending)
        }
        "Source" {
            $verified = @($verified | Sort-Object Source,FileName)
            $unknown = @($unknown | Sort-Object ZoneId,FileName)
            $suspicious = @($suspicious | Sort-Object DepFileName,FileName)
        }
        "Matches Count" {
            $suspicious = @($suspicious | Sort-Object @{Expression={$_.StringsFound.Count};Descending=$true},FileName)
        }
    }

    $gridVerified.DataSource = $null
    $gridUnknown.DataSource = $null
    $gridSuspicious.DataSource = $null

    $gridVerified.DataSource = (Build-TableVerified $verified)
    $gridUnknown.DataSource = (Build-TableUnknown $unknown)
    $gridSuspicious.DataSource = (Build-TableSuspicious $suspicious)

    if ($gridSuspicious.Columns["Matches Count"]) {
        $gridSuspicious.Columns["Matches Count"].Visible = $false
    }

    switch ($category) {
        "Verified"   { $resultsTabs.SelectedTab = $tabVerified }
        "Unknown"    { $resultsTabs.SelectedTab = $tabUnknown }
        "Suspicious" { $resultsTabs.SelectedTab = $tabSuspicious }
    }
}

function Clear-Results {
    $script:allVerified = @()
    $script:allUnknown = @()
    $script:allSuspicious = @()
    $script:totalFiles = 0
    if (-not $chkRememberPath.Checked) {
        $script:scanPath = ""
        $pathBox.Text = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    }

    $gridVerified.DataSource = $null
    $gridUnknown.DataSource = $null
    $gridSuspicious.DataSource = $null
    $detailsBox.Text = ""
    $progressBar.Value = 0
    $scanProgressBar.Value = 0
    $scanStatusText.Text = "Ready."
    $statusLabel.Text = "Cleared."
    Update-Cards
}

function Add-HistoryEntry {
    param(
        [string]$Path,
        [int]$Scanned,
        [int]$Verified,
        [int]$Unknown,
        [int]$Suspicious
    )

    $entry = [PSCustomObject]@{
        Timestamp  = Get-Date
        Path       = $Path
        Scanned    = $Scanned
        Verified   = $Verified
        Unknown    = $Unknown
        Suspicious = $Suspicious
    }

    $scanHistory.Insert(0,$entry)

    $line = "{0} | {1} | Files={2} | Verified={3} | Unknown={4} | Suspicious={5}" -f `
        $entry.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"),
        $entry.Path,
        $entry.Scanned,
        $entry.Verified,
        $entry.Unknown,
        $entry.Suspicious

    $historyList.Items.Insert(0,$line)
    $dashHistoryList.Items.Insert(0,$line)
}

function Export-Results {
    param([string]$Type)

    if (-not $scanPath) {
        [System.Windows.Forms.MessageBox]::Show("No scan results available yet.","TESLAPRO","OK","Information") | Out-Null
        return
    }

    switch ($Type) {
        "TXT"  { $saveDialog.Filter = "Text files (*.txt)|*.txt";  $saveDialog.FileName = "TESLAPRO-Scan-Results.txt" }
        "CSV"  { $saveDialog.Filter = "CSV files (*.csv)|*.csv";   $saveDialog.FileName = "TESLAPRO-Scan-Results.csv" }
        "JSON" { $saveDialog.Filter = "JSON files (*.json)|*.json"; $saveDialog.FileName = "TESLAPRO-Scan-Results.json" }
    }

    if ($saveDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        return
    }

    if ($Type -eq "TXT") {
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add("TESLAPRO PREMIUM MOD ANALYZER V2")
        $lines.Add("Path: $scanPath")
        $lines.Add("Scanned files: $totalFiles")
        $lines.Add("Verified: $($allVerified.Count)")
        $lines.Add("Unknown: $($allUnknown.Count)")
        $lines.Add("Suspicious: $($allSuspicious.Count)")
        $lines.Add("")
        $lines.Add("[ VERIFIED ]")
        foreach ($item in $allVerified) { $lines.Add("$($item.ModName) | $($item.FileName) | $($item.Source)") }
        $lines.Add("")
        $lines.Add("[ UNKNOWN ]")
        foreach ($item in $allUnknown) { $lines.Add("$($item.FileName) | $($item.ZoneId)") }
        $lines.Add("")
        $lines.Add("[ SUSPICIOUS ]")
        foreach ($item in $allSuspicious) {
            $lines.Add("$($item.FileName) | $($item.DepFileName) | $([string]::Join(', ', $item.StringsFound))")
        }
        [System.IO.File]::WriteAllLines($saveDialog.FileName, $lines)
    }
    elseif ($Type -eq "CSV") {
        $rows = @()
        foreach ($v in $allVerified) {
            $rows += [PSCustomObject]@{ Category="Verified"; FileName=$v.FileName; Name=$v.ModName; Source=$v.Source; Details="" }
        }
        foreach ($u in $allUnknown) {
            $rows += [PSCustomObject]@{ Category="Unknown"; FileName=$u.FileName; Name=""; Source=$u.ZoneId; Details="" }
        }
        foreach ($s in $allSuspicious) {
            $rows += [PSCustomObject]@{ Category="Suspicious"; FileName=$s.FileName; Name=$s.DepFileName; Source=""; Details=([string]::Join(", ", $s.StringsFound)) }
        }
        $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $saveDialog.FileName
    }
    else {
        $payload = [PSCustomObject]@{
            Path = $scanPath
            TotalFiles = $totalFiles
            Verified = $allVerified
            Unknown = $allUnknown
            Suspicious = $allSuspicious
        }
        $payload | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -Path $saveDialog.FileName
    }

    [System.Windows.Forms.MessageBox]::Show("Export completed.","TESLAPRO","OK","Information") | Out-Null
}

function Start-Scan {
    $mods = $pathBox.Text.Trim()

    if (-not (Test-Path $mods -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("Invalid mods folder path.","TESLAPRO","OK","Warning") | Out-Null
        return
    }

    $scanButton.Enabled = $false
    $browseButton.Enabled = $false
    $clearButton.Enabled = $false
    $rescanButton.Enabled = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    try {
        $statusLabel.Text = "Preparing scan..."
        $scanStatusText.Text = "Preparing scan..."
        $progressBar.Value = 0
        $scanProgressBar.Value = 0
        [System.Windows.Forms.Application]::DoEvents()

        $verifiedMods = @()
        $unknownMods = @()
        $cheatMods = @()

        $jarFiles = Get-ChildItem -Path $mods -Filter *.jar -File -ErrorAction SilentlyContinue
        if (-not $jarFiles -or $jarFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No .jar files found in the selected folder.","TESLAPRO","OK","Information") | Out-Null
            return
        }

        $totalMods = $jarFiles.Count
        $current = 0

        foreach ($file in $jarFiles) {
            $current++
            $msg = "Hash verification: $current / $totalMods - $($file.Name)"
            $statusLabel.Text = $msg
            $scanStatusText.Text = $msg
            $progressBar.Value = [Math]::Min([int](($current / $totalMods) * 60), 60)
            $scanProgressBar.Value = $progressBar.Value
            [System.Windows.Forms.Application]::DoEvents()

            $hash = Get-SHA1 -filePath $file.FullName

            if ($chkUseModrinth.Checked) {
                $modDataModrinth = Fetch-Modrinth -hash $hash
                if ($modDataModrinth.Slug) {
                    $verifiedMods += [PSCustomObject]@{
                        ModName  = $modDataModrinth.Name
                        FileName = $file.Name
                        Source   = "Modrinth"
                        FilePath = $file.FullName
                    }
                    continue
                }
            }

            if ($chkUseMegabase.Checked) {
                $modDataMegabase = Fetch-Megabase -hash $hash
                if ($modDataMegabase.name) {
                    $verifiedMods += [PSCustomObject]@{
                        ModName  = $modDataMegabase.Name
                        FileName = $file.Name
                        Source   = "Megabase"
                        FilePath = $file.FullName
                    }
                    continue
                }
            }

            $zoneId = Get-ZoneIdentifier $file.FullName
            $unknownMods += [PSCustomObject]@{
                FileName = $file.Name
                FilePath = $file.FullName
                ZoneId   = $zoneId
            }
        }

        if ($chkDeepScan.Checked -and $unknownMods.Count -gt 0) {
            $tempDir = Join-Path $env:TEMP "teslapro_premium_modanalyzer_v2"
            $deepCurrent = 0
            $deepTotal = $unknownMods.Count

            try {
                if (Test-Path $tempDir) {
                    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
                }

                New-Item -ItemType Directory -Path $tempDir | Out-Null

                foreach ($mod in @($unknownMods)) {
                    $deepCurrent++
                    $msg = "Deep scan: $deepCurrent / $deepTotal - $($mod.FileName)"
                    $statusLabel.Text = $msg
                    $scanStatusText.Text = $msg
                    $progressBar.Value = [Math]::Min(60 + [int](($deepCurrent / $deepTotal) * 40), 100)
                    $scanProgressBar.Value = $progressBar.Value
                    [System.Windows.Forms.Application]::DoEvents()

                    $modStrings = Check-Strings $mod.FilePath
                    if ($modStrings.Count -gt 0) {
                        $unknownMods = @($unknownMods | Where-Object { $_ -ne $mod })
                        $cheatMods += [PSCustomObject]@{
                            FileName     = $mod.FileName
                            FilePath     = $mod.FilePath
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
                            FilePath     = $mod.FilePath
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

        $script:allVerified = $verifiedMods
        $script:allUnknown = $unknownMods
        $script:allSuspicious = $cheatMods
        $script:totalFiles = $totalMods
        $script:scanPath = $mods

        if ($chkSaveHistory.Checked) {
            Add-HistoryEntry -Path $mods -Scanned $totalMods -Verified $verifiedMods.Count -Unknown $unknownMods.Count -Suspicious $cheatMods.Count
        }

        Update-Cards
        Apply-FilterAndSort

        $statusLabel.Text = "Scan complete."
        $scanStatusText.Text = "Scan complete."
        $progressBar.Value = 100
        $scanProgressBar.Value = 100

        if ($chkShowPopups.Checked) {
            [System.Windows.Forms.MessageBox]::Show(
                "Scan complete.`n`nScanned: $totalMods`nVerified: $($verifiedMods.Count)`nUnknown: $($unknownMods.Count)`nSuspicious: $($cheatMods.Count)",
                "TESLAPRO",
                "OK",
                "Information"
            ) | Out-Null
        }

        if ($chkAutoOpenResults.Checked -or $chkOpenResultsAfterScan.Checked) {
            Show-Page "Results"
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $($_.Exception.Message)","TESLAPRO","OK","Error") | Out-Null
        $statusLabel.Text = "Error during scan."
        $scanStatusText.Text = "Error during scan."
    }
    finally {
        $scanButton.Enabled = $true
        $browseButton.Enabled = $true
        $clearButton.Enabled = $true
        $rescanButton.Enabled = $true
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
}

function Apply-Theme {
    $theme = Get-Theme

    $form.BackColor = $theme.FormBack
    $form.ForeColor = $theme.Fore

    $sidebar.BackColor = $theme.SidebarBack
    $logo.ForeColor = $theme.Accent
    $logoSub.ForeColor = $theme.Muted
    $sidebarFooter.ForeColor = $theme.Muted

    foreach ($b in @($btnDashboard,$btnScan,$btnResults,$btnHistory,$btnSettings)) {
        $b.BackColor = $theme.BtnNeutral
        $b.ForeColor = $theme.Fore
    }

    foreach ($panel in @(
        $pageDashboard,$pageScan,$pageResults,$pageHistory,$pageSettings,
        $dashHeader,$dashQuickPanel,$dashHistoryPanel,
        $scanHeader,$scanTopPanel,$scanOptionsPanel,$scanProgressPanel,
        $resHeader,$resFiltersPanel,$resDetailsPanel,
        $histHeader,$historyPanel,$setHeader,$settingsPanel
    )) {
        $panel.BackColor = $theme.PanelBack
    }

    foreach ($panel in @($dashHeader,$scanHeader,$resHeader,$histHeader,$setHeader)) {
        $panel.BackColor = $theme.HeaderBack
    }

    foreach ($card in @($dCard1,$dCard2,$dCard3,$dCard4,$rCard1,$rCard2,$rCard3,$rCard4)) {
        $card[0].BackColor = $theme.CardBack
        $card[3].ForeColor = $theme.Muted
    }

    $dCard1[2].BackColor = $theme.Green
    $dCard2[2].BackColor = $theme.Yellow
    $dCard3[2].BackColor = $theme.Red
    $dCard4[2].BackColor = $theme.Accent
    $rCard1[2].BackColor = $theme.Green
    $rCard2[2].BackColor = $theme.Yellow
    $rCard3[2].BackColor = $theme.Red
    $rCard4[2].BackColor = $theme.Accent

    $dashTitle.ForeColor = $theme.Accent
    $dashSub.ForeColor = $theme.Muted
    $quickTitle.ForeColor = $theme.Fore
    $dashInfo.ForeColor = $theme.Muted
    $dashLatestTitle.ForeColor = $theme.Fore

    $dashLatestBox.BackColor = $theme.InputBack
    $dashLatestBox.ForeColor = $theme.Fore

    $dashHistoryTitle.ForeColor = $theme.Fore
    $dashHistoryList.BackColor = $theme.InputBack
    $dashHistoryList.ForeColor = $theme.Fore

    $scanTitle.ForeColor = $theme.Accent
    $scanSub.ForeColor = $theme.Muted
    $pathLabel.ForeColor = $theme.Muted
    $pathBox.BackColor = $theme.InputBack
    $pathBox.ForeColor = $theme.Fore
    $browseButton.BackColor = $theme.BtnNeutral
    $browseButton.ForeColor = $theme.Fore
    $scanButton.BackColor = $theme.BtnPrimary
    $clearButton.BackColor = $theme.BtnDanger
    $clearButton.ForeColor = $theme.Fore
    $rescanButton.BackColor = $theme.BtnNeutral
    $rescanButton.ForeColor = $theme.Fore

    $optTitle.ForeColor = $theme.Fore
    foreach ($chk in @($chkDeepScan,$chkUseModrinth,$chkUseMegabase,$chkShowPopups,$chkAutoOpenResults,$chkSaveHistory)) {
        $chk.ForeColor = $theme.Fore
    }
    $scanHint.ForeColor = $theme.Muted
    $scanProgressTitle.ForeColor = $theme.Fore
    $scanStatusText.BackColor = $theme.InputBack
    $scanStatusText.ForeColor = $theme.Fore

    $resTitle.ForeColor = $theme.Accent
    $resSub.ForeColor = $theme.Muted
    $searchLabel.ForeColor = $theme.Muted
    $searchBox.BackColor = $theme.InputBack
    $searchBox.ForeColor = $theme.Fore
    $filterLabel.ForeColor = $theme.Muted
    $sortLabel.ForeColor = $theme.Muted
    $showOnlyDownloaded.ForeColor = $theme.Fore
    $detailsTitle.ForeColor = $theme.Muted
    $detailsBox.BackColor = $theme.InputBack
    $detailsBox.ForeColor = $theme.Fore
    $openLocationButton.BackColor = $theme.BtnNeutral
    $openLocationButton.ForeColor = $theme.Fore
    $copyMatchesButton.BackColor = $theme.BtnNeutral
    $copyMatchesButton.ForeColor = $theme.Fore

    $histTitle.ForeColor = $theme.Accent
    $histSub.ForeColor = $theme.Muted
    $historyTitle.ForeColor = $theme.Fore
    $historyList.BackColor = $theme.InputBack
    $historyList.ForeColor = $theme.Fore

    $setTitle.ForeColor = $theme.Accent
    $setSub.ForeColor = $theme.Muted
    $settingsTitle.ForeColor = $theme.Fore
    foreach ($chk in @($chkDarkTheme,$chkAutoScan,$chkOpenResultsAfterScan,$chkRememberPath)) {
        $chk.ForeColor = $theme.Fore
    }
    $settingsNote.ForeColor = $theme.Muted

    $statusBar.BackColor = $theme.HeaderBack
    $statusLabel.ForeColor = $theme.Fore
    $exportMenu.ForeColor = $theme.Fore

    foreach ($grid in @($gridVerified,$gridUnknown,$gridSuspicious)) {
        $grid.BackgroundColor = $theme.GridBack
        $grid.GridColor = $theme.GridLine
        $grid.ColumnHeadersDefaultCellStyle.BackColor = $theme.GridHeader
        $grid.ColumnHeadersDefaultCellStyle.ForeColor = $theme.Fore
        $grid.DefaultCellStyle.BackColor = $theme.GridBack
        $grid.DefaultCellStyle.ForeColor = $theme.Fore
    }
}

# =========================
# Events
# =========================

$btnDashboard.Add_Click({ Show-Page "Dashboard" })
$btnScan.Add_Click({ Show-Page "Scan" })
$btnResults.Add_Click({ Show-Page "Results" })
$btnHistory.Add_Click({ Show-Page "History" })
$btnSettings.Add_Click({ Show-Page "Settings" })

$dashStartScan.Add_Click({ Show-Page "Scan" })
$dashGoResults.Add_Click({ Show-Page "Results" })
$dashExport.Add_Click({ Export-Results "TXT" })

$browseButton.Add_Click({
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathBox.Text = $folderDialog.SelectedPath
    }
})

$scanButton.Add_Click({ Start-Scan })
$rescanButton.Add_Click({ Start-Scan })
$clearButton.Add_Click({ Clear-Results })

$searchBox.Add_TextChanged({ Apply-FilterAndSort })
$filterCombo.Add_SelectedIndexChanged({ Apply-FilterAndSort })
$sortCombo.Add_SelectedIndexChanged({ Apply-FilterAndSort })
$showOnlyDownloaded.Add_CheckedChanged({ Apply-FilterAndSort })

$gridVerified.Add_SelectionChanged({
    if ($gridVerified.SelectedRows.Count -gt 0) {
        $row = $gridVerified.SelectedRows[0]
        $detailsBox.Text = "Verified | Mod Name: $($row.Cells[0].Value) | File Name: $($row.Cells[1].Value) | Source: $($row.Cells[2].Value)"
    }
})

$gridUnknown.Add_SelectionChanged({
    if ($gridUnknown.SelectedRows.Count -gt 0) {
        $row = $gridUnknown.SelectedRows[0]
        $detailsBox.Text = "Unknown | File Name: $($row.Cells[0].Value) | Downloaded From: $($row.Cells[1].Value)"
    }
})

$gridSuspicious.Add_SelectionChanged({
    if ($gridSuspicious.SelectedRows.Count -gt 0) {
        $row = $gridSuspicious.SelectedRows[0]
        $detailsBox.Text = "Suspicious | File Name: $($row.Cells[0].Value) | Embedded Jar: $($row.Cells[1].Value) | Matches: $($row.Cells[2].Value)"
    }
})

$openLocationButton.Add_Click({
    $path = $null

    if ($resultsTabs.SelectedTab -eq $tabVerified -and $gridVerified.SelectedRows.Count -gt 0) {
        $fileName = [string]$gridVerified.SelectedRows[0].Cells[1].Value
        if ($scanPath) { $path = Join-Path $scanPath $fileName }
    }
    elseif ($resultsTabs.SelectedTab -eq $tabUnknown -and $gridUnknown.SelectedRows.Count -gt 0) {
        $fileName = [string]$gridUnknown.SelectedRows[0].Cells[0].Value
        if ($scanPath) { $path = Join-Path $scanPath $fileName }
    }
    elseif ($resultsTabs.SelectedTab -eq $tabSuspicious -and $gridSuspicious.SelectedRows.Count -gt 0) {
        $fileName = [string]$gridSuspicious.SelectedRows[0].Cells[0].Value
        if ($scanPath) { $path = Join-Path $scanPath $fileName }
    }

    if ($path -and (Test-Path $path)) {
        Start-Process explorer.exe "/select,`"$path`""
    } else {
        [System.Windows.Forms.MessageBox]::Show("No file selected or file not found.","TESLAPRO","OK","Information") | Out-Null
    }
})

$copyMatchesButton.Add_Click({
    if ($resultsTabs.SelectedTab -eq $tabSuspicious -and $gridSuspicious.SelectedRows.Count -gt 0) {
        $matches = [string]$gridSuspicious.SelectedRows[0].Cells[2].Value
        if ($matches) {
            [System.Windows.Forms.Clipboard]::SetText($matches)
            [System.Windows.Forms.MessageBox]::Show("Suspicious matches copied to clipboard.","TESLAPRO","OK","Information") | Out-Null
            return
        }
    }
    [System.Windows.Forms.MessageBox]::Show("Select a suspicious result first.","TESLAPRO","OK","Information") | Out-Null
})

$exportMenu.DropDownItems[0].Add_Click({ Export-Results "TXT" })
$exportMenu.DropDownItems[1].Add_Click({ Export-Results "CSV" })
$exportMenu.DropDownItems[2].Add_Click({ Export-Results "JSON" })

$chkDarkTheme.Add_CheckedChanged({
    $script:IsDarkTheme = $chkDarkTheme.Checked
    Apply-Theme
})

# =========================
# Init
# =========================

Apply-Theme
Update-Cards
Show-Page "Dashboard"

if ($chkAutoScan.Checked) {
    Start-Scan
}

[void]$form.ShowDialog()