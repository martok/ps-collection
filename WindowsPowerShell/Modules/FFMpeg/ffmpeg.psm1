function Compress-Frames {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$basename,

        [parameter(Mandatory=$false)]
        [string]$mask
    )
    BEGIN {
        if (-not $mask) {
            $mask = $basename + "%05d.png"
        }
        $self = (Get-PSCallStack)[0].ScriptName
        $ffmpeg = Join-Path (Split-Path $self -Parent) "ffmpeg-bin\ffmpeg.exe"
    }
    PROCESS {
        Write-Output "In" (Get-Location).Path
        & $ffmpeg @('-y', '-f','image2', '-r','10', '-i',$mask, '-filter:v','crop=floor(in_w/2)*2:floor(in_h/2)*2:0:0', '-vcodec','h264', '-pix_fmt','yuv420p', '-b:v','15M', "${basename}.avi" )
        #-s 1280x720 
    }
}

# Video from Subdirs:
#PS> Get-ChildItem Ani* | % { Push-Location $_.BaseName; Compress-Frames "..\$($_.BaseName)" -mask "IMG%04d.png"; Pop-Location }