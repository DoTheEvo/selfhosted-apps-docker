$NasName = "NAS-2"
$Excluded = @("something1", "something2") # skip these shares

$env:KOPIA_CONFIG_PATH = "C:\Kopia\repository.config"

# Get list of shares from the NAS
$Shares = net view "\\$NasName" | ForEach-Object {
    if ($_ -match '^(\S+)\s+Disk\s') {
        $matches[1]
    }
} | Where-Object { $_ -notin $Excluded }

# Get list of Kopia policies and their UNC paths
# Filters out the global policy which has an empty path.
$KopiaPolicyPaths = kopia policy list --json | ConvertFrom-Json | ForEach-Object { $_.target.path } | Where-Object { $_ }

Write-Host "======   checking for new shares to add   ======"

Write-Host "..."
foreach ($Share in $Shares) {
    $UncPath = "\\$NasName\$Share"

    # Check whether share has a kopia policy defined
    $HasPolicy = $KopiaPolicyPaths | Where-Object { $_ -ieq $UncPath }

    if (-not $HasPolicy) {
        Write-Host "$UncPath - creating a new policy"

        # Temporarily relax EAP as Kopia writes information messages in to stderr
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = "Continue"

        # Kopia requires at least one flag explicitly defined
        $output = kopia policy set $UncPath --keep-latest inherit 2>&1

        $ErrorActionPreference = $prevEAP

        # Exit code is the real success/failure signal not the stderr
        # non-zero here means Kopia genuinely failed.
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to set policy for $UncPath (exit code $LASTEXITCODE): $output"
        }
    }
}
Write-Host "..."
Write-Host "==============   check  done   ================"
Write-Host ""
Write-Host "=============   current policies   ============="

kopia policy list --json | ConvertFrom-Json | ForEach-Object { $_.target.path } | Where-Object { $_ }

Write-Host ""
Write-Host "=============   ignored shares   ==============="
$Excluded | ForEach-Object { "\\$NasName\$_" }
