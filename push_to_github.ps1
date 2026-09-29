$ErrorActionPreference = 'Stop'
$expectedRemote = 'https://github.com/santrimanofficial26-oss/WEBSITEPGRIMATRAMAN.git'
$repoPath = (Resolve-Path -LiteralPath $PSScriptRoot).Path

function Run-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    & git -C $repoPath @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Git gagal (exit $LASTEXITCODE): git $($GitArgs -join ' ')"
    }
}

try {
    Write-Host '==================================================' -ForegroundColor Cyan
    Write-Host '  PGRI MATRAMAN — PUSH VERCEL WRAPPER TO GITHUB   ' -ForegroundColor Cyan
    Write-Host '==================================================' -ForegroundColor Cyan

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git belum terpasang atau belum tersedia di PATH sistem.'
    }

    # 1. Inisialisasi Git Repository jika belum ada
    $isGitRepo = $false
    try {
        $actualRoot = (& git -C $repoPath rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -eq 0 -and $actualRoot -and ([IO.Path]::GetFullPath($actualRoot.Trim()) -eq [IO.Path]::GetFullPath($repoPath))) {
            $isGitRepo = $true
        }
    } catch { $isGitRepo = $false }

    if (-not $isGitRepo) {
        Write-Host 'Inisialisasi repositori Git lokal (branch main)...' -ForegroundColor Yellow
        Run-Git init -b main
    }

    # Pastikan branch aktif adalah main
    $currentBranch = (& git -C $repoPath branch --show-current 2>$null)
    if (-not $currentBranch -or $currentBranch.Trim() -ne 'main') {
        & git -C $repoPath checkout -B main 2>$null
    }

    # 2. Periksa / Set Remote Origin
    $allRemotes = (& git -C $repoPath remote 2>$null)
    $hasOrigin = $false
    if ($allRemotes) {
        $remoteList = @($allRemotes -split "`r?`n" | Where-Object { $_.Trim() -ne '' })
        if ($remoteList -contains 'origin') {
            $hasOrigin = $true
        }
    }

    if (-not $hasOrigin) {
        Write-Host "Menambahkan remote origin: $expectedRemote" -ForegroundColor Yellow
        Run-Git remote add origin $expectedRemote
    } else {
        $currentUrl = (& git -C $repoPath remote get-url origin 2>$null)
        if ($currentUrl -and ($currentUrl.Trim().TrimEnd('/') -ne $expectedRemote.TrimEnd('/'))) {
            Write-Host "Memperbarui remote origin ke: $expectedRemote" -ForegroundColor Yellow
            Run-Git remote set-url origin $expectedRemote
        }
    }

    # 3. Stage All Files
    Write-Host 'Menyiapkan berkas Vercel Wrapper (git add -A)...' -ForegroundColor Cyan
    Run-Git add -A

    # 4. Commit Changes
    & git -C $repoPath diff --cached --quiet
    if ($LASTEXITCODE -eq 1) {
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $commitMsg = "Deploy Vercel Iframe Wrapper PGRI Matraman $stamp"
        Write-Host "Membuat commit: $commitMsg" -ForegroundColor Yellow
        Run-Git commit -m $commitMsg
    } elseif ($LASTEXITCODE -eq 0) {
        Write-Host 'Semua berkas sudah up-to-date (tidak ada perubahan baru untuk di-commit).' -ForegroundColor Yellow
    } else {
        throw 'Gagal memeriksa status staged diff.'
    }

    # 5. Push ke GitHub
    Write-Host "Mengirim (git push) ke remote GitHub ($expectedRemote)..." -ForegroundColor Cyan
    
    # Cek apakah remote sudah memiliki riwayat branch main
    $remoteCheck = (& git -C $repoPath ls-remote --heads origin main 2>$null)
    if ($remoteCheck) {
        # Remote ada commits, coba push reguler atau rebase jika perlu
        try {
            Run-Git push -u origin main
        } catch {
            Write-Host 'Mencoba menarik pembaruan remote terlebih dahulu (git pull --rebase)...' -ForegroundColor Yellow
            Run-Git pull origin main --rebase
            Run-Git push -u origin main
        }
    } else {
        # Remote masih kosong / fresh
        Run-Git push -u origin main
    }

    Write-Host '==================================================' -ForegroundColor Green
    Write-Host '  SUKSES! Wrapper Vercel berhasil di-push ke GitHub!' -ForegroundColor Green
    Write-Host "  Repository URL: $expectedRemote" -ForegroundColor Green
    Write-Host '==================================================' -ForegroundColor Green

} catch {
    Write-Host '==================================================' -ForegroundColor Red
    Write-Host "GAGAL: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host '==================================================' -ForegroundColor Red
    exit 1
}
