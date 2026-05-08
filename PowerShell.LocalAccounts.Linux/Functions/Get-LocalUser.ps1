#Requires -Version 7.2
function Get-LocalUser {
    <#
    .SYNOPSIS
        Gets local user accounts on a Linux system.
    .DESCRIPTION
        Returns local user accounts by parsing getent passwd. Password status
        and expiry information are retrieved via passwd -S and chage.
        Mirrors the output shape of Get-LocalUser on Windows.
    .PARAMETER Name
        One or more user names to retrieve. Wildcards accepted.
        If omitted, all local users are returned.
    .EXAMPLE
        Get-LocalUser
        Lists all local users.
    .EXAMPLE
        Get-LocalUser -Name peppe
        Gets the user named peppe.
    .EXAMPLE
        Get-LocalUser -Name 'a*'
        Gets all users whose name starts with a.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [string[]]$Name
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Get-LocalUser @PSBoundParameters
            } else {
                Write-Warning "Get-LocalUser: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        $patterns = if ($Name) { $Name } else { @('*') }

        $passwdLines = & getent passwd 2>/dev/null
        foreach ($line in $passwdLines) {
            $fields = $line -split ':'
            if ($fields.Count -lt 7) { continue }

            $username  = $fields[0]
            $uid       = [int]$fields[2]
            $gid       = [int]$fields[3]
            $gecos     = $fields[4]
            $home      = $fields[5]
            $shell     = $fields[6]

            # Filter by Name patterns
            $matched = $false
            foreach ($p in $patterns) {
                if ($username -like $p) { $matched = $true; break }
            }
            if (-not $matched) { continue }

            # Parse GECOS — first field is Full Name
            $fullName = ($gecos -split ',')[0]

            # Password status via passwd -S (requires appropriate permissions)
            $enabled = $true
            $passwordRequired = $true
            try {
                $passwdStatus = & passwd -S $username 2>/dev/null
                if ($passwdStatus -match '^\S+\s+(L|LK)\s') {
                    $enabled = $false   # locked
                }
                if ($passwdStatus -match '^\S+\s+NP\s') {
                    $passwordRequired = $false  # no password
                }
            } catch { }

            # Password expiry via chage -l
            $passwordExpires = $null
            $passwordLastSet = $null
            $accountExpires  = $null
            $passwordChangeableDate = $null
            try {
                $chageOutput = & chage -l $username 2>/dev/null
                foreach ($chageLine in $chageOutput) {
                    if ($chageLine -match 'Password expires\s*:\s*(.+)') {
                        $val = $Matches[1].Trim()
                        if ($val -notin 'never', 'password must be changed') {
                            $passwordExpires = [datetime]::Parse($val, [System.Globalization.CultureInfo]::InvariantCulture)
                        }
                    }
                    if ($chageLine -match 'Last password change\s*:\s*(.+)') {
                        $val = $Matches[1].Trim()
                        if ($val -notin 'never', 'password must be changed') {
                            try { $passwordLastSet = [datetime]::Parse($val, [System.Globalization.CultureInfo]::InvariantCulture) } catch { }
                        }
                    }
                    if ($chageLine -match 'Account expires\s*:\s*(.+)') {
                        $val = $Matches[1].Trim()
                        if ($val -ne 'never') {
                            try { $accountExpires = [datetime]::Parse($val, [System.Globalization.CultureInfo]::InvariantCulture) } catch { }
                        }
                    }
                    if ($chageLine -match 'Password inactive\s*:\s*(.+)') {
                        $val = $Matches[1].Trim()
                    }
                    if ($chageLine -match 'Minimum number of days between password change\s*:\s*(.+)') {
                        # passwordChangeableDate = passwordLastSet + minDays
                    }
                }
            } catch { }

            [PSCustomObject]@{
                PSTypeName              = 'Microsoft.PowerShell.Commands.LocalUser'
                Name                   = $username
                FullName               = $fullName
                Description            = $gecos
                Enabled                = $enabled
                SID                    = $null
                ObjectClass            = 'User'
                PrincipalSource        = 'Local'
                PasswordRequired       = $passwordRequired
                UserMayChangePassword  = $true
                PasswordExpires        = $passwordExpires
                PasswordLastSet        = $passwordLastSet
                PasswordChangeableDate = $passwordChangeableDate
                AccountExpires         = $accountExpires
                LastLogon              = $null
                HomeDirectory          = $home
                Shell                  = $shell
                UID                    = $uid
                GID                    = $gid
            }
        }
    }
}
