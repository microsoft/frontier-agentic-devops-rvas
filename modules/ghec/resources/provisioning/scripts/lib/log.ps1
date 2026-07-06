# log.ps1 — logging helpers for the provisioning scripts (PowerShell twin).
function Write-GhecInfo  { param([string]$Msg) Write-Host "[info]  $Msg" -ForegroundColor Blue }
function Write-GhecOk    { param([string]$Msg) Write-Host "[ ok ]  $Msg" -ForegroundColor Green }
function Write-GhecWarn  { param([string]$Msg) Write-Host "[warn]  $Msg" -ForegroundColor Yellow }
function Write-GhecErr   { param([string]$Msg) Write-Host "[fail]  $Msg" -ForegroundColor Red }
function Write-GhecPlan  { param([string]$Msg) Write-Host "[plan]  $Msg" -ForegroundColor DarkGray }
function Write-GhecStep  { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Stop-Ghec       { param([string]$Msg) Write-GhecErr $Msg; exit 1 }
