param (
    [Parameter(Mandatory=$true)]
    [string]$arch
)

$config = Get-Content -Path (Join-Path $PSScriptRoot "config.json") | ConvertFrom-Json
if($arch -ne "x64" -and $arch -ne "x86"){
    Write-Host "-arch must be x64 or x86"
    Exit
}

$DbgShellPath = Join-Path $PSScriptRoot "DbgShell\$arch"
$DbgShell = Join-Path $DbgShellPath "DbgShell.exe"
$ScriptPath = Join-Path $PSScriptRoot "debugger.ps1"

$inputs = Get-ChildItem $config.in 
$cmdlines = [System.Collections.ArrayList]::new()

Write-Host $inputs
Write-Host "Crashed Testcases"
if($config.cmdline.IndexOf("@@") -ne -1){ #need args input
    for ($i = 0; $i -le $inputs.Length - 1; $i += 1){
        $cmdlines.Add(
            $config.cmdline.replace('@@', $inputs[$i].FullName)
        )
    }
}

Write-Host $cmdlines

#$debugger = (Start-Process -FilePath $Dbgshell -PassThru -ArgumentList $ScriptPath).Id

#Write-Host $debugger 