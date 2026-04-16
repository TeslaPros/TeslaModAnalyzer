#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# =========================
# Double-buffer helper
# =========================
$doubleBufferProp = [System.Type]::GetType("System.Windows.Forms.Control").GetProperty(
    "DoubleBuffered",
    [System.Reflection.BindingFlags] "Instance,NonPublic"
)

function Enable-DoubleBuffer { param($c); $doubleBufferProp?.SetValue($c, $true, $null) }

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
        if ($ads -match "HostUrl=(.+)") { return $matches[1].Trim() }
    } catch {}
    return $null
}

function Fetch-Modrinth {
    param([string]$hash)
    try {
        $ver = Invoke-RestMethod "https://api.modrinth.com/v2/version_file/$hash" -ErrorAction Stop
        if ($ver.project_id) {
            $proj = Invoke-RestMethod "https://api.modrinth.com/v2/project/$($ver.project_id)" -ErrorAction Stop
            return @{ Name = $proj.title; Slug = $proj.slug }
        }
    } catch {}
    return @{ Name = ""; Slug = "" }
}

function Fetch-Megabase {
    param([string]$hash)
    try {
        $r = Invoke-RestMethod "https://megabase.vercel.app/api/query?hash=$hash" -ErrorAction Stop
        if (-not $r.error) { return $r.data }
    } catch {}
    return $null
}

# Cheat strings – normalized lookup map
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
    $key = Normalize-Text $item
    if ($key -and -not $normalizedCheatMap.ContainsKey($key)) {
        $normalizedCheatMap[$key] = $item
    }
}

function Check-Strings {
    param([string]$filePath)
    $found = [System.Collections.Generic.HashSet[string]]::new()
    try {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        if (-not $bytes -or $bytes.Length -eq 0) { return $found }
        $content = Normalize-Text ([System.Text.Encoding]::UTF8.GetString($bytes))
        foreach ($key in $normalizedCheatMap.Keys) {
            if ($content.Contains($key)) { [void]$found.Add($normalizedCheatMap[$key]) }
        }
    } catch {}
    return $found
}

# =========================
# Color palette (dark neon)
# =========================

$C = @{
    Bg0         = [System.Drawing.Color]::FromArgb(8, 10, 18)
    Bg1         = [System.Drawing.Color]::FromArgb(12, 15, 24)
    Bg2         = [System.Drawing.Color]::FromArgb(16, 20, 32)
    Bg3         = [System.Drawing.Color]::FromArgb(22, 27, 42)
    Bg4         = [System.Drawing.Color]::FromArgb(28, 34, 52)
    Border      = [System.Drawing.Color]::FromArgb(40, 50, 75)
    BorderBright= [System.Drawing.Color]::FromArgb(60, 80, 120)
    Fore        = [System.Drawing.Color]::FromArgb(220, 230, 255)
    ForeD       = [System.Drawing.Color]::FromArgb(120, 135, 170)
    Accent      = [System.Drawing.Color]::FromArgb(80, 180, 255)
    AccentD     = [System.Drawing.Color]::FromArgb(30, 90, 160)
    Green       = [System.Drawing.Color]::FromArgb(50, 220, 120)
    GreenD      = [System.Drawing.Color]::FromArgb(20, 90, 50)
    Yellow      = [System.Drawing.Color]::FromArgb(255, 200, 60)
    YellowD     = [System.Drawing.Color]::FromArgb(100, 75, 15)
    Red         = [System.Drawing.Color]::FromArgb(255, 80, 90)
    RedD        = [System.Drawing.Color]::FromArgb(100, 25, 30)
    BtnBlue     = [System.Drawing.Color]::FromArgb(0, 115, 210)
    BtnGray     = [System.Drawing.Color]::FromArgb(30, 38, 58)
    Selection   = [System.Drawing.Color]::FromArgb(0, 115, 210)
    White       = [System.Drawing.Color]::White
}

# =========================
# Font helpers
# =========================

function fnt { param([float]$s, [System.Drawing.FontStyle]$st = "Regular") New-Object System.Drawing.Font("Segoe UI", $s, $st) }
function fntB { param([float]$s) fnt $s Bold }

# =========================
# UI builder helpers
# =========================

function New-Panel {
    param([int]$X, [int]$Y, [int]$W, [int]$H, [System.Drawing.Color]$Back = $C.Bg1)
    $p = New-Object System.Windows.Forms.Panel
    $p.SetBounds($X, $Y, $W, $H)
    $p.BackColor = $Back
    Enable-DoubleBuffer $p
    return $p
}

function New-Label {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H,
          [System.Drawing.Color]$Fore = $C.Fore,
          [System.Drawing.Font]$Font = $null)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text; $l.SetBounds($X, $Y, $W, $H)
    $l.ForeColor = $Fore
    $l.BackColor = [System.Drawing.Color]::Transparent
    if ($Font) { $l.Font = $Font }
    return $l
}

function New-Btn {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H,
          [System.Drawing.Color]$Back = $C.BtnGray,
          [System.Drawing.Color]$Fore = $C.Fore)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text; $b.SetBounds($X, $Y, $W, $H)
    $b.FlatStyle = 'Flat'
    $b.FlatAppearance.BorderSize = 1
    $b.FlatAppearance.BorderColor = $C.Border
    $b.BackColor = $Back; $b.ForeColor = $Fore
    $b.Font = fntB 9.5
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Add_MouseEnter({ $this.FlatAppearance.BorderColor = $C.AccentD })
    $b.Add_MouseLeave({ $this.FlatAppearance.BorderColor = $C.Border })
    return $b
}

