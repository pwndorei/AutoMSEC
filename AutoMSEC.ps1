param (
    [Parameter(Mandatory=$true)]
    [string]$arch
)

if($arch -ne "x64" -and $arch -ne "x86"){
    Write-Host "-arch must be x64 or x86"
    Exit
}

$DbgShellPath = Join-Path $PSScriptRoot "DbgShell\$arch"
$DbgShell = Join-Path $DbgShellPath "DbgShell.exe"
$ScriptPath = Join-Path $PSScriptRoot "debugger_$arch.ps1"

Write-Host $DbgShellPath
Write-Host $DbgShell
Write-Host $ScriptPath

$debugger = (Start-Process -FilePath $Dbgshell -PassThru -ArgumentList $ScriptPath).Id

Write-Host $debugger 