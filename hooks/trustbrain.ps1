# TrustBrain hooks for Windows (https://github.com/NeuralTrust/trustbrain-plugin):
# sends a coding agent's hook event to TrustBrain and prints what it answers.
# Usage: powershell -NoProfile -File trustbrain.ps1 <client> <event>
param([string]$Client = "claude", [string]$Event = "")
$ErrorActionPreference = "SilentlyContinue"
$TbUrl = if ($env:TRUSTBRAIN_URL) { $env:TRUSTBRAIN_URL } else { "https://brain.neuraltrust.ai" }
$Dir = if ($env:TRUSTBRAIN_HOME) { $env:TRUSTBRAIN_HOME } else { Join-Path $HOME ".trustbrain" }
$TokenFile = Join-Path $Dir "token-$Client"
$Pending = Join-Path $Dir "pending-$Client"
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

function Nothing {
  switch ($Event) {
    { $_ -in "Stop", "SubagentStop", "stop", "afterAgentResponse", "afterMCPExecution", "afterShellExecution", "afterFileEdit", "sessionStart" } { Write-Output "{}" }
    "beforeSubmitPrompt" { Write-Output '{"continue":true}' }
  }
  exit 0
}

$InputJson = [Console]::In.ReadToEnd()
$Wait = switch ($Event) { { $_ -in "UserPromptSubmit", "beforeSubmitPrompt" } { 2 } { $_ -in "SessionStart", "sessionStart" } { 5 } default { 20 } }

if (-not (Test-Path $TokenFile) -and (Test-Path $Pending)) {
  try {
    $r = Invoke-RestMethod -Method Post -Uri "$TbUrl/hooks/device/token" -ContentType "application/json" `
      -Body (@{ device_code = (Get-Content $Pending -Raw).Trim() } | ConvertTo-Json) -TimeoutSec 5
    if ($r.access_token) { Set-Content -Path $TokenFile -Value $r.access_token -NoNewline; Remove-Item $Pending }
  } catch {}
}
if (-not (Test-Path $TokenFile)) {
  if ($Event -notin "SessionStart", "sessionStart", "UserPromptSubmit") { Nothing }
  if ((Test-Path $Pending) -and ((Get-Item $Pending).LastWriteTime -gt (Get-Date).AddMinutes(-14))) { Nothing }
  try {
    $resp = Invoke-WebRequest -Method Post -Uri "$TbUrl/hooks/device/code?client=$Client&event=$Event" -ContentType "application/json" `
      -Body (@{ device = $env:COMPUTERNAME } | ConvertTo-Json) -TimeoutSec 5 -UseBasicParsing
    $code = $resp.Headers["X-TrustBrain-Device-Code"]
    if ($code) { Set-Content -Path $Pending -Value $code -NoNewline }
    Write-Output $resp.Content
  } catch {}
  exit 0
}

$Token = (Get-Content $TokenFile -Raw).Trim()
# Only the repository's address: credentials in it (https://user:token@...) stay here.
$Remote = (git remote get-url origin 2>$null) -replace '://[^/@]*@', '://'
try {
  $resp = Invoke-WebRequest -Method Post -Uri "$TbUrl/hooks/$Client/$Event" -ContentType "application/json" -Body $InputJson `
    -Headers @{ Authorization = "Bearer $Token"; "X-TrustBrain-Repo" = "$Remote" } -TimeoutSec $Wait -UseBasicParsing
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 401) { Remove-Item $TokenFile }
  Nothing
}
$From = $resp.Headers["X-TrustBrain-Send-From"]
$Session = $resp.Headers["X-TrustBrain-Session"]
if ($From -and $Session) {
  $Transcript = ($InputJson | ConvertFrom-Json).transcript_path
  if ($Transcript -and (Test-Path $Transcript)) {
    $Lines = Get-Content $Transcript | Select-Object -Skip ([int]$From)
    try {
      Invoke-WebRequest -Method Post -Uri "$TbUrl/hooks/$Client/transcript?session=$Session&from=$From" -ContentType "application/x-ndjson" `
        -Body ($Lines -join "`n") -Headers @{ Authorization = "Bearer $Token" } -TimeoutSec 30 -UseBasicParsing | Out-Null
    } catch {}
  }
}
if ($resp.Content) { Write-Output $resp.Content } else { Nothing }
