$ErrorActionPreference = "Stop"

$files = @(
    "docs/latex-overview.html",
    "docs/simu2-overview.html",
    "docs/embedded-overview.html",
    "docs/tese-analyzes.html"
)

foreach ($file in $files) {
    if (!(Test-Path $file)) {
        throw "Missing $file"
    }

    $content = Get-Content -Raw $file

    if ($content -match "[{][{]|[}][}]") {
        throw "Unreplaced placeholder in $file"
    }

    if ($content -notmatch '<details class="chapter level-1"') {
        throw "No chapters found in $file"
    }
}
