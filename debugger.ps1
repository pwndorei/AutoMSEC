<#BreakCode = 2147483651 #>
$ExitEvent = "ProcessExitedEventArgs"
$ExceptionEvent = "ExceptionEventArgs"
$BreakExceptionCode = 2147483651 #ignore this code
$ResultPath = Join-Path $PSScriptRoot "result\"


$config = Get-Content -Path (Join-Path $PSScriptRoot "config.json") | ConvertFrom-Json
$arg = Get-Content -Path (Join-Path $PSScriptRoot "args.txt")

Push-Location

Set-Location -Path $PSScriptRoot

function Check-DumpLevel($Class, $CurLevel)
{
    begin
    {
        $DumpLevel = @("EXPLOITABLE", "PROBABLY_EXPLOITABLE", "PROBABLY_NOT_EXPLOITABLE", "UNKNOWN")
    }
    process
    {
        return ($DumpLevel.IndexOf($Class)+1) -le $CurLevel
    }
}



function Save-Exception($Exception, $ExceptionCount)
{
    Write-Verbose "Exception Occured"
    if($Exception.ExceptionCode -eq $BreakExceptionCode)
    {
        return
    }

    $hashtable = @{}

    foreach($line in !exploitable -m){
        $idx = $line.IndexOf(":")

        if($idx -eq -1)
        {
            continue
        }
        $line = $line -split ":"
        $hashtable[$line[0]] = $line[1]
    }

    $hashtable | ConvertTo-Json | Out-File -FilePath (Join-Path $ResultPath "$ExceptionCount.json")

    try
    {
        if($config.dump)
        {
            if(Check-DumpLevel -Class $hashtable['CLASSIFICATION'] -CurLevel $config.dump_level)
            {
                .dump (Join-Path $ResultPath "$ExceptionCount.dmp")
            }
        }
        
    }
    catch
    {
        Write-Host $json
        Write-Host $_
    }
}


$Debuggee = (Start-Process -PassThru -FilePath $config.executable -WindowStyle Hidden -ArgumentList $arg -WorkingDirectory $PSScriptRoot)

$Debuggee.Id | Out-File -FilePath "pid.txt"

Connect-Process -Id $Debuggee.Id

if($Debugger.TargetIs32Bit){
    .load (Join-Path $PSScriptRoot "MSEC_x86.dll")
}

else{
    .load (Join-Path $PSScriptRoot "MSEC_x64.dll")
}

$ExceptionCount = 0

:DEBUG While($true){
    $events = g
    foreach($e in $events){
        switch($e.GetType().Name)
        {
            $ExitEvent {break DEBUG}
            $ExceptionEvent
            {
                Save-Exception -Exception $e -ExceptionCount $ExceptionCount
                $ExceptionCount += 1
                if($e.IsFirstChance)
                {
                    break
                }
                break DEBUG
            }
        }
    }
}

exit