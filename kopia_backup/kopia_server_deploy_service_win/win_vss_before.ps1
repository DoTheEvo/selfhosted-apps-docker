if ($args.Length -eq 0) {
    $kopiaSnapshotId = $env:KOPIA_SNAPSHOT_ID
    $kopiaSourcePath = $env:KOPIA_SOURCE_PATH
} else {
    $kopiaSnapshotId = $args[0]
    $kopiaSourcePath = $args[1]
}

$sourceDrive = Split-Path -Qualifier $kopiaSourcePath
$sourcePath = Split-Path -NoQualifier $kopiaSourcePath
# use Kopia snapshot ID as mount point name for extra caution for duplication
$mountPoint = "${PSScriptRoot}\${kopiaSnapshotId}"

if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $shadowId = (Invoke-CimMethod -ClassName Win32_ShadowCopy -MethodName Create -Arguments @{ Volume = "${sourceDrive}\" }).ShadowID
    $shadowDevice = (Get-CimInstance -ClassName Win32_ShadowCopy | Where-Object { $_.ID -eq $shadowId }).DeviceObject
    if (-not $shadowDevice) {
        # fail the Kopia snapshot early if shadow copy was not created
        exit 1
    }

    cmd /c mklink /d $mountPoint "${shadowDevice}\"
} else {
    $proc = Start-Process 'powershell' '-f', $MyInvocation.MyCommand.Path, $kopiaSnapshotId, $kopiaSourcePath -PassThru -Verb RunAs -WindowStyle Hidden -Wait
    if ($proc.ExitCode) {
        exit $proc.ExitCode
    }
}

Write-Output "KOPIA_SNAPSHOT_PATH=${mountPoint}${sourcePath}"
