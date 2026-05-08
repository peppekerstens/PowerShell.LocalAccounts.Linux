<#
.SYNOPSIS
    Find disabled or locked user accounts.
.DESCRIPTION
    Lists all local user accounts that are currently disabled (locked).
    Useful for auditing dormant or service accounts.
.EXAMPLE
    pwsh -File Get-DisabledUsers.ps1
#>
param()

if ($IsLinux) {
    Import-Module (Join-Path $PSScriptRoot '..' 'PowerShell.LocalAccounts.Linux' 'PowerShell.LocalAccounts.Linux.psd1') -Force
} else {
    Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction Stop
}

$disabled = Get-LocalUser | Where-Object { -not $_.Enabled }

if ($disabled) {
    Write-Host "Disabled user accounts:" -ForegroundColor Yellow
    $disabled |
        Sort-Object Name |
        Select-Object Name,
            @{ Name = 'UID'; Expression = { if ($_.UID) { $_.UID } else { '-' } } },
            Shell, HomeDirectory |
        Format-Table -AutoSize
} else {
    Write-Host "No disabled user accounts found." -ForegroundColor Green
}
