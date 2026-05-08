#Requires -Version 7.2

if (-not $IsLinux) {
    throw "PowerShell.LocalAccounts.Linux cannot be loaded on Windows. On Windows, use the built-in 'Microsoft.PowerShell.LocalAccounts' module:`n  Import-Module Microsoft.PowerShell.LocalAccounts`nPowerShell.LocalAccounts.Linux is a Linux-only peer module."
}

$functionsPath = Join-Path $PSScriptRoot 'Functions'
Get-ChildItem -Path $functionsPath -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}
