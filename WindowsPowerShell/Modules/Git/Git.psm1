function Export-GitArchive {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true,ParameterSetName='targetPath')]
        [string]$Path,

        [parameter(Mandatory=$true,ParameterSetName='targetArchive')]
        [string]$Archive,

        [Switch]$Force
    )
    BEGIN {
        git log -n1 | Out-Null
        if ($LastExitCode -ne 0) { Throw "Not in a git directory!" }

        if ($Path) {
            $outp = (New-Item $Path -Force -Type Directory)
            if ((Get-ChildItem $outp *).Count -gt 0 -and -not $Force) { Throw "Target directory is not empty!" }
        }
        if ($Archive) {
            if ((Test-Path $Archive) -and -not $Force) { Throw "Target archive file already exists!" }
            $outp = New-TemporaryDirectory
        }
    }
    PROCESS {
        git checkout-index -a -f "--prefix=$($outp.FullName)\"
        (git ls-files) | Show-Progress -Activity "Fixing file timestamps" | % {
            (Get-ChildItem $outp $_).LastWriteTime=(git log --pretty=format:%cd -n 1 --date=iso $_)
        }
    }
    END {
        if ($Path) {
            Write-Host "Done with export to $($outp.FullName)"
        }
        if ($Archive) {
            Compress-Archive -Path $outp -DestinationPath $Archive -Force
            Write-Host "Created Archive $Archive"
            Remove-Item -Recurse $outp
        }
    }
}