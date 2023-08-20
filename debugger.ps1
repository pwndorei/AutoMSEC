<#BreakCode = 2147483651 #>

$msec = $PSScriptRoot
$config = Get-Content -Path (Join-Path $PSScriptRoot "config.json") | ConvertFrom-Json

$inputs = Get-ChildItem -Name $config.in

Write-Host $inputs
Write-Host "Crashed Testcases"
for ($i = 0; $i -le $inputs.Length - 1; $i += 1){
    $inputs[$i] = Join-Path $config.in $inputs[$i]
    $inputs[$i] = Join-Path $PSScriptRoot $inputs[$i]
    Write-Host $inputs[$i]
}

$Debuggee = (Start-Process -PassThru $config.program ).Id
$Debugger.SkipInitialBreakpoint = $true

Connect-Process $Debuggee

if($Debugger.TargetIs32Bit){
    $msec = Join-Path $msec "MSEC_x86.dll"
}
else{
    $msec = Join-Path $msec "MSEC_x64.dll"
}

.load $msec


function Start-Debuggee($testcase){
    $args_list = [System.Collections.ArrayList]::new()
    foreach ($arg in $config.args){
        if ($arg -eq "SEEDFILE") {$args_list.Add($testcase)}
        else {$args_list.Add($arg)}
    }
    Start-Process -PassThru $program -ArgumentList $args_list | Connect-Process
}


function Debug-UntilExit(){
    $result = [System.Collections.ArrayList]::new()
    :RUN while($true){
        $events = gn

        foreach ($e in $events){
            switch ($e.GetType().Name){
                "ProcessExitedEventArgs"{
                    break RUN
                }

                "ExceptionEventArgs" {
                    switch($e.ExceptionCode){
                        2147483651 {break} # Break Code
                        Default{
                            $analysis = !exploitable -v
                            $result.Add($analysis)
                        }
                    }
                    break
                }

            }
        }

    }
    .detach
    return $result
}


function Save-DebugOutput($outpath, $result){
    Out-File -FilePath $result
}