<#
.SYNOPSIS
    List all local groups and their members.
.DESCRIPTION
    Retrieves every local group and for each group lists its members,
    formatted as a summary table.
.EXAMPLE
    pwsh -File Get-LocalGroups.ps1
#>
param()

if ($IsLinux) {
    Import-Module (Join-Path $PSScriptRoot '..' 'PowerShell.LocalAccounts.Linux' 'PowerShell.LocalAccounts.Linux.psd1') -Force
} else {
    Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction Stop
}

Get-LocalGroup | Sort-Object Name | ForEach-Object {
    $group   = $_
    $members = Get-LocalGroupMember -Group $group.Name |
                   Select-Object -ExpandProperty Name
    [PSCustomObject]@{
        Group   = $group.Name
        GID     = if ($group.GID) { $group.GID } else { '-' }
        Members = if ($members) { $members -join ', ' } else { '(none)' }
    }
} | Format-Table -AutoSize
