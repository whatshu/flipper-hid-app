param([string]$FirmwareVersion = '1.5.1')

$ErrorActionPreference = 'Stop'
$envRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\env'))
$python = Join-Path $envRoot 'python\Scripts\python.exe'
$previousTemp = $env:TEMP
$previousTmp = $env:TMP
try {
    $env:TEMP = Join-Path $envRoot 'tmp'
    $env:TMP = $env:TEMP
    New-Item -ItemType Directory -Force $env:TEMP | Out-Null
    if (!(Test-Path -LiteralPath $python)) {
        & python -m venv (Join-Path $envRoot 'python')
        if ($LASTEXITCODE -ne 0) { throw 'Could not create Python virtual environment.' }
    }
    & $python -m ensurepip --upgrade --default-pip
    if ($LASTEXITCODE -ne 0) { throw 'Could not initialize pip.' }
    & $python -m pip install --cache-dir (Join-Path $envRoot 'pip-cache') 'ufbt==0.2.6' 'pyserial==3.5'
    if ($LASTEXITCODE -ne 0) { throw 'Could not install build tools.' }
    & (Join-Path $PSScriptRoot 'build.ps1') update --branch $FirmwareVersion
    if ($LASTEXITCODE -ne 0) { throw 'Could not install the firmware SDK.' }
} finally {
    $env:TEMP = $previousTemp
    $env:TMP = $previousTmp
}
