param (
    [Parameter(Mandatory=$true)]
    [string]$arch
)

Push-Location

Set-Location -Path $PSScriptRoot

$config = Get-Content -Path (Join-Path $PSScriptRoot "config.json") | ConvertFrom-Json

function Move-Result($Source, $CurInput)
{
    $Name = "NO_EXCEPTION"
    $Class = "NOT_CLASSIFIED"
    foreach($r in $Source)
    {

        $json = Get-Content -Path $r.FullName | ConvertFrom-Json
        $Name = $json.EXCEPTION_TYPE + "_" + $json.MAJOR_HASH + "." + $json.MINOR_HASH
        $Class = $json.CLASSIFICATION
        $Destination = Join-Path $config.out $Class

        if( !(Test-Path -Path $Destination) )#Check Classification Directory exists
        {
            New-Item -Path $Destination -ItemType Directory
        }

        $Destination = Join-Path $Destination $Name

        if( !(Test-Path -Path $Destination) )#Check Type_Major_Minor directory exists
        {
            New-Item -Path $Destination -ItemType Directory
        }

        $dst = Join-Path $Destination ($CurInput.Basename + "_" + $r.Name)

        Move-Item -Force -Destination $dst $r.FullName

        if($config.dump -and (Test-Path -Path $r.FullName.replace(".json", ".dmp")))
        {
            $dst = Join-Path $Destination ($CurInput.Basename + "_" + $r.Basename + ".dmp")
			if((Get-ChildItem -Path $Destination -Filter "*.dmp").length -eq 0){
				Move-Item -Force -Destination $dst $r.FullName.replace(".json", ".dmp")
			}
			else{
				Get-Item -Path $r.FullName.replace(".json", ".dmp") | Remove-Item
			}
            
        }

    }

    $Destination = Join-Path $config.out $Class
    if( !(Test-Path -Path $Destination) )#Check Classification Directory exists
    {
        New-Item -Path $Destination -ItemType Directory
    }
    $Destination = Join-Path $Destination $Name
    if( !(Test-Path -Path $Destination) )
    {
        New-Item -Path $Destination -ItemType Directory
    }
    Copy-Item -Path $CurInput.Fullname -Destination $Destination

}



if($arch -ne "x64" -and $arch -ne "x86"){
    Write-Host "-arch must be x64 or x86"
    Exit
}

if(Test-Path -Path (Join-Path $PSScriptRoot "result\"))
{
    $result = (Get-ChildItem -Path $PSScriptRoot -Filter ".json")
    if($result.length -ne 0) 
    {
        $result.Delete($true)
    }
}

New-Item -ItemType "directory" -Path $PSScriptRoot -Name "result" -Force

$DbgShellPath = Join-Path $PSScriptRoot "DbgShell\$arch"
$DbgShell = Join-Path $DbgShellPath "DbgShell.exe"
$ScriptPath = Join-Path $PSScriptRoot "debugger.ps1"

$inputs = Get-ChildItem $config.in 

if($config.args.IndexOf("@@") -eq -1){ #need args input
    Write-Error "@@ not found in $config.args, "
    Exit
}

Write-Host ("Total {0} inputs" -f $inputs.length)

$i = 0

foreach($input in $inputs)
{
    $prog = $i / $inputs.Length * 100
    Write-Progress -Activity "AutoMSEC" -PercentComplete $prog
    $i += 1
    $arg = $config.args.replace('@@', $input.FullName)
    $arg | Out-File -FilePath (Join-Path $PSScriptRoot ".\args.txt")
    $debugger = (Start-Process -FilePath $DbgShell -PassThru -ArgumentList $ScriptPath -NoNewWindow)
    try
    {
        Wait-Process -Id $debugger.id -Timeout 10 -ErrorAction Stop
        $results = Get-ChildItem -Path (Join-Path $PSScriptRoot "result\") -Filter "*.json"
        Move-Result -CurInput $input -Source $results
    }
    catch [System.TimeoutException]
    {
        Write-Verbose "Debuggee Timeout"
        $debuggee = Get-Content "pid.txt"
        Write-Host $debuggee
        Stop-Process -Id $debuggee -Force
        Stop-Process -Id $debugger.id -Force
    }
    finally
    {
        Remove-Item -Path "pid.txt"
        $tmp = (Get-ChildItem -Path (Join-Path $PSScriptRoot "result"))
        if($tmp.length -ne 0)
        {
            $tmp.Delete()
        }
    }

<#
    if($results.Length -ne 0)
    {
        $Destination = Join-Path $config.out $Class
        Copy-Item -Path $input.Fullname -Destination (Join-Path $Destination $Name)
    }
#>
}

Pop-Location