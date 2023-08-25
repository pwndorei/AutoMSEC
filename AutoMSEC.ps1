param (
    [Parameter(Mandatory=$true)]
    [string]$arch
)

$config = Get-Content -Path (Join-Path $PSScriptRoot "config.json") | ConvertFrom-Json
if($arch -ne "x64" -and $arch -ne "x86"){
    Write-Host "-arch must be x64 or x86"
    Exit
}

if(Test-Path -Path (Join-Path $PSScriptRoot "result\"))
{
    (Get-ChildItem -Path $PSScriptRoot -Filter "result").Delete($true)
}

New-Item -ItemType "directory" -Path $PSScriptRoot -Name "result"

$DbgShellPath = Join-Path $PSScriptRoot "DbgShell\$arch"
$DbgShell = Join-Path $DbgShellPath "DbgShell.exe"
$ScriptPath = Join-Path $PSScriptRoot "debugger.ps1"

$inputs = Get-ChildItem $config.in 
$argslist = [System.Collections.ArrayList]::new()

Write-Host $inputs
Write-Host "Crashed Testcases"
if($config.args.IndexOf("@@") -ne -1){ #need args input
    for ($i = 0; $i -le $inputs.Length - 1; $i += 1){
        $argslist.Add(
            $config.args.replace('@@', $inputs[$i].FullName)
        )
    }
}

$argslist[180] | Out-File -FilePath "./args.txt"

$dpid = (Start-Process -FilePath $DbgShell -PassThru -ArgumentList $ScriptPath -NoNewWindow).Id
Wait-Process -Id $dpid

$results = Get-ChildItem -Path (Join-Path $PSScriptRoot "result\")

foreach($r in $results)
{
    $json = Get-Content -Path $r.FullName | ConvertFrom-Json

    $ExceptionType = $json['EXCEPTION_TYPE']

}