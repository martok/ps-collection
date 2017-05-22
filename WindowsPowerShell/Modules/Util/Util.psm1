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

function Split-Pathspec
{
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]$PathSpec
)

    return $PathSpec | Select-String -Pattern '("[^"]+"|[^"][^;]+)(?:;|$)' -AllMatches | % {$_.matches} | % { $_.groups.Captures[1].Value }
}

function Test-PathInList ([string[]]$paths, [string]$path)
{
    $path = $path -replace "\\$", ""

    return ( ($paths -contains $path) -or ($paths -contains $path+'\') )
}

function Prepend-Path ([string[]]$paths, [string]$path)
{
    $path = $path -replace "\\$", ""

    if ( Test-PathInList $paths $path ) {
        return $paths
    } else {
        return @( $path ) + $paths
    }
}

function Prepend-Envvar ([string]$var, [string]$varscope, [string]$path)
{
    $paths = [Environment]::GetEnvironmentVariable($var,$varscope) | Split-Pathspec
    $paths = Prepend-Path $paths $myPath
    $path = $paths -join ';'
    [Environment]::SetEnvironmentVariable($var, $path, $varscope)
}