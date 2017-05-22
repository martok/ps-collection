param(
  [parameter(Mandatory=$True)]
  [string]$Save
)

Import-Module -Name PSTerminalServices

Push-Location "C:\System\tmp"
try {
    $msgInfo = Import-Clixml -Path $Save

    $params = @{Text = $msgInfo.Message }
    if (![string]::IsNullOrWhiteSpace($msgInfo.Title)) { $params.Caption = $msgInfo.Title }
    Get-TSCurrentSession | Where -Property UserName -NE "" | Send-TSMessage @params
} finally {
    Pop-Location
}