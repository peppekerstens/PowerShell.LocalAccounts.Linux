<#
.SYNOPSIS
    Show the group memberships of each local user.
.DESCRIPTION
    For every local user account, lists which groups that user belongs to.
    Useful for auditing group membership across the system.
.EXAMPLE
    pwsh -File Get-UserGroupMembership.ps1
.EXAMPLE
    pwsh -File Get-UserGroupMembership.ps1 | Where-Object { $_.Groups -match 'sudo' }
#>
param(
    [string]$UserName   # Optional: filter to a single user
)

if ($IsLinux) {
    Import-Module (Join-Path $PSScriptRoot '..' 'PowerShell.LocalAccounts.Linux' 'PowerShell.LocalAccounts.Linux.psd1') -Force
} else {
    Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction Stop
}

$users = if ($UserName) {
    Get-LocalUser -Name $UserName
} else {
    Get-LocalUser | Sort-Object Name
}

$allGroups = Get-LocalGroup

$users | ForEach-Object {
    $user = $_
    $memberOf = $allGroups | Where-Object {
        $members = Get-LocalGroupMember -Group $_.Name |
                       Select-Object -ExpandProperty Name
        $user.Name -in $members
    } | Select-Object -ExpandProperty Name

    [PSCustomObject]@{
        User    = $user.Name
        Enabled = $user.Enabled
        Groups  = if ($memberOf) { $memberOf -join ', ' } else { '(none)' }
    }
} | Format-Table -AutoSize
