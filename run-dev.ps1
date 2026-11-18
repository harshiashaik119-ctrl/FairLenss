<#
    FairLens local dev launcher (Windows PowerShell).
    No WSL, no bash required. Run this from the project root:

        .\run-dev.ps1

    Options:
        .\run-dev.ps1 -SkipInstall     # skip pip/npm install (faster on repeat runs)
        .\run-dev.ps1 -BackendOnly     # only start the FastAPI backend
        .\run-dev.ps1 -FrontendOnly    # only start the Vite frontend
#>

param(
    [switch]$SkipInstall,
    [switch]$BackendOnly,
    [switch]$FrontendOnly
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

function Start-Backend {
    Write-Host "== FairLens backend ==" -ForegroundColor Cyan
    Push-Location "$root\backend"

    if (-not (Test-Path ".venv")) {
        Write-Host "Creating Python virtual environment (.venv)..."
        python -m venv .venv
    }

    $venvPython = ".\.venv\Scripts\python.exe"

    if (-not $SkipInstall) {
        Write-Host "Installing backend dependencies..."
        & $venvPython -m pip install --upgrade pip | Out-Null
        & $venvPython -m pip install -r requirements.txt
    }

    if (-not (Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-Host "Created backend\.env from backend\.env.example"
        Write-Host "Edit backend\.env to add your MongoDB Atlas URI and Claude API key when ready." -ForegroundColor Yellow
    }

    $modelPath = "app\ml\models\evidence_confidence_model.joblib"
    if (-not (Test-Path $modelPath)) {
        Write-Host "Training the Evidence Confidence Model (one-time, a few seconds)..." -ForegroundColor Cyan
        try {
            & $venvPython -m app.ml.train_evidence_model
        } catch {
            Write-Host "Model training skipped (app will use the deterministic fallback instead)." -ForegroundColor Yellow
        }
    }

    Write-Host "Starting FastAPI on http://localhost:8000 ..." -ForegroundColor Green
    Start-Process -FilePath $venvPython -ArgumentList "-m uvicorn app.main:app --reload --port 8000" -NoNewWindow

    Pop-Location
}

function Start-Frontend {
    Write-Host "== FairLens frontend ==" -ForegroundColor Cyan
    Push-Location "$root\frontend"

    if (-not $SkipInstall) {
        Write-Host "Installing frontend dependencies..."
        npm install
    }

    Write-Host "Starting Vite dev server on http://localhost:5173 ..." -ForegroundColor Green
    npm run dev

    Pop-Location
}

if ($BackendOnly) {
    Start-Backend
    Write-Host "Backend running. Press Ctrl+C in its window to stop." -ForegroundColor Yellow
}
elseif ($FrontendOnly) {
    Start-Frontend
}
else {
    Start-Backend
    Start-Sleep -Seconds 2
    Start-Frontend
}
