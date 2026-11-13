$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $root ".claude-plugin\marketplace.json"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "marketplace.json nao encontrado em $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$bundle = $manifest.plugins | Where-Object { $_.name -eq "gamedev" }

if (-not $bundle) {
    throw "Bundle 'gamedev' nao encontrado no manifesto"
}

$targets = @(
    (Join-Path $env:USERPROFILE ".config\opencode\skills"),
    (Join-Path $env:USERPROFILE ".gemini\config\skills")
)

foreach ($target in $targets) {
    New-Item -ItemType Directory -Force -Path $target | Out-Null

    $installed = 0
    foreach ($rel in $bundle.skills) {
        $src = Join-Path $root ($rel -replace "/", "\")
        $skillMd = Join-Path $src "SKILL.md"

        if (-not (Test-Path -LiteralPath $skillMd)) {
            Write-Warning "SKILL.md ausente, pulando: $rel"
            continue
        }

        $name = Split-Path -Leaf $rel
        $dst = Join-Path $target $name

        if (Test-Path -LiteralPath $dst) {
            Remove-Item -Recurse -Force -LiteralPath $dst
        }

        Copy-Item -Recurse -LiteralPath $src -Destination $dst
        $installed++
    }

    Write-Output "$installed skills instaladas em $target"
}
