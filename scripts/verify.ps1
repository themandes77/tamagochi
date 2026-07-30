[CmdletBinding()]
param(
    [switch]$BuildAndroid
)

$ErrorActionPreference = "Stop"

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$CommandArguments
    )

    & $Command @CommandArguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE."
    }
}

Invoke-CheckedCommand flutter pub get
Invoke-CheckedCommand dart format --output=none --set-exit-if-changed lib test
Invoke-CheckedCommand flutter analyze
Invoke-CheckedCommand flutter test

if ($BuildAndroid) {
    Invoke-CheckedCommand flutter build apk --debug
}

Write-Host "Repository verification completed successfully."