function New-StatCard {
    param([string]$Label, [System.Drawing.Color]$Accent, [int]$X, [int]$Y)
    $W = 290; $H = 100
    $card = New-Panel $X $Y $W $H $C.Bg2
    $card.BorderStyle = 'FixedSingle'

    # left color bar via Paint event
    $accentCopy = $Accent
    $card.Add_Paint({
        param($s, $e)
        $e.Graphics.FillRectangle([System.Drawing.SolidBrush]::new($accentCopy), 0, 0, 4, $s.Height)
    })

    $lbl = New-Label $Label 18 12 240 20 $C.ForeD (fnt 9.5)
    $val = New-Label "0" 18 36 240 46 $Accent (fntB 28)

    $card.Controls.AddRange(@($lbl, $val))
    return @{ Panel = $card; Value = $val; Label = $lbl }
}

function New-Grid {
    param([int]$X, [int]$Y, [int]$W, [int]$H)
    $g = New-Object System.Windows.Forms.DataGridView
    $g.SetBounds($X, $Y, $W, $H)
    $g.BackgroundColor = $C.Bg1
    $g.BorderStyle = 'None'
    $g.GridColor = $C.Border
    $g.EnableHeadersVisualStyles = $false
    $g.ColumnHeadersDefaultCellStyle.BackColor = $C.Bg3
    $g.ColumnHeadersDefaultCellStyle.ForeColor = $C.Fore
    $g.ColumnHeadersDefaultCellStyle.Font = fntB 9.5
    $g.ColumnHeadersBorderStyle = 'Single'
    $g.ColumnHeadersHeight = 34
    $g.DefaultCellStyle.BackColor = $C.Bg1
    $g.DefaultCellStyle.ForeColor = $C.Fore
    $g.DefaultCellStyle.Font = fnt 9.5
    $g.DefaultCellStyle.SelectionBackColor = $C.Selection
    $g.DefaultCellStyle.SelectionForeColor = $C.White
    $g.AlternatingRowsDefaultCellStyle.BackColor = $C.Bg2
    $g.AlternatingRowsDefaultCellStyle.SelectionBackColor = $C.Selection
    $g.AlternatingRowsDefaultCellStyle.SelectionForeColor = $C.White
    $g.RowHeadersVisible = $false
    $g.AutoSizeColumnsMode = 'Fill'
    $g.SelectionMode = 'FullRowSelect'
    $g.MultiSelect = $false
    $g.ReadOnly = $true
    $g.AllowUserToAddRows = $false
    $g.AllowUserToDeleteRows = $false
    $g.AllowUserToResizeRows = $false
    $g.RowTemplate.Height = 28
    Enable-DoubleBuffer $g
    return $g
}

function New-TextBox {
    param([int]$X, [int]$Y, [int]$W, [int]$H, [string]$Text = "", [bool]$ReadOnly = $false)
    $t = New-Object System.Windows.Forms.TextBox
    $t.SetBounds($X, $Y, $W, $H)
    $t.BackColor = $C.Bg3
    $t.ForeColor = $C.Fore
    $t.BorderStyle = 'FixedSingle'
    $t.Font = fnt 10
    $t.Text = $Text
    $t.ReadOnly = $ReadOnly
    return $t
}

# =========================
# Shared state
# =========================

$script:allVerified   = @()
$script:allUnknown    = @()
$script:allSuspicious = @()
$script:scanPath      = ""
$script:totalFiles    = 0
$script:scanHistory   = New-Object System.Collections.Generic.List[object]
$script:IsDarkTheme   = $true   # kept for compat

# =========================
# Main form
# =========================

$form = New-Object System.Windows.Forms.Form
$form.Text = "TESLAPRO Premium Mod Analyzer V3"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1600, 1000)
$form.MinimumSize = New-Object System.Drawing.Size(1400, 860)
$form.BackColor = $C.Bg0
$form.ForeColor = $C.Fore
$form.Font = fnt 10
Enable-DoubleBuffer $form

# --- Sidebar ---
$sidebar = New-Panel 0 0 220 1000 $C.Bg1
$sidebar.Anchor = 'Top,Bottom,Left'
$sidebar.BorderStyle = 'None'

# Sidebar paint – right border line
$sidebar.Add_Paint({
    param($s,$e)
    $pen = New-Object System.Drawing.Pen($C.Border, 1)
    $e.Graphics.DrawLine($pen, $s.Width-1, 0, $s.Width-1, $s.Height)
    $pen.Dispose()
})

$logoLabel = New-Label "TESLA" 20 28 180 38 $C.Accent (fntB 26)
$proLabel  = New-Label "PRO" 100 30 80 32 $C.White (fntB 22)
$subLabel  = New-Label "Mod Analyzer V3" 22 68 180 20 $C.ForeD (fnt 9)
$sidebar.Controls.AddRange(@($logoLabel, $proLabel, $subLabel))

# Sidebar divider
$sideDiv = New-Panel 16 100 188 1 $C.Border
$sidebar.Controls.Add($sideDiv)

function New-NavBtn {
    param([string]$Icon, [string]$Text, [int]$Y)
    $b = New-Object System.Windows.Forms.Button
    $b.SetBounds(12, $Y, 196, 44)
    $b.Text = "$Icon  $Text"
    $b.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $b.FlatStyle = 'Flat'
    $b.FlatAppearance.BorderSize = 0
    $b.BackColor = [System.Drawing.Color]::Transparent
    $b.ForeColor = $C.ForeD
    $b.Font = fnt 10.5
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Add_MouseEnter({
        if ($this.BackColor.A -eq 0 -or $this.BackColor -ne $C.BtnGray) {
            $this.ForeColor = $C.Fore
        }
    })
    $b.Add_MouseLeave({
        if ($this.Tag -ne "active") {
            $this.ForeColor = $C.ForeD
            $this.BackColor = [System.Drawing.Color]::Transparent
        }
    })
    return $b
}

