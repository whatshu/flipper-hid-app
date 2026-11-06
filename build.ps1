param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$UfbtArgs
)

$ErrorActionPreference = 'Stop'
$envRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\env'))
$ufbt = Join-Path $envRoot 'python\Scripts\ufbt.exe'
if (!(Test-Path -LiteralPath $ufbt)) {
    throw 'Independent environment is missing. Run .\setup-env.ps1 first.'
}

$overrides = @{
    UFBT_HOME = Join-Path $envRoot 'ufbt'
    FBT_TOOLCHAIN_PATH = Join-Path $envRoot 'ufbt'
    TEMP = Join-Path $envRoot 'tmp'
    TMP = Join-Path $envRoot 'tmp'
}
$previous = @{}
foreach ($name in $overrides.Keys) {
    $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $overrides[$name], 'Process')
}
try {
    New-Item -ItemType Directory -Force $overrides.TEMP | Out-Null
    Push-Location $PSScriptRoot
    try {
        & $ufbt @UfbtArgs
        $result = $LASTEXITCODE
    } finally {
        Pop-Location
    }
} finally {
    foreach ($name in $previous.Keys) {
        [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process')
    }
}
exit $result
