<# :
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (${%~f0} | Out-String)"
pause
exit /b
#>

# --- EVERYTHING BELOW IS PURE POWERSHELL ---
$Host.UI.RawUI.ForegroundColor = 'DarkYellow'
$Host.UI.RawUI.BackgroundColor = 'Black'
Clear-Host

Write-Host ">> DIRECTORY STRUCTURE <<" -ForegroundColor Yellow

# Your logic

function Show-Tree {
    param(
        [string]$Path = ".",
        [string]$Prefix = ""
    )

    $items = Get-ChildItem -LiteralPath $Path | Sort-Object Name
    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        $isLast = ($i -eq $items.Count - 1)

        $connector = if ($isLast) { "+-- " } else { "|-- " }
        Write-Host "$Prefix$connector$item"

        if ($item.PSIsContainer) {
            $newPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix|   " }
            Show-Tree -Path $item.FullName -Prefix $newPrefix
        }
    }
}

Show-Tree
