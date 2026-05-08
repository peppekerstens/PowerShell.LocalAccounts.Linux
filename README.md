# PowerShell.LocalAccounts.Linux

> Linux peer module for `Microsoft.PowerShell.LocalAccounts`. Wraps `useradd`, `usermod`, `userdel`, `groupadd`, `groupmod`, `groupdel`, `gpasswd`, and `getent` to provide the full 15-cmdlet surface of the Windows LocalAccounts module on Linux.

Inspired by [Evgenij Smirnov's call to action](https://www.youtube.com/watch?v=RlzinWYIjBY) at the 2025 European PowerShell Summit.

---

## What it does

Provides all 15 cmdlets from `Microsoft.PowerShell.LocalAccounts` for Linux:

| Cmdlet | Linux tool | Notes |
|---|---|---|
| `Get-LocalUser` | `getent passwd`, `passwd -S`, `chage -l` | Full object including UID, shell, home, enabled state |
| `Get-LocalGroup` | `getent group` | Includes GID |
| `Get-LocalGroupMember` | `getent group`, `getent passwd` | Includes primary-group members |
| `New-LocalUser` | `useradd`, `chpasswd` | SupportsShouldProcess |
| `New-LocalGroup` | `groupadd` | SupportsShouldProcess |
| `Set-LocalUser` | `usermod`, `chage`, `chpasswd` | SupportsShouldProcess |
| `Set-LocalGroup` | — | No-op (Linux groups have no description field); warns |
| `Enable-LocalUser` | `usermod -U` | Unlocks the account |
| `Disable-LocalUser` | `usermod -L` | Locks the account |
| `Remove-LocalUser` | `userdel` | `-RemoveHome` to also delete home directory |
| `Remove-LocalGroup` | `groupdel` | SupportsShouldProcess |
| `Add-LocalGroupMember` | `usermod -aG` | SupportsShouldProcess |
| `Remove-LocalGroupMember` | `gpasswd -d` | SupportsShouldProcess |
| `Rename-LocalUser` | `usermod -l` | `-MoveHome` to also rename home directory |
| `Rename-LocalGroup` | `groupmod -n` | SupportsShouldProcess |

All write cmdlets support `-WhatIf` and `-Confirm`.

---

## Requirements

- PowerShell 7.2+
- Linux only (Ubuntu 20.04+ / Debian-based recommended)
- Standard Linux utilities: `useradd`, `usermod`, `userdel`, `groupadd`, `groupmod`, `groupdel`, `gpasswd`, `getent`, `passwd`, `chage`, `chpasswd`
- Most write operations require root or `sudo`

---

## Installation

```powershell
# Clone the repo and import directly
git clone https://github.com/peppekerstens/PowerShell.LocalAccounts.Linux
Import-Module ./PowerShell.LocalAccounts.Linux/PowerShell.LocalAccounts.Linux/PowerShell.LocalAccounts.Linux.psd1
```

---

## Usage

```powershell
# List all users
Get-LocalUser

# Find locked accounts
Get-LocalUser | Where-Object { -not $_.Enabled }

# Show group membership
Get-LocalGroupMember -Group sudo

# Create a new user
New-LocalUser -Name alice -FullName 'Alice Smith' -Password (Read-Host -AsSecureString)

# Add user to group
Add-LocalGroupMember -Group sudo -Member alice

# Disable an account
Disable-LocalUser -Name alice

# Remove a user and their home directory
Remove-LocalUser -Name alice -RemoveHome
```

---

## Examples

The `Examples\` folder contains four ready-to-run scripts:

| Script | Description |
|---|---|
| `Get-LocalUsers.ps1` | List all users with status, UID, shell, and home |
| `Get-LocalGroups.ps1` | List all groups with GID and member list |
| `Get-UserGroupMembership.ps1` | Show group memberships per user |
| `Get-DisabledUsers.ps1` | Find disabled/locked accounts |

---

## Cmdlet Status

| Cmdlet | Status | Notes |
|---|---|---|
| `Get-LocalUser` | ✅ Implemented | |
| `Get-LocalGroup` | ✅ Implemented | |
| `Get-LocalGroupMember` | ✅ Implemented | Includes primary-group membership |
| `New-LocalUser` | ✅ Implemented | |
| `New-LocalGroup` | ✅ Implemented | |
| `Set-LocalUser` | ✅ Implemented | |
| `Set-LocalGroup` | ✅ Implemented | No-op (no description field on Linux) |
| `Enable-LocalUser` | ✅ Implemented | |
| `Disable-LocalUser` | ✅ Implemented | |
| `Remove-LocalUser` | ✅ Implemented | |
| `Remove-LocalGroup` | ✅ Implemented | |
| `Add-LocalGroupMember` | ✅ Implemented | |
| `Remove-LocalGroupMember` | ✅ Implemented | |
| `Rename-LocalUser` | ✅ Implemented | |
| `Rename-LocalGroup` | ✅ Implemented | |

---

## Implementation Notes

- **Linux-only guard**: The `.psm1` throws immediately on non-Linux platforms. Use `Microsoft.PowerShell.LocalAccounts` on Windows.
- **SID**: Linux has no concept of Windows SIDs. All SID properties return `$null`.
- **Password status**: Requires `passwd -S` which may need root on some distributions. On systems where this is restricted, `Enabled` defaults to `$true`.
- **`Set-LocalGroup`**: Linux groups have no description field; the cmdlet validates the group exists and emits a warning if `Description` is passed.
- **`Get-LocalGroupMember`**: Returns both explicit members (listed in `/etc/group`) and users for whom the group is their primary GID.
- **Write operations**: All mutating cmdlets require appropriate privileges (`root` or `sudo`). No privilege escalation is performed by the module.

---

## Test Results

| Environment | Passed | Skipped | Failed |
|---|---|---|---|
| Windows (Pester 5.3.3) | 10 | 61 | 0 |
| WSL2 Ubuntu (Pester 5.7.1) | 70 | 1 | 0 |

---

## Version History

| Version | Changes |
|---|---|
| 0.1.0 | Initial release. All 15 cmdlets implemented. |

---

## License

[GNU General Public License v3](LICENSE)
