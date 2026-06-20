param(
    [string]$AddOnsDir
)

$ErrorActionPreference = "Stop"

$AddonDir = Split-Path -Parent $PSScriptRoot
if (-not $AddOnsDir) {
    $AddOnsDir = Split-Path -Parent $AddonDir
}

$LibsDir = Join-Path $AddonDir "Libs"
New-Item -ItemType Directory -Force -Path $LibsDir | Out-Null

$Libraries = @(
    @{
        Name = "LibStub"
        File = "LibStub.lua"
        Candidates = @(
            "ElvUI_Libraries\Game\Shared\LibStub",
            "BigWigs\Libs\LibStub",
            "Details\Libs\LibStub"
        )
    },
    @{
        Name = "CallbackHandler-1.0"
        File = "CallbackHandler-1.0.xml"
        Candidates = @(
            "ElvUI_Libraries\Game\Shared\CallbackHandler-1.0",
            "BigWigs\Libs\CallbackHandler-1.0",
            "Details\Libs\CallbackHandler-1.0"
        )
    },
    @{
        Name = "AceAddon-3.0"
        File = "AceAddon-3.0.xml"
        Candidates = @(
            "ElvUI_Libraries\Game\Shared\Ace3\AceAddon-3.0",
            "Details\Libs\AceAddon-3.0",
            "BigDebuffs\Libs\AceAddon-3.0"
        )
    },
    @{
        Name = "AceEvent-3.0"
        File = "AceEvent-3.0.xml"
        Candidates = @(
            "ElvUI_Libraries\Game\Shared\Ace3\AceEvent-3.0",
            "Details\Libs\AceEvent-3.0",
            "BigDebuffs\Libs\AceEvent-3.0"
        )
    },
    @{
        Name = "AceConsole-3.0"
        File = "AceConsole-3.0.xml"
        Candidates = @(
            "ElvUI_Libraries\Game\Shared\Ace3\AceConsole-3.0",
            "Details\Libs\AceConsole-3.0",
            "BigDebuffs\Libs\AceConsole-3.0"
        )
    },
    @{
        Name = "AceDB-3.0"
        File = "AceDB-3.0.xml"
        Candidates = @(
            "ElvUI_Libraries\Game\Shared\Ace3\AceDB-3.0",
            "Details\Libs\AceDB-3.0",
            "BigDebuffs\Libs\AceDB-3.0"
        )
    },
    @{
        Name = "LibWindow-1.1"
        File = "LibWindow-1.1.lua"
        Candidates = @(
            "Details\Libs\LibWindow-1.1",
            "WorldQuestTracker\libs\LibWindow-1.1"
        )
    }
)

function Get-LibrarySource($Library) {
    foreach ($candidate in $Library.Candidates) {
        $path = Join-Path $AddOnsDir $candidate
        if (Test-Path -LiteralPath (Join-Path $path $Library.File)) {
            return $path
        }
    }

    $match = Get-ChildItem -Path $AddOnsDir -Recurse -Filter $Library.File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notlike "$LibsDir*" -and
            $_.DirectoryName -like "*$($Library.Name)*"
        } |
        Select-Object -First 1

    if ($match) {
        return $match.DirectoryName
    }

    throw "Could not find $($Library.Name). Update another addon that embeds it, or install a packaged SpotiWoW zip."
}

$libsRoot = [System.IO.Path]::GetFullPath($LibsDir)

foreach ($library in $Libraries) {
    $source = Get-LibrarySource $library
    $target = Join-Path $LibsDir $library.Name
    $targetFull = [System.IO.Path]::GetFullPath($target)

    if (-not $targetFull.StartsWith($libsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to write outside Libs: $target"
    }

    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }

    Copy-Item -LiteralPath $source -Destination $target -Recurse
    Write-Host "Refreshed $($library.Name)"
}