$btnDashboard = New-NavBtn "≡" "Dashboard"  118
$btnScan      = New-NavBtn "⊕" "Scan Center" 166
$btnResults   = New-NavBtn "⊞" "Results"     214
$btnHistory   = New-NavBtn "⌛" "History"    262
$btnSettings  = New-NavBtn "⚙" "Settings"   310

$navButtons = @($btnDashboard, $btnScan, $btnResults, $btnHistory, $btnSettings)

$footerLabel = New-Label "Discord: @teamwsf" 20 940 180 20 $C.ForeD (fnt 9)
$footerLabel.Anchor = 'Bottom,Left'

$sidebar.Controls.AddRange(@($btnDashboard,$btnScan,$btnResults,$btnHistory,$btnSettings,$footerLabel))

# --- Main host ---
$mainHost = New-Panel 220 0 1380 1000 $C.Bg0
$mainHost.Anchor = 'Top,Bottom,Left,Right'

# =========================
# Page helper
# =========================

$pages = @{}

function New-Page {
    param([string]$Name)
    $p = New-Panel 0 0 1380 1000 $C.Bg0
    $p.Visible = $false
    $p.Anchor = 'Top,Bottom,Left,Right'
    $mainHost.Controls.Add($p)
    $pages[$Name] = $p
    return $p
}

function New-PageHeader {
    param([System.Windows.Forms.Panel]$Page, [string]$Title, [string]$Sub)
    $hdr = New-Panel 20 18 1340 80 $C.Bg1
    $hdr.Anchor = 'Top,Left,Right'
    $hdr.BorderStyle = 'FixedSingle'

    # Bottom accent line
    $hdr.Add_Paint({
        param($s,$e)
        $brush = New-Object System.Drawing.SolidBrush($C.Accent)
        $e.Graphics.FillRectangle($brush, 0, $s.Height-2, $s.Width, 2)
        $brush.Dispose()
    })

    $t = New-Label $Title 20 12 600 36 $C.Accent (fntB 22)
    $s = New-Label $Sub 22 50 700 18 $C.ForeD (fnt 9.5)
    $hdr.Controls.AddRange(@($t, $s))
    $Page.Controls.Add($hdr)
    return $hdr
}

# =========================
# Pages
# =========================

$pageDashboard = New-Page "Dashboard"
$pageScan      = New-Page "Scan"
$pageResults   = New-Page "Results"
$pageHistory   = New-Page "History"
$pageSettings  = New-Page "Settings"

# =========================
# Dashboard
# =========================

New-PageHeader $pageDashboard "Dashboard" "Overview of your latest scan activity" | Out-Null

# Stat cards
$dashCard1 = New-StatCard "Verified Mods"    $C.Green  20  118
$dashCard2 = New-StatCard "Unknown Mods"     $C.Yellow 330 118
$dashCard3 = New-StatCard "Suspicious Mods"  $C.Red    640 118
$dashCard4 = New-StatCard "Scanned Files"    $C.Accent 950 118

$pageDashboard.Controls.AddRange(@(
    $dashCard1.Panel, $dashCard2.Panel, $dashCard3.Panel, $dashCard4.Panel
))

# Quick actions panel
$dashActions = New-Panel 20 240 680 280 $C.Bg2
$dashActions.BorderStyle = 'FixedSingle'

$qTitle = New-Label "Quick Actions" 18 14 300 28 $C.Fore (fntB 14)
$btnDashScan    = New-Btn "▶  Start New Scan"      22 58  200 38 $C.BtnBlue $C.White
$btnDashResults = New-Btn "⊞  Open Results"        238 58 180 38
$btnDashExport  = New-Btn "↓  Export Results"      434 58 200 38

$summaryLbl  = New-Label "Latest Summary" 22 116 300 22 $C.Fore (fntB 11)
$dashSummary = New-TextBox 22 144 628 32 "" $true

$infoLbl = New-Label "Use Dashboard for a quick overview, Scan Center for a new scan, Results for detailed inspection." 22 195 630 50 $C.ForeD (fnt 9.5)

$dashActions.Controls.AddRange(@($qTitle,$btnDashScan,$btnDashResults,$btnDashExport,$summaryLbl,$dashSummary,$infoLbl))

# Recent history panel
$dashHistPanel = New-Panel 720 240 620 280 $C.Bg2
$dashHistPanel.BorderStyle = 'FixedSingle'

$dhTitle = New-Label "Recent History" 18 14 300 28 $C.Fore (fntB 14)
$dashHistList = New-Object System.Windows.Forms.ListBox
$dashHistList.SetBounds(16, 48, 588, 216)
$dashHistList.BackColor = $C.Bg3; $dashHistList.ForeColor = $C.Fore
$dashHistList.BorderStyle = 'None'; $dashHistList.Font = fnt 9.5

$dashHistPanel.Controls.AddRange(@($dhTitle, $dashHistList))
$pageDashboard.Controls.AddRange(@($dashActions, $dashHistPanel))

# =========================
# Scan Center
# =========================

New-PageHeader $pageScan "Scan Center" "Choose a mods folder, configure options and start scanning" | Out-Null

# Path row
$scanPathPanel = New-Panel 20 118 1340 80 $C.Bg2
$scanPathPanel.BorderStyle = 'FixedSingle'

$pathLbl  = New-Label "Mods Folder" 18 10 120 18 $C.ForeD (fnt 9)
$pathBox  = New-TextBox 18 32 870 30 "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
$btnBrowse= New-Btn "Browse"  902 30 100 34
$btnScan  = New-Btn "▶ Scan"  1014 30 110 34 $C.BtnBlue $C.White
$btnClear = New-Btn "Clear"   1136 30 80 34  $C.RedD
$btnRescan= New-Btn "↺ Rescan" 1228 30 100 34

$scanPathPanel.Controls.AddRange(@($pathLbl,$pathBox,$btnBrowse,$btnScan,$btnClear,$btnRescan))
$pageScan.Controls.Add($scanPathPanel)

# Options
$scanOptPanel = New-Panel 20 216 1340 180 $C.Bg2
$scanOptPanel.BorderStyle = 'FixedSingle'

$oTitle = New-Label "Scan Options" 18 12 300 26 $C.Fore (fntB 13)

function New-Chk {
    param([string]$Text, [int]$X, [int]$Y, [bool]$Checked = $true)
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Text = $Text; $c.SetBounds($X, $Y, 340, 26)
    $c.Checked = $Checked
    $c.ForeColor = $C.Fore; $c.BackColor = [System.Drawing.Color]::Transparent
    $c.Font = fnt 10; $c.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $c
}

$chkDeep      = New-Chk "Deep scan (embedded JARs)"           22  50
$chkModrinth  = New-Chk "Modrinth verification"                22  82
$chkMegabase  = New-Chk "Megabase verification"                22 114
$chkPopups    = New-Chk "Show popup after scan"               400  50
$chkAutoRes   = New-Chk "Auto-open Results Center"            400  82
$chkHistory   = New-Chk "Save to history"                     400 114

$scanHint = New-Label "Tip: keep the raw GitHub filename unchanged to allow CMD-based remote execution." 740 58 580 60 $C.ForeD (fnt 9)

$scanOptPanel.Controls.AddRange(@($oTitle,$chkDeep,$chkModrinth,$chkMegabase,$chkPopups,$chkAutoRes,$chkHistory,$scanHint))
$pageScan.Controls.Add($scanOptPanel)

# Progress panel
$scanProgPanel = New-Panel 20 414 1340 110 $C.Bg2
$scanProgPanel.BorderStyle = 'FixedSingle'

$progTitle  = New-Label "Scan Status" 18 10 300 24 $C.Fore (fntB 13)
$statusText = New-TextBox 18 38 1300 30 "Ready." $true
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.SetBounds(18, 76, 1300, 20)
$progressBar.Minimum = 0; $progressBar.Maximum = 100; $progressBar.Value = 0

$scanProgPanel.Controls.AddRange(@($progTitle,$statusText,$progressBar))
$pageScan.Controls.Add($scanProgPanel)

# =========================
# Results Center
# =========================

New-PageHeader $pageResults "Results Center" "Search, filter, export and inspect scan results" | Out-Null

# Stat cards for results
$resCard1 = New-StatCard "Verified Mods"    $C.Green  20  118
$resCard2 = New-StatCard "Unknown Mods"     $C.Yellow 330 118
$resCard3 = New-StatCard "Suspicious Mods"  $C.Red    640 118
$resCard4 = New-StatCard "Scanned Files"    $C.Accent 950 118

$pageResults.Controls.AddRange(@($resCard1.Panel,$resCard2.Panel,$resCard3.Panel,$resCard4.Panel))

# Filter bar
$filterPanel = New-Panel 20 238 1340 56 $C.Bg2
$filterPanel.BorderStyle = 'FixedSingle'

$searchLbl = New-Label "Search" 14 18 58 20 $C.ForeD
$searchBox = New-TextBox 72 14 280 28

$catLbl = New-Label "Category" 368 18 72 20 $C.ForeD
$catCombo = New-Object System.Windows.Forms.ComboBox
$catCombo.SetBounds(440, 14, 160, 28)
$catCombo.DropDownStyle = 'DropDownList'; $catCombo.BackColor = $C.Bg3; $catCombo.ForeColor = $C.Fore
[void]$catCombo.Items.AddRange(@("All","Verified","Unknown","Suspicious"))
$catCombo.SelectedIndex = 0

$sortLbl = New-Label "Sort" 616 18 40 20 $C.ForeD
$sortCombo = New-Object System.Windows.Forms.ComboBox
$sortCombo.SetBounds(658, 14, 200, 28)
$sortCombo.DropDownStyle = 'DropDownList'; $sortCombo.BackColor = $C.Bg3; $sortCombo.ForeColor = $C.Fore
[void]$sortCombo.Items.AddRange(@("File Name A→Z","File Name Z→A","Source","Match Count"))
$sortCombo.SelectedIndex = 0

$chkOnlyDl = New-Chk "Only downloaded-source unknowns" 880 16 340 $false

$filterPanel.Controls.AddRange(@($searchLbl,$searchBox,$catLbl,$catCombo,$sortLbl,$sortCombo,$chkOnlyDl))
$pageResults.Controls.Add($filterPanel)

# Tabs
$resultsTabs = New-Object System.Windows.Forms.TabControl
$resultsTabs.SetBounds(20, 308, 1340, 460)
$resultsTabs.Anchor = 'Top,Bottom,Left,Right'
$resultsTabs.Font = fntB 10

$tabV = New-Object System.Windows.Forms.TabPage; $tabV.Text = "  Verified  "; $tabV.BackColor = $C.Bg1
$tabU = New-Object System.Windows.Forms.TabPage; $tabU.Text = "  Unknown  "; $tabU.BackColor = $C.Bg1
$tabS = New-Object System.Windows.Forms.TabPage; $tabS.Text = "  Suspicious  "; $tabS.BackColor = $C.Bg1

$gridV = New-Grid 8 8 1305 414
$gridU = New-Grid 8 8 1305 414
$gridS = New-Grid 8 8 1305 414

