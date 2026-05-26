<# :
@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -Command "iex (${%~f0} | Out-String)"
pause
exit /b
#>

$Host.UI.RawUI.ForegroundColor = 'DarkYellow'
$Host.UI.RawUI.BackgroundColor = 'Black'
Clear-Host

Write-Host ">> GHOST DB DETECTOR <<" -ForegroundColor Yellow

# =========================
# GET AZURE SQL SERVERS
# =========================

$servers = az sql server list | ConvertFrom-Json

$items = foreach ($s in $servers) {
    [PSCustomObject]@{
        Name     = $s.name
        RG       = $s.resourceGroup
        Selected = $false
        Type     = "server"
    }
}

$items += [PSCustomObject]@{
    Name     = "GO"
    RG       = ""
    Selected = $false
    Type     = "go"
}

$cursor = 0
$exit = $false


# =========================
# UI
# =========================
function RenderMenu {

    Clear-Host
    Write-Host "Azure SQL Server Selector`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $items.Count; $i++) {

        $item = $items[$i]

        $prefix = if ($i -eq $cursor) { "-> " } else { "   " }
        $color = if ($i -eq $cursor) { "Yellow" } else { "White" }

        $star = if ($item.Type -eq "server" -and $item.Selected) { "*" } else { "" }

        if ($item.Type -eq "go") {
            Write-Host "$prefix GO" -ForegroundColor Green
        }
        else {
            Write-Host ("{0}{1}. {2} {3}" -f $prefix, ($i+1), $item.Name, $star) -ForegroundColor $color
        }
    }
}

# =========================
# Spinner
# =========================
function Show-Spinner($ScriptBlock) {

    $job = Start-Job $ScriptBlock

    $spinner = @('|','/','-','\')
    $i = 0

    while ($job.State -eq 'Running') {
        Write-Host -NoNewline "`rLoading Azure SQL servers... $($spinner[$i])"
        Start-Sleep -Milliseconds 150
        $i = ($i + 1) % $spinner.Length
    }

    Write-Host "`rLoading Azure SQL servers... Done!     " -ForegroundColor Green

    Receive-Job $job
    Remove-Job $job
}


# =========================
# UI LOOP
# =========================
while (-not $exit) {

    RenderMenu

    $key = [Console]::ReadKey($true)

    switch ($key.Key) {

        "UpArrow"   { if ($cursor -gt 0) { $cursor-- } }
        "DownArrow" { if ($cursor -lt $items.Count - 1) { $cursor++ } }

        "Enter" {
            $current = $items[$cursor]

            if ($current.Type -eq "go") {
                $exit = $true
                break
            }

            if ($current.Type -eq "server") {
                $items[$cursor].Selected = -not $items[$cursor].Selected
            }
        }
    }
}


# =========================
# SELECTED SERVERS
# =========================
$selectedServers = $items | Where-Object Selected

Clear-Host

Write-Host "`nSelected servers:`n" -ForegroundColor Green
$selectedServers | ForEach-Object { Write-Host $_.Name }

Read-Host "`nPress Enter to start scanning"


# =========================
# AZURE CONTEXT
# =========================
$subscriptionId = az account show --query id -o tsv
az account set --subscription $subscriptionId

$startTime = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssZ")
$endTime   = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

$inactiveCpu = 0.1
$inactiveDtu = 0.1


# =========================
# PARALLEL SCAN
# =========================
Write-Host "`nStarting PARALLEL scan..." -ForegroundColor Cyan

$results = $selectedServers | ForEach-Object -Parallel {

    $server = $_
    $out = @()

    Write-Host "`n[Server] $($server.Name)" -ForegroundColor Yellow

    $dbs = az sql db list -g $server.RG -s $server.Name | ConvertFrom-Json

    foreach ($db in $dbs) {

        if ($db.name -eq "master") { continue }

        Write-Host "   Checking DB: $($db.name)" -ForegroundColor DarkGray

        # ================= CPU =================
        $cpuMetrics = az monitor metrics list `
            --resource $db.id `
            --metric "cpu_percent" `
            --start-time $using:startTime `
            --end-time $using:endTime `
            --interval PT1H `
            -o json | ConvertFrom-Json

        $cpuAvg = 0
        if ($cpuMetrics.value -and $cpuMetrics.value[0].timeseries) {
            $cpuAvg = $cpuMetrics.value[0].timeseries[0].data |
                ForEach-Object { $_.average } |
                Where-Object { $_ -ne $null } |
                Measure-Object -Average |
                Select-Object -ExpandProperty Average
        }

        # ================= DTU =================
        $dtuMetrics = az monitor metrics list `
            --resource $db.id `
            --metric "dtu_consumption_percent" `
            --start-time $using:startTime `
            --end-time $using:endTime `
            --interval PT1H `
            -o json | ConvertFrom-Json

        $dtuAvg = 0
        if ($dtuMetrics.value -and $dtuMetrics.value[0].timeseries) {
            $dtuAvg = $dtuMetrics.value[0].timeseries[0].data |
                ForEach-Object { $_.average } |
                Where-Object { $_ -ne $null } |
                Measure-Object -Average |
                Select-Object -ExpandProperty Average
        }

        # default safety
        if (-not $cpuAvg) { $cpuAvg = 0 }
        if (-not $dtuAvg) { $dtuAvg = 0 }

        # ================= FILTER =================
        if ($cpuAvg -lt $using:inactiveCpu -and $dtuAvg -lt $using:inactiveDtu) {

            $out += [PSCustomObject]@{
                Server    = $server.Name
                Database  = $db.name
                AvgCPU30d = [math]::Round($cpuAvg,2)
                AvgDTU30d = [math]::Round($dtuAvg,2)
            }
        }
    }

    return $out

} -ThrottleLimit 5


# =========================
# FLATTEN RESULTS
# =========================
$unusedDbs = $results | Where-Object { $_ }


# =========================
# FINAL OUTPUT
# =========================
Write-Host "`n=============================="
Write-Host "UNUSED DATABASES (30 DAYS)"
Write-Host "==============================`n"

if ($unusedDbs.Count -eq 0) {
    Write-Host "No unused databases found." -ForegroundColor Green
}
else {
    $unusedDbs | Format-Table -AutoSize
}


# =========================
# EXPORT
# =========================
$file = "unused_sql_dbs_$(Get-Date -Format yyyyMMdd_HHmmss).csv"
$unusedDbs | Export-Csv $file -NoTypeInformation

Write-Host "`nExported: $file" -ForegroundColor Cyan
