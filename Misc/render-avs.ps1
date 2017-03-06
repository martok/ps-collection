param ([string]$AVSName, [string]$VideoFile, [switch]$CheckOnly)
$self = (Get-PSCallStack)[0].ScriptName
$sd = Split-Path -Parent $self
$WAIT_TIMEOUT = 2000

# Expectes avisynth+avsproxy in .\avs\ and Avidemux in .\avidemux\
$env:Path = "$sd;$sd\avs;$sd\avidemux;$env:Path"

if ($CheckOnly) {
    $tf = New-TemporaryFile
    $avsproxy = Start-Process -PassThru avsproxy -ArgumentList "$AVSName" -RedirectStandardError $tf.FullName
    if ($avsproxy.WaitForExit($WAIT_TIMEOUT)) {
        $c = $avsproxy.ExitCode
        Write-Output "AVSProxy failed with code $c, check your script!"
        Get-Content -Path $tf.FullName | Write-Output
    } else {
        $avsproxy.Kill()
        $avsproxy.WaitForExit($WAIT_TIMEOUT)
        Write-Output "AVSProxy looks okay!"
    }
    Remove-Item $tf.FullName -Force

} else {
    $avsproxy = Start-Process -PassThru avsproxy -ArgumentList "$AVSName"

    if ($avsproxy.WaitForExit($WAIT_TIMEOUT)) {
        $c = $avsproxy.ExitCode
        Write-Error "AVSProxy failed with code $c, check your script!"
        return
    }

    Start-Process -Wait avidemux -ArgumentList "--load","$sd\avs\adm_adapt.avi","--run","$sd\avidem.py","--save","$VideoFile","--quit"
    Write-Output "Done!"
}
