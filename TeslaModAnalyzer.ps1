Clear-Host

$host.UI.RawUI.WindowTitle = "TESLAPRO Mod Analyzer"

function Write-Centered {
    param(
        [string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    try {
        $width = $Host.UI.RawUI.WindowSize.Width
    } catch {
        $width = 120
    }

    if (-not $width -or $width -lt 20) {
        $width = 120
    }

    $padding = [Math]::Max([Math]::Floor(($width - $Text.Length) / 2), 0)
    Write-Host (" " * $padding + $Text) -ForegroundColor $Color
}

function Write-Section {
    param(
        [string]$Title,
        [ConsoleColor]$Color = [ConsoleColor]::DarkCyan
    )

    Write-Host
    Write-Host ("=" * 78) -ForegroundColor DarkGray
    Write-Centered $Title $Color
    Write-Host ("=" * 78) -ForegroundColor DarkGray
}

function Normalize-Text {
    param(
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    return ($Text.ToLowerInvariant() -replace '[^a-z0-9]', '')
}

function Update-ProgressLine {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Yellow
    )

    Write-Host ("`r" + (" " * 140) + "`r") -NoNewline
    Write-Host $Message -ForegroundColor $Color -NoNewline
}

Write-Host
Write-Centered "████████╗███████╗███████╗██╗      █████╗ ██████╗ ██████╗  ██████╗ " Cyan
Write-Centered "╚══██╔══╝██╔════╝██╔════╝██║     ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗" Cyan
Write-Centered "   ██║   █████╗  ███████╗██║     ███████║██████╔╝██████╔╝██║   ██║" Cyan
Write-Centered "   ██║   ██╔══╝  ╚════██║██║     ██╔══██║██╔═══╝ ██╔═══╝ ██║   ██║" Cyan
Write-Centered "   ██║   ███████╗███████║███████╗██║  ██║██║     ██║     ╚██████╔╝" Cyan
Write-Centered "   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝      ╚═════╝ " Cyan
Write-Host
Write-Centered "TESLAPRO MOD ANALYZER" Yellow
Write-Centered "TESLAPRO | Discord = @teamwsf" DarkGray
Write-Host
Write-Host ("=" * 78) -ForegroundColor DarkGray
Write-Host

Write-Host "Enter path to the mods folder: " -NoNewline
Write-Host "(press Enter to use default)" -ForegroundColor DarkGray
$mods = Read-Host "PATH"
Write-Host

if (-not $mods) {
    $mods = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "Continuing with " -NoNewline
    Write-Host $mods -ForegroundColor White
    Write-Host
}

if (-not (Test-Path $mods -PathType Container)) {
    Write-Host "Invalid Path!" -ForegroundColor Red
    exit 1
}

$process = Get-Process javaw -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $process) {
    $process = Get-Process java -ErrorAction SilentlyContinue | Select-Object -First 1
}

if ($process) {
    try {
        $startTime = $process.StartTime
        $elapsedTime = (Get-Date) - $startTime

        Write-Section "{ Minecraft Uptime }" DarkCyan
        Write-Host "$($process.Name) PID $($process.Id) started at $startTime and running for $($elapsedTime.Hours)h $($elapsedTime.Minutes)m $($elapsedTime.Seconds)s" -ForegroundColor Gray
        Write-Host
    } catch {}
}

function Get-SHA1 {
    param (
        [string]$filePath
    )
    return (Get-FileHash -Path $filePath -Algorithm SHA1).Hash
}

function Get-ZoneIdentifier {
    param (
        [string]$filePath
    )

    try {
        $ads = Get-Content -Raw -Stream Zone.Identifier $filePath -ErrorAction SilentlyContinue
        if ($ads -match "HostUrl=(.+)") {
            return $matches[1]
        }
    } catch {}

    return $null
}

function Fetch-Modrinth {
    param (
        [string]$hash
    )

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
    param (
        [string]$hash
    )

    try {
        $response = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if (-not $response.error) {
            return $response.data
        }
    } catch {}

    return $null
}

$cheatStrings = @(
    "AimAssist",
    "AnchorTweaks",
    "AutoAnchor",
    "AutoCrystal",
    "AutoDoubleHand",
    "AutoHitCrystal",
    "AutoPot",
    "AutoTotem",
    "AutoArmor",
    "InventoryTotem",
    "Hitboxes",
    "JumpReset",
    "LegitTotem",
    "PingSpoof",
    "SelfDestruct",
    "ShieldBreaker",
    "TriggerBot",
    "Velocity",
    "AxeSpam",
    "WebMacro",
    "FastPlace",

    "illegalmodifications",
    "stringcleaner",
    "autoretotem",
    "autoinventorytotem",
    "smarttotem",
    "fasttotem",
    "totempredict",
    "armoroptimizer",
    "autogapple",
    "offhandmanager",
    "autoswap",
    "clickaimassist",
    "legitaimassist",
    "smoothaim",
    "adaptiveaim",
    "stickyaim",
    "autoclicker",
    "fakecps",
    "clicksimulation",
    "clickrandomizer",
    "aimrandomizer",
    "delayrandomizer",
    "attackdelay",
    "switchdelay",
    "attackinvisibles",
    "hitdelay",
    "nomissdelay",
    "delayedhit",
    "hitsync",
    "multipoint",
    "targetstrafe",
    "reach",
    "reachassist",
    "velocitycontrol",
    "antikb",
    "velocityboost",
    "speedmultiplier",
    "speedcontrol",
    "speeddelay",
    "verticalspeed",
    "horizontalspeed",
    "strafecontrol",
    "movementfix",
    "fastfall",
    "glidecontrol",
    "autowtap",
    "smartwtap",
    "autojumpreset",
    "autoswitch",
    "keepSprint",
    "sworddelay",
    "axedelay",
    "onlycritsword",
    "onlycritaxe",
    "autocrit",
    "critassist",
    "slotselection",
    "fakelag",
    "xray",
    "netheritefinder",
    "autoloot",
    "stoponkill",
    "genericautoanchor",
    "smartanchor",
    "anchorprediction",
    "anchorplacer",
    "anchormacro",
    "macroanchor",
    "crystalaura",
    "smartcrystal",
    "instantcrystal",
    "crystalprediction",
    "crystaloptimizer",
    "genericcrystaloptimizer",
    "cwcrystal",
    "autohitcrystal",
    "doubleglowstone",
    "autoshieldbreaker",
    "genericshieldbreaker",
    "disableshields",
    "genericdisableshield",
    "autopotrefill",
    "switchback",
    "equipdelay",
    "heightexpansion",
    "widthexpansion",
    "throwdelay",
    "donutsmpbypass",
    "blatantmode",
    "legitmode",
    "ghostmode",
    "bypassmode",
    "humanizer",
    "antisstool",
    "genericselfdestruct",
    "possibledestruct",
    "deleteusnjournal",
    "logcleaner",
    "attackplayers",
    "syracruseclient",
    "automace",
    "macedamage",
    "maceboost",
    "macecrit",
    "maceaura",
    "macevelocity",
    "macefallboost",
    "macekb",
    "macecombo",
    "maceassist",
    "maceaim",
    "macestrafe",
    "autopearl",
    "pearlcatch",
    "fastpearl",
    "pearlmacro",
    "pearlassist",
    "pearlprediction",
    "pearltracker",
    "pearlaim",
    "pearlthrow",
    "pearlspam",
    "antipearl",
    "pearlcancel",
    "pearlclutch"
) | Sort-Object -Unique

$normalizedCheatMap = @{}
foreach ($item in $cheatStrings) {
    $normalized = Normalize-Text $item
    if ($normalized -and -not $normalizedCheatMap.ContainsKey($normalized)) {
        $normalizedCheatMap[$normalized] = $item
    }
}

function Check-Strings {
    param (
        [string]$filePath
    )

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

$verifiedMods = @()
$unknownMods = @()
$cheatMods = @()

$jarFiles = Get-ChildItem -Path $mods -Filter *.jar -File -ErrorAction SilentlyContinue

if (-not $jarFiles -or $jarFiles.Count -eq 0) {
    Write-Section "{ Result }" DarkCyan
    Write-Host "No .jar files found in the selected folder." -ForegroundColor DarkYellow
    Write-Host
    exit 0
}

$spinner = @("|", "/", "-", "\")
$totalMods = $jarFiles.Count
$counter = 0

Write-Section "{ Hash Verification }" DarkCyan

foreach ($file in $jarFiles) {
    $counter++
    $spin = $spinner[$counter % $spinner.Length]
    Update-ProgressLine "[$spin] Scanning mods: $counter / $totalMods  ->  $($file.Name)" Yellow

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

Write-Host ("`r" + (" " * 140) + "`r") -NoNewline

if ($unknownMods.Count -gt 0) {
    Write-Section "{ Deep Scan }" DarkCyan

    $tempDir = Join-Path $env:TEMP "teslapromodanalyzer"
    $counter = 0

    try {
        if (Test-Path $tempDir) {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }

        New-Item -ItemType Directory -Path $tempDir | Out-Null
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        foreach ($mod in @($unknownMods)) {
            $counter++
            $spin = $spinner[$counter % $spinner.Length]
            Update-ProgressLine "[$spin] Deep scanning unknown mod: $counter / $($unknownMods.Count)  ->  $($mod.FileName)" Yellow

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
    } catch {
        Write-Host
        Write-Host "Error occurred while scanning jar files! $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        Write-Host ("`r" + (" " * 140) + "`r") -NoNewline
        if (Test-Path $tempDir) {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }
}

Write-Section "{ Scan Results }" DarkCyan

if ($verifiedMods.Count -gt 0) {
    Write-Host "[ VERIFIED MODS ]" -ForegroundColor Green
    foreach ($mod in $verifiedMods | Sort-Object ModName, FileName) {
        Write-Host ("> {0,-32}" -f $mod.ModName) -ForegroundColor Green -NoNewline
        Write-Host (" {0,-38}" -f $mod.FileName) -ForegroundColor Gray -NoNewline
        Write-Host (" [{0}]" -f $mod.Source) -ForegroundColor DarkGray
    }
    Write-Host
}

if ($unknownMods.Count -gt 0) {
    Write-Host "[ UNKNOWN MODS ]" -ForegroundColor DarkYellow
    foreach ($mod in $unknownMods | Sort-Object FileName) {
        if ($mod.ZoneId) {
            Write-Host ("> {0,-32}" -f $mod.FileName) -ForegroundColor DarkYellow -NoNewline
            Write-Host $mod.ZoneId -ForegroundColor DarkGray
        } else {
            Write-Host ("> {0}" -f $mod.FileName) -ForegroundColor DarkYellow
        }
    }
    Write-Host
}

if ($cheatMods.Count -gt 0) {
    Write-Host "[ SUSPICIOUS / CHEAT MODS ]" -ForegroundColor Red
    foreach ($mod in $cheatMods | Sort-Object FileName, DepFileName) {
        Write-Host "> $($mod.FileName)" -ForegroundColor Red -NoNewline
        if ($mod.DepFileName) {
            Write-Host " -> $($mod.DepFileName)" -ForegroundColor Magenta -NoNewline
        }
        Write-Host " [$([string]::Join(', ', $mod.StringsFound))]" -ForegroundColor DarkMagenta
    }
    Write-Host
}

if ($verifiedMods.Count -eq 0 -and $unknownMods.Count -eq 0 -and $cheatMods.Count -eq 0) {
    Write-Host "No results to display." -ForegroundColor DarkYellow
    Write-Host
}

Write-Host ("-" * 78) -ForegroundColor DarkGray
Write-Centered "SCAN COMPLETE | TESLAPRO" Cyan
Write-Host ("-" * 78) -ForegroundColor DarkGray
Write-Host