$tabV.Controls.Add($gridV); $tabU.Controls.Add($gridU); $tabS.Controls.Add($gridS)
$resultsTabs.TabPages.AddRange(@($tabV,$tabU,$tabS))
$pageResults.Controls.Add($resultsTabs)

# Details bar
$detailsBar = New-Panel 20 780 1340 100 $C.Bg2
$detailsBar.Anchor = 'Bottom,Left,Right'
$detailsBar.BorderStyle = 'FixedSingle'

$detLbl    = New-Label "Selected" 14 10 80 18 $C.ForeD (fntB 9)
$detailBox = New-TextBox 14 30 950 30 "" $true
$btnOpenLoc = New-Btn "📁 Open Location"    980 28 150 36
$btnCopyMat = New-Btn "📋 Copy Matches"    1146 28 150 36

$detailsBar.Controls.AddRange(@($detLbl,$detailBox,$btnOpenLoc,$btnCopyMat))
$pageResults.Controls.Add($detailsBar)

# =========================
# History
# =========================

New-PageHeader $pageHistory "Scan History" "All scans saved by TESLAPRO this session" | Out-Null

$histPanel = New-Panel 20 118 1340 760 $C.Bg2
$histPanel.BorderStyle = 'FixedSingle'; $histPanel.Anchor = 'Top,Bottom,Left,Right'

$histTitle = New-Label "Saved scans" 18 14 300 24 $C.Fore (fntB 13)
$histList = New-Object System.Windows.Forms.ListBox
$histList.SetBounds(16, 46, 1308, 700)
$histList.BackColor = $C.Bg3; $histList.ForeColor = $C.Fore
$histList.BorderStyle = 'None'; $histList.Font = fnt 10
$histList.Anchor = 'Top,Bottom,Left,Right'

$histPanel.Controls.AddRange(@($histTitle,$histList))
$pageHistory.Controls.Add($histPanel)

# =========================
# Settings
# =========================

New-PageHeader $pageSettings "Settings" "Appearance and startup behavior" | Out-Null

$setPanel = New-Panel 20 118 800 400 $C.Bg2
$setPanel.BorderStyle = 'FixedSingle'

$setTitle = New-Label "General Settings" 18 14 300 26 $C.Fore (fntB 13)
$chkDark        = New-Chk "Dark theme (restart to apply fully)" 22 56  $true
$chkAutoScan    = New-Chk "Auto-scan on startup"                22 90  $false
$chkOpenAfter   = New-Chk "Open Results after scan"             22 124 $true
$chkRemPath     = New-Chk "Remember folder path during session" 22 158 $true
$setNote = New-Label "Settings apply immediately where possible. Path memory applies within the current session." 22 206 740 40 $C.ForeD (fnt 9)

$setPanel.Controls.AddRange(@($setTitle,$chkDark,$chkAutoScan,$chkOpenAfter,$chkRemPath,$setNote))
$pageSettings.Controls.Add($setPanel)

# =========================
# Status bar
# =========================

$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.BackColor = $C.Bg1; $statusBar.SizingGrip = $false

$statusLbl = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLbl.Text = "Ready."; $statusLbl.ForeColor = $C.Fore; $statusLbl.Spring = $true

$statusProg = New-Object System.Windows.Forms.ToolStripProgressBar
$statusProg.Minimum = 0; $statusProg.Maximum = 100; $statusProg.Value = 0
$statusProg.Size = New-Object System.Drawing.Size(240, 18)

$exportDd = New-Object System.Windows.Forms.ToolStripDropDownButton
$exportDd.Text = "Export ▾"; $exportDd.ForeColor = $C.Fore
[void]$exportDd.DropDownItems.Add("Export as TXT")
[void]$exportDd.DropDownItems.Add("Export as CSV")
[void]$exportDd.DropDownItems.Add("Export as JSON")

$statusBar.Items.AddRange(@($statusLbl, $statusProg, $exportDd))
$form.Controls.AddRange(@($sidebar, $mainHost, $statusBar))

# =========================
# Navigation
# =========================

function Show-Page {
    param([string]$Name)
    foreach ($p in $pages.Values) { $p.Visible = $false }
    if ($pages.ContainsKey($Name)) { $pages[$Name].Visible = $true }

    # Update nav button highlight
    $map = @{ Dashboard=$btnDashboard; Scan=$btnScan; Results=$btnResults; History=$btnHistory; Settings=$btnSettings }
    foreach ($b in $navButtons) {
        $b.Tag = ""; $b.BackColor = [System.Drawing.Color]::Transparent; $b.ForeColor = $C.ForeD
    }
    if ($map.ContainsKey($Name)) {
        $active = $map[$Name]
        $active.BackColor = $C.Bg3; $active.ForeColor = $C.Accent; $active.Tag = "active"
    }
}

# =========================
# Data helpers
# =========================

function Update-Cards {
    foreach ($card in @($dashCard1,$resCard1)) { $card.Value.Text = [string]$script:allVerified.Count }
    foreach ($card in @($dashCard2,$resCard2)) { $card.Value.Text = [string]$script:allUnknown.Count }
    foreach ($card in @($dashCard3,$resCard3)) { $card.Value.Text = [string]$script:allSuspicious.Count }
    foreach ($card in @($dashCard4,$resCard4)) { $card.Value.Text = [string]$script:totalFiles }

    if ($script:scanPath) {
        $dashSummary.Text = "Path: $($script:scanPath)  |  Scanned: $($script:totalFiles)  |  Verified: $($script:allVerified.Count)  |  Unknown: $($script:allUnknown.Count)  |  Suspicious: $($script:allSuspicious.Count)"
    } else { $dashSummary.Text = "" }
}

