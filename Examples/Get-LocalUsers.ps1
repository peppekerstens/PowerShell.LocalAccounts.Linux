<#
.SYNOPSIS
    List all local users on the system with their status.
.DESCRIPTION
    Retrieves all local user accounts and displays name, enabled status,
    shell, home directory, and UID in a formatted table.
.EXAMPLE
    pwsh -File Get-LocalUsers.ps1
#>
param()

if ($IsLinux) {
    Import-Module (Join-Path $PSScriptRoot '..' 'PowerShell.LocalAccounts.Linux' 'PowerShell.LocalAccounts.Linux.psd1') -Force
} else {
    Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction Stop
}

Get-LocalUser |
    Sort-Object Name |
    Select-Object Name, Enabled, PasswordRequired,
        @{ Name = 'UID'; Expression = { if ($_.UID) { $_.UID } else { '-' } } },
        @{ Name = 'Shell'; Expression = { if ($_.Shell) { $_.Shell } else { '-' } } },
        @{ Name = 'Home'; Expression = { if ($_.HomeDirectory) { $_.HomeDirectory } else { '-' } } } |
    Format-Table -AutoSize
