param (
    [Parameter(Mandatory=$true)]
    [string]$arch
)

$config = Get-Content -Path (Join-Path $PSScriptRoot "config.json") | ConvertFrom-Json

function Move-Result($Destination, $Name)
{
    if( !(Test-Path -Path $Destination) )
    {
        New-Item -Path $Destination -ItemType Directory
    }

    $Destination = Join-Path $Destination $Name

    if( !(Test-Path -Path $Destination) )
    {
        New-Item -Path $Destination -ItemType Directory
    }

    Get-ChildItem -File (Join-Path $PSScriptRoot "result\") | Move-Item -Destination $Destination 
}



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

if($config.args.IndexOf("@@") -eq -1){ #need args input
    Write-Error "@@ not found in $config.args, "
}

foreach($input in $inputs)
{
    $arg = $config.args.replace('@@', $input.FullName)
    $arg | Out-File -FilePath "./args.txt"
    $dpid = (Start-Process -FilePath $DbgShell -PassThru -ArgumentList $ScriptPath -NoNewWindow).Id
    Wait-Process -Id $dpid
    $results = Get-ChildItem -Path (Join-Path $PSScriptRoot "result\")

    foreach($r in $results)
    {
        $json = Get-Content -Path $r.FullName | ConvertFrom-Json

        $Name = $json.EXCEPTION_TYPE + "_" + $json.MAJOR_HASH + "." + $json.MINOR_HASH
        $Class = $json.CLASSIFICATION

        Move-Result -Destination (Join-Path $config.out $Class) -Name $Name

    }

    if($results.Length -ne 0)
    {
        $Destination = Join-Path $config.out $Class
        Move-Item -Path $input.Fullname -Destination (Join-Path $Destination $Name)
    }
}