function Build-TableVerified {
    param($items)
    $t = New-Object System.Data.DataTable
    foreach ($col in @("Mod Name","File Name","Source")) { [void]$t.Columns.Add($col) }
    foreach ($i in $items) { [void]$t.Rows.Add($i.ModName, $i.FileName, $i.Source) }
    return $t
}

function Build-TableUnknown {
    param($items)
    $t = New-Object System.Data.DataTable
    [void]$t.Columns.Add("File Name"); [void]$t.Columns.Add("Downloaded From")
    foreach ($i in $items) { [void]$t.Rows.Add($i.FileName, $i.ZoneId) }
    return $t
}

function Build-TableSuspicious {
    param($items)
    $t = New-Object System.Data.DataTable
    foreach ($col in @("File Name","Embedded JAR","Matches","Count")) { [void]$t.Columns.Add($col) }
    foreach ($i in $items) {
        [void]$t.Rows.Add($i.FileName, $i.DepFileName, ([string]::Join(", ", $i.StringsFound)), $i.StringsFound.Count)
    }
    return $t
}

function Apply-FilterAndSort {
    $q       = $searchBox.Text.Trim().ToLowerInvariant()
    $cat     = $catCombo.SelectedItem
    $sort    = $sortCombo.SelectedItem
    $onlyDl  = $chkOnlyDl.Checked

    $v = @($script:allVerified)
    $u = @($script:allUnknown)
    $s = @($script:allSuspicious)

    if ($q) {
        $v = @($v | Where-Object { "$($_.ModName) $($_.FileName) $($_.Source)".ToLowerInvariant().Contains($q) })
        $u = @($u | Where-Object { "$($_.FileName) $($_.ZoneId)".ToLowerInvariant().Contains($q) })
        $s = @($s | Where-Object { "$($_.FileName) $($_.DepFileName) $([string]::Join(' ',$_.StringsFound))".ToLowerInvariant().Contains($q) })
    }

    if ($onlyDl) { $u = @($u | Where-Object { -not [string]::IsNullOrWhiteSpace($_.ZoneId) }) }

    switch ($sort) {
        "File Name A→Z" { $v=$v|Sort-Object FileName; $u=$u|Sort-Object FileName; $s=$s|Sort-Object FileName }
        "File Name Z→A" { $v=$v|Sort-Object FileName -Desc; $u=$u|Sort-Object FileName -Desc; $s=$s|Sort-Object FileName -Desc }
        "Source"        { $v=$v|Sort-Object Source,FileName; $u=$u|Sort-Object ZoneId,FileName; $s=$s|Sort-Object DepFileName,FileName }
        "Match Count"   { $s=$s|Sort-Object @{Expr={$_.StringsFound.Count};Desc=$true},FileName }
    }

    $gridV.DataSource = $null; $gridU.DataSource = $null; $gridS.DataSource = $null
    $gridV.DataSource = Build-TableVerified $v
    $gridU.DataSource = Build-TableUnknown $u
    $gridS.DataSource = Build-TableSuspicious $s

    if ($gridS.Columns["Count"]) { $gridS.Columns["Count"].Visible = $false }

    switch ($cat) {
        "Verified"   { $resultsTabs.SelectedTab = $tabV }
        "Unknown"    { $resultsTabs.SelectedTab = $tabU }
        "Suspicious" { $resultsTabs.SelectedTab = $tabS }
    }
}

function Clear-Results {
    $script:allVerified = @(); $script:allUnknown = @(); $script:allSuspicious = @(); $script:totalFiles = 0
    if (-not $chkRemPath.Checked) {
        $script:scanPath = ""
        $pathBox.Text = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    }
    $gridV.DataSource = $null; $gridU.DataSource = $null; $gridS.DataSource = $null
    $detailBox.Text = ""; $progressBar.Value = 0; $statusProg.Value = 0
    $statusText.Text = "Ready."; $statusLbl.Text = "Cleared."
    Update-Cards
}

function Add-HistoryEntry {
    param([string]$Path,[int]$Scanned,[int]$Verified,[int]$Unknown,[int]$Suspicious)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$ts  |  $Path  |  Files=$Scanned  Verified=$Verified  Unknown=$Unknown  Suspicious=$Suspicious"
    $histList.Items.Insert(0, $line)
    $dashHistList.Items.Insert(0, $line)
}

function Export-Results {
    param([string]$Type)
    if (-not $script:scanPath) {
        [System.Windows.Forms.MessageBox]::Show("No scan results yet.","TESLAPRO","OK","Information") | Out-Null; return
    }

    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    switch ($Type) {
        "TXT"  { $dlg.Filter = "Text files (*.txt)|*.txt";   $dlg.FileName = "TESLAPRO-Results.txt" }
        "CSV"  { $dlg.Filter = "CSV files (*.csv)|*.csv";    $dlg.FileName = "TESLAPRO-Results.csv" }
        "JSON" { $dlg.Filter = "JSON files (*.json)|*.json"; $dlg.FileName = "TESLAPRO-Results.json" }
    }
    if ($dlg.ShowDialog() -ne "OK") { return }

    if ($Type -eq "TXT") {
        $lines = @(
            "TESLAPRO PREMIUM MOD ANALYZER V3",
            "Path: $($script:scanPath)",
            "Scanned: $($script:totalFiles)  Verified: $($script:allVerified.Count)  Unknown: $($script:allUnknown.Count)  Suspicious: $($script:allSuspicious.Count)",
            "","[ VERIFIED ]"
        )
        foreach ($i in $script:allVerified) { $lines += "$($i.ModName) | $($i.FileName) | $($i.Source)" }
        $lines += "","[ UNKNOWN ]"
        foreach ($i in $script:allUnknown) { $lines += "$($i.FileName) | $($i.ZoneId)" }
        $lines += "","[ SUSPICIOUS ]"
        foreach ($i in $script:allSuspicious) { $lines += "$($i.FileName) | $($i.DepFileName) | $([string]::Join(', ',$i.StringsFound))" }
        [System.IO.File]::WriteAllLines($dlg.FileName, $lines)
    }
    elseif ($Type -eq "CSV") {
        $rows = @()
        foreach ($v in $script:allVerified)   { $rows += [PSCustomObject]@{Category="Verified";  FileName=$v.FileName; Name=$v.ModName;    Source=$v.Source; Details=""} }
        foreach ($u in $script:allUnknown)    { $rows += [PSCustomObject]@{Category="Unknown";   FileName=$u.FileName; Name="";            Source=$u.ZoneId; Details=""} }
        foreach ($s in $script:allSuspicious) { $rows += [PSCustomObject]@{Category="Suspicious";FileName=$s.FileName; Name=$s.DepFileName;Source="";        Details=([string]::Join(", ",$s.StringsFound))} }
        $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $dlg.FileName
    }
    else {
        [PSCustomObject]@{
            Path=$script:scanPath; TotalFiles=$script:totalFiles
            Verified=$script:allVerified; Unknown=$script:allUnknown; Suspicious=$script:allSuspicious
        } | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -Path $dlg.FileName
    }
    [System.Windows.Forms.MessageBox]::Show("Export completed.","TESLAPRO","OK","Information") | Out-Null
}

# =========================
# Scan engine
# =========================

function Start-Scan {
    $mods = $pathBox.Text.Trim()
    if (-not (Test-Path $mods -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("Invalid mods folder path.","TESLAPRO","OK","Warning") | Out-Null; return
    }

    foreach ($b in @($btnScan,$btnBrowse,$btnClear,$btnRescan)) { $b.Enabled = $false }
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    function Set-Status { param([string]$msg,[int]$pct)
        $statusLbl.Text = $msg; $statusText.Text = $msg
        $progressBar.Value = [Math]::Max(0,[Math]::Min($pct,100))
        $statusProg.Value  = $progressBar.Value
        [System.Windows.Forms.Application]::DoEvents()
    }

    try {
        Set-Status "Preparing scan..." 0

        $jarFiles = @(Get-ChildItem -Path $mods -Filter *.jar -File -ErrorAction SilentlyContinue)
        if (-not $jarFiles -or $jarFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No .jar files found.","TESLAPRO","OK","Information") | Out-Null; return
        }

        $total   = $jarFiles.Count
        $current = 0
        $verified = [System.Collections.Generic.List[object]]::new()
        $unknown  = [System.Collections.Generic.List[object]]::new()
        $cheats   = [System.Collections.Generic.List[object]]::new()

        foreach ($file in $jarFiles) {
            $current++
            Set-Status "Hash check: $current / $total  [$($file.Name)]" ([int](($current/$total)*60))

            $hash = Get-SHA1 $file.FullName
            $matched = $false

            if ($chkModrinth.Checked) {
                $m = Fetch-Modrinth $hash
                if ($m.Slug) {
                    $verified.Add([PSCustomObject]@{ ModName=$m.Name; FileName=$file.Name; Source="Modrinth"; FilePath=$file.FullName })
                    $matched = $true
                }
            }

            if (-not $matched -and $chkMegabase.Checked) {
                $mb = Fetch-Megabase $hash
                if ($mb.name) {
                    $verified.Add([PSCustomObject]@{ ModName=$mb.Name; FileName=$file.Name; Source="Megabase"; FilePath=$file.FullName })
                    $matched = $true
                }
            }

            if (-not $matched) {
                $unknown.Add([PSCustomObject]@{ FileName=$file.Name; FilePath=$file.FullName; ZoneId=(Get-ZoneIdentifier $file.FullName) })
            }
        }

        if ($chkDeep.Checked -and $unknown.Count -gt 0) {
            $tempDir  = Join-Path $env:TEMP "teslapro_v3_scan"
            $deepTotal   = $unknown.Count
            $deepCurrent = 0

            try {
                if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
                New-Item -ItemType Directory -Path $tempDir | Out-Null

                foreach ($mod in @($unknown)) {
                    $deepCurrent++
                    Set-Status "Deep scan: $deepCurrent / $deepTotal  [$($mod.FileName)]" (60 + [int](($deepCurrent/$deepTotal)*40))

                    # Check JAR itself
                    $strDirect = Check-Strings $mod.FilePath
                    if ($strDirect.Count -gt 0) {
                        [void]$unknown.Remove($mod)
                        $cheats.Add([PSCustomObject]@{ FileName=$mod.FileName; FilePath=$mod.FilePath; DepFileName="(main jar)"; StringsFound=@($strDirect | Sort-Object) })
                        continue
                    }

                    # Extract and check embedded jars
                    $extractPath = Join-Path $tempDir ([System.IO.Path]::GetFileNameWithoutExtension($mod.FileName))
                    if (Test-Path $extractPath) { Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue }
                    New-Item -ItemType Directory -Path $extractPath | Out-Null

                    try { [System.IO.Compression.ZipFile]::ExtractToDirectory($mod.FilePath, $extractPath) } catch { continue }

                    $depPath = Join-Path $extractPath "META-INF\jars"
                    if (-not (Test-Path $depPath)) { continue }

                    foreach ($jar in @(Get-ChildItem -Path $depPath -File -ErrorAction SilentlyContinue)) {
                        $str = Check-Strings $jar.FullName
                        if ($str.Count -gt 0) {
                            [void]$unknown.Remove($mod)
                            $cheats.Add([PSCustomObject]@{ FileName=$mod.FileName; FilePath=$mod.FilePath; DepFileName=$jar.Name; StringsFound=@($str | Sort-Object) })
                        }
                    }
                }
            } finally {
                if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
            }
        }

        $script:allVerified   = @($verified)
        $script:allUnknown    = @($unknown)
        $script:allSuspicious = @($cheats)
        $script:totalFiles    = $total
        $script:scanPath      = $mods

        if ($chkHistory.Checked) {
            Add-HistoryEntry -Path $mods -Scanned $total -Verified $verified.Count -Unknown $unknown.Count -Suspicious $cheats.Count
        }

        Update-Cards
        Apply-FilterAndSort
        Set-Status "Scan complete  ✔" 100

        if ($chkPopups.Checked) {
            [System.Windows.Forms.MessageBox]::Show(
                "Scan complete.`n`nScanned:    $total`nVerified:   $($verified.Count)`nUnknown:    $($unknown.Count)`nSuspicious: $($cheats.Count)",
                "TESLAPRO","OK","Information") | Out-Null
        }

        if ($chkAutoRes.Checked -or $chkOpenAfter.Checked) { Show-Page "Results" }

    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)","TESLAPRO","OK","Error") | Out-Null
        $statusLbl.Text = "Error during scan."
    } finally {
        foreach ($b in @($btnScan,$btnBrowse,$btnClear,$btnRescan)) { $b.Enabled = $true }
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
}

# =========================
# Events
# =========================

$btnDashboard.Add_Click({ Show-Page "Dashboard" })
$btnScan.Add_Click({      Show-Page "Scan" })
$btnResults.Add_Click({   Show-Page "Results" })
$btnHistory.Add_Click({   Show-Page "History" })
$btnSettings.Add_Click({  Show-Page "Settings" })

$btnDashScan.Add_Click({    Show-Page "Scan" })
$btnDashResults.Add_Click({ Show-Page "Results" })
$btnDashExport.Add_Click({  Export-Results "TXT" })

$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select mods folder"
    if ($dlg.ShowDialog() -eq "OK") { $pathBox.Text = $dlg.SelectedPath }
})

$btnScan.Add_Click({ Start-Scan })
$btnRescan.Add_Click({ Start-Scan })
$btnClear.Add_Click({ Clear-Results })

$searchBox.Add_TextChanged({ Apply-FilterAndSort })
$catCombo.Add_SelectedIndexChanged({ Apply-FilterAndSort })
$sortCombo.Add_SelectedIndexChanged({ Apply-FilterAndSort })
$chkOnlyDl.Add_CheckedChanged({ Apply-FilterAndSort })

$gridV.Add_SelectionChanged({
    if ($gridV.SelectedRows.Count -gt 0) {
        $r = $gridV.SelectedRows[0]
        $detailBox.Text = "VERIFIED  |  Mod: $($r.Cells[0].Value)  |  File: $($r.Cells[1].Value)  |  Source: $($r.Cells[2].Value)"
    }
})
$gridU.Add_SelectionChanged({
    if ($gridU.SelectedRows.Count -gt 0) {
        $r = $gridU.SelectedRows[0]
        $detailBox.Text = "UNKNOWN  |  File: $($r.Cells[0].Value)  |  Downloaded from: $($r.Cells[1].Value)"
    }
})
$gridS.Add_SelectionChanged({
    if ($gridS.SelectedRows.Count -gt 0) {
        $r = $gridS.SelectedRows[0]
        $detailBox.Text = "SUSPICIOUS  |  File: $($r.Cells[0].Value)  |  Embedded JAR: $($r.Cells[1].Value)  |  Matches: $($r.Cells[2].Value)"
    }
})

$btnOpenLoc.Add_Click({
    $fileName = $null
    if      ($resultsTabs.SelectedTab -eq $tabV -and $gridV.SelectedRows.Count -gt 0) { $fileName = [string]$gridV.SelectedRows[0].Cells[1].Value }
    elseif  ($resultsTabs.SelectedTab -eq $tabU -and $gridU.SelectedRows.Count -gt 0) { $fileName = [string]$gridU.SelectedRows[0].Cells[0].Value }
    elseif  ($resultsTabs.SelectedTab -eq $tabS -and $gridS.SelectedRows.Count -gt 0) { $fileName = [string]$gridS.SelectedRows[0].Cells[0].Value }

    if ($fileName -and $script:scanPath) {
        $full = Join-Path $script:scanPath $fileName
        if (Test-Path $full) { Start-Process explorer.exe "/select,`"$full`"" }
        else { [System.Windows.Forms.MessageBox]::Show("File not found.","TESLAPRO","OK","Information") | Out-Null }
    } else { [System.Windows.Forms.MessageBox]::Show("No file selected.","TESLAPRO","OK","Information") | Out-Null }
})

$btnCopyMat.Add_Click({
    if ($resultsTabs.SelectedTab -eq $tabS -and $gridS.SelectedRows.Count -gt 0) {
        $txt = [string]$gridS.SelectedRows[0].Cells[2].Value
        if ($txt) { [System.Windows.Forms.Clipboard]::SetText($txt); [System.Windows.Forms.MessageBox]::Show("Copied.","TESLAPRO","OK","Information") | Out-Null; return }
    }
    [System.Windows.Forms.MessageBox]::Show("Select a suspicious entry first.","TESLAPRO","OK","Information") | Out-Null
})

$exportDd.DropDownItems[0].Add_Click({ Export-Results "TXT" })
$exportDd.DropDownItems[1].Add_Click({ Export-Results "CSV" })
$exportDd.DropDownItems[2].Add_Click({ Export-Results "JSON" })

# =========================
# Init
# =========================

Show-Page "Dashboard"
Update-Cards

if ($chkAutoScan.Checked) { Start-Scan }

[void]$form.ShowDialog()
