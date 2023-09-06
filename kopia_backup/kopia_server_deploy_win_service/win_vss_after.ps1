if ($args.Length -eq 0) {
    $kopiaSnapshotId = $env:KOPIA_SNAPSHOT_ID
} else {
    $kopiaSnapshotId = $args[0]
}

if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $mountPoint = Get-Item "${PSScriptRoot}\${kopiaSnapshotId}"
    $mountedVolume = $mountPoint.Target

    cmd /c rmdir $mountPoint
    Get-CimInstance -ClassName Win32_ShadowCopy | Where-Object { "$($_.DeviceObject)\" -eq "\\?\${mountedVolume}" } | Remove-CimInstance
} else {
    Start-Process 'powershell' '-f', $MyInvocation.MyCommand.Path, $kopiaSnapshotId -Verb RunAs -WindowStyle Hidden -Wait
    if ($proc.ExitCode) {
        exit $proc.ExitCode
    }
}
