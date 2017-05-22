param(
  [switch]$UserPath,

  [switch]$SystemPath
)

if ($UserPath) {
    $myPath = Join-Path -Path ([environment]::GetFolderPath(“mydocuments”)) -ChildPath 'WindowsPowerShell\Modules'

    if ( -not (Test-PathInList (Split-Pathspec -PathSpec $env:PSModulePath) $myPath) ) {
        Prepend-Envvar "PSModulePath" "User" $myPath
        Write-Host "$myPath Added to user PSModulePath"
    } else {
        Write-Host "$myPath already in effective PSModulePath, not re-adding"
    }
}

if ($SystemPath) {
    $mypath = "C:\System\PSModules"
    mkdir -Force $myPath

    $acl = Get-Acl -Path $myPath

    $objUser = New-Object System.Security.Principal.NTAccount("${env:USERDOMAIN}\${env:USERNAME}")
    $ownerSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])

    $sddl = "O:" + $ownerSID + "G:DUD:PAI(A;OICI;FA;;;CO)(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200af;;;BU)"

    $acl.SetSecurityDescriptorSddlForm($sddl)
    Set-Acl -Path $myPath -AclObject $acl


    if ( -not (Test-PathInList (Split-Pathspec -PathSpec $env:PSModulePath) $myPath) ) {
        Prepend-Envvar "PSModulePath" "Machine" $myPath
        Write-Host "$myPath Added to machine PSModulePath"
    } else {
        Write-Host "$myPath already in effective PSModulePath, not re-adding"
    }
}

