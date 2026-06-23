# log.ps1 — logging helpers for the wth provisioning CLI (PowerShell twin).
function Write-WthInfo  { param([string]$Msg) Write-Host "[info]  $Msg" -ForegroundColor Blue }
function Write-WthOk    { param([string]$Msg) Write-Host "[ ok ]  $Msg" -ForegroundColor Green }
function Write-WthWarn  { param([string]$Msg) Write-Host "[warn]  $Msg" -ForegroundColor Yellow }
function Write-WthErr   { param([string]$Msg) Write-Host "[fail]  $Msg" -ForegroundColor Red }
function Write-WthPlan  { param([string]$Msg) Write-Host "[plan]  $Msg" -ForegroundColor DarkGray }
function Write-WthStep  { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Stop-Wth       { param([string]$Msg) Write-WthErr $Msg; exit 1 }
