<#BreakCode = 2147483651 #>
$ExitEvent = "ProcessExitedEventArgs"
$ExceptionEvent = "ExceptionEventArgs"
$BreakExceptionCode = 2147483651 #ignore this code
$ExceptionCount = 0
$ResultPath = Join-Path $PSScriptRoot "result\"


$config = Get-Content -Path (Join-Path $PSScriptRoot "config.json") | ConvertFrom-Json
$arg = Get-Content -Path (Join-Path $PSScriptRoot "args.txt")


function Save-Exception($Exception)
{
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

    $hashtable | ConvertTo-Json | Out-File -FilePath (Join-Path $ResultPath "result$ExceptionCount.json")
    $ExceptionCount += 1
}

$Debuggee = (Start-Process -PassThru -FilePath (Join-Path $PSScriptRoot $config.executable) -WindowStyle Hidden -ArgumentList $arg -WorkingDirectory $PSScriptRoot)

Connect-Process -Id $Debuggee.Id

if($Debugger.TargetIs32Bit){
    .load (Join-Path $PSScriptRoot "MSEC_x86.dll")
}

else{
    .load (Join-Path $PSScriptRoot "MSEC_x64.dll")
}


:DEBUG While($true){
    $events = g
    foreach($e in $events){
        switch($e.GetType().Name)
        {
            $ExitEvent {break DEBUG}
            $ExceptionEvent
            {
                Save-Exception -Exception $e
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