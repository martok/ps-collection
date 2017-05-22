param(
  [parameter(Mandatory=$True,ParameterSetName="Disable")]
  [switch]$Disable,

  [parameter(Mandatory=$True,ParameterSetName="Enable")]
  [string]$Message,
  [parameter(Mandatory=$False,ParameterSetName="Enable")]
  [string]$Title = "Pending Restart...",

  [parameter(Mandatory=$True,ParameterSetName="Job")]
  [string]$JobMode
)

Import-Module -Name ScheduledTasks
Import-Module -Name PSTerminalServices

$JobNameLogin = "IWW_RestartLogon"
$JobNameMain = "IWW_RestartCheck"
$Debug = $PSBoundParameters.ContainsKey("Debug")

function New-PowershellTaskAction([string]$script, [string]$workdir, [string]$arguments)
{
    $sa = "-NoProfile -WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File ""$script"" $arguments"
    New-ScheduledTaskAction -WorkingDirectory $workdir -Execute "$PSHome\powershell.exe" -Argument $sa
}

function Delete-Oldtasks
{
    Get-ScheduledTask | Where -Property TaskName -In ($JobNameLogin, $JobNameMain) | Unregister-ScheduledTask -Confirm:$false
}

mkdir -Force "C:\System\tmp"
Push-Location "C:\System\tmp"
try{
    if ($JobMode) {
        $pendingObj = Import-Clixml -Path $JobMode
        $users = (Get-TSSession | Where -Property UserName -NE "")

        if ($users.Count -gt 0) {
            # have interactive sessions, do nothing
            $names = $users.UserAccount -Join ", "
            Add-Content -Path "Shutdown.log" -Value "$(Get-Date -Format G): Not shutting down, have logged on users: $names"
        } else {
            # no sessions, clean up jobs and reboot
            Delete-Oldtasks
            Add-Content -Path "Shutdown.log" -Value "$(Get-Date -Format G): Restarting now, no users online!"
            Restart-Computer -Confirm:$false
        }
    } elseif ($Disable) {
        Delete-Oldtasks
        Remove-Item -Path "pending.xml" -Confirm:$False -Force 2> $null
        exit 0
    } else {
        # setup job to send to all new sessions
        $pendingObj = [PSCustomObject]@{
            Message = $Message;
            Title = $Title
        }
        Delete-Oldtasks
        $pendingObj | Export-Clixml -Depth 1 -Path "pending.xml"
        $trigger = New-ScheduledTaskTrigger -AtLogOn -RandomDelay (New-TimeSpan -Seconds 1)
        $action = New-PowershellTaskAction -script "Send-SavedMessage.ps1" -arguments "-Save pending.xml" -workdir $PSScriptRoot
        Register-ScheduledTask -TaskName $JobNameLogin -Trigger $trigger -Action $action

        # setup job to send to check if we can shutdown
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 100)
        $scriptSelf = (Get-PSCallStack)[0].ScriptName
        $action = New-PowershellTaskAction -script $scriptSelf -arguments "-JobMode pending.xml" -workdir $PSScriptRoot
        Register-ScheduledTask -TaskName $JobNameMain -Trigger $trigger -Action $action -User "System" -RunLevel Highest


        # send to all current sessions
        $params = @{Text = $Message }
        if (![string]::IsNullOrWhiteSpace($Title)) { $params.Caption = $Title }
        Get-TSSession | Where -Property UserName -NE "" | Send-TSMessage @params

        Write-Host "All setup and notified."
    }
} finally {
    Pop-Location
}

