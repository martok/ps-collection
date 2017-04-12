# Source: http://stackoverflow.com/a/34559554
function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    return New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

# Based on http://stackoverflow.com/q/33300508/3280879
function Show-Progress
{
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [PSObject[]]$InputObject,

    [Parameter(Mandatory=$true)]
    [String]$Activity
)

    [int]$TotItems = $Input.Count
    [int]$Count = 0

    $Input|foreach {
        $_
        $Count++
        [int]$PercentComplete = ($Count/$TotItems* 100)
        Write-Progress -Activity $Activity -PercentComplete $PercentComplete -Status ("Working - " + $PercentComplete + "%")
    }
}