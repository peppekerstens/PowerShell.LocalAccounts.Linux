# PowerShell.LocalAccounts.Linux

[![Pester Tests](https://github.com/peppekerstens/PowerShell.LocalAccounts.Linux/actions/workflows/pester.yml/badge.svg)](https://github.com/peppekerstens/PowerShell.LocalAccounts.Linux/actions/workflows/pester.yml)

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

## CI / Testing

Tested across 5 Linux distributions in containers:

| Distro | Image |
|---|---|
| Ubuntu 24.04 | `ghcr.io/peppekerstens/testinfra:ubuntu-24.04` |
| Debian 12 | `ghcr.io/peppekerstens/testinfra:debian-12` |
| Fedora 40 | `ghcr.io/peppekerstens/testinfra:fedora-40` |
| openSUSE Tumbleweed | `ghcr.io/peppekerstens/testinfra:opensuse-tumbleweed` |
| Arch Linux | `ghcr.io/peppekerstens/testinfra:arch-latest` |

Run locally with:

```powershell
# From the repo root
docker compose -f docker-compose.test.yml up --abort-on-container-exit
```

GitHub Actions runs the same matrix on every push — see `.github/workflows/pester.yml`.
---

## Version history

| Version | Changes |
|---|---|
| 0.1.0 | Initial release. All 15 cmdlets implemented. |

---

## How we built this

### Why this module exists

`Microsoft.PowerShell.LocalAccounts` is the standard module for managing local users and groups on Windows. It's 15 cmdlets that cover the full lifecycle: create, modify, enable, disable, delete, and query. On Linux, none of this exists natively in PowerShell. You can call `useradd` and friends from bash, but that breaks cross-platform scripts. This module makes the same 15 cmdlets work on Linux so you can write one script and run it anywhere.

### No renaming needed

Unlike other modules in this project (Storage, Security, Update), `PowerShell.LocalAccounts.Linux` does **not** use Linux-native names with Windows aliases. The reason: the cmdlet nouns are already platform-neutral. `LocalUser` and `LocalGroup` are abstract concepts that exist on both platforms. Renaming to `LinuxLocalUser` would be silly. So this module exports the exact same names as the Windows module — `Get-LocalUser`, `New-LocalUser`, etc. — with no aliases required.

### Tool choices

**`getent passwd`** is the standard way to enumerate users on Linux. It works with `/etc/passwd` but also with LDAP/NIS/SSSD backends if configured — making it the correct tool rather than reading `/etc/passwd` directly. Same for `getent group`.

**`passwd -S`** gives the password status (locked, unlocked, no password). This is what `Get-LocalUser` uses to populate the `Enabled` property. A locked account (`passwd -S username` returns `L` in the second field) maps to `Enabled = $false`.

**`chage -l`** provides account expiry information: `PasswordExpired`, `PasswordChangeableDate`, `AccountExpires`, `PasswordLastSet`. These are the fields that `Get-LocalUser` returns on Windows and that scripts actually use.

**`useradd`, `usermod`, `userdel`, `groupadd`, `groupmod`, `groupdel`, `gpasswd`, `chpasswd`** handle all write operations. These are the standard Linux user management tools — nothing exotic.

### Key gotchas

**Primary-group membership.** On Linux, a user's primary group (their GID in `/etc/passwd`) is not listed in `/etc/group` for that group — it's implicit. `Get-LocalGroupMember` on Windows returns all members of a group. If we only read `/etc/group` entries, we miss users whose primary GID matches that group. The fix: for each user in `getent passwd`, check if their primary GID matches the requested group, and include them if so.

**`Set-LocalGroup` is a no-op.** Linux groups have no description field. The Windows cmdlet accepts `-Description`. Our implementation validates the group exists, emits a `Write-Warning` if `-Description` was passed (explaining that it has no effect), and returns. It's technically a no-op, but it doesn't error — which is what you want for cross-platform script compatibility.

**`passwd -S` may need root.** On some hardened distributions, reading password status requires root privileges. Rather than hard-failing, the module catches permission errors and defaults `Enabled` to `$true` with a `Write-Warning`. Scripts that need accurate enabled status on such systems need to run as root.

**SIDs don't exist.** Windows LocalAccounts objects have SID properties. Linux has no SIDs. All SID properties return `$null`. If a script reads `.SID` and does something with it, it will fail — but that's an inherently Windows-specific script and can't be fixed at the module layer.

**Write operations need elevation.** `useradd`, `usermod`, `userdel` etc. require root or sudo. The module does not try to escalate privileges automatically. If a write cmdlet is called without sufficient rights, the underlying tool fails and the error bubbles up naturally.

### Test approach

Tests use Pester 5.2+ with `BeforeDiscovery` for platform detection. On Windows, 10 metadata/structural tests run (checking module manifest, exported cmdlets, etc.) and 61 Linux tests skip. On WSL2, 70 tests run (1 skips — the `passwd -S` root-required test). Tests that create users and groups clean up after themselves. The test file requires `#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }` to ensure consistent behavior across Pester versions.

---

## License

[GNU General Public License v3](LICENSE)
