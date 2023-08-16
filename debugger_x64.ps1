$config = Get-Content -Path (Join-Path $PSScriptRoot "config.json") | ConvertFrom-Json

foreach ($input in $config.in){
    Start-Process $config.program -ArgumentList $config.args -PassThru | Connect-Process
    .load (Join-Path $PSScriptRoot "MSEC_x64.dll")

    g

    !exploitable -v

    Read-Host
}

