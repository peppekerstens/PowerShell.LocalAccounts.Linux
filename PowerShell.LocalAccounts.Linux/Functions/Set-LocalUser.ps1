#Requires -Version 7.2
function Set-LocalUser {
    <#
    .SYNOPSIS
        Modifies a local user account on a Linux system.
    .DESCRIPTION
        Wraps usermod, chage, and passwd to modify user account properties.
        Requires root or sudo for most operations.
    .PARAMETER Name
        The user to modify.
    .PARAMETER FullName
        New full name (GECOS field).
    .PARAMETER Description
        New description (GECOS field). FullName takes precedence if both are given.
    .PARAMETER Password
        New password as a SecureString.
    .PARAMETER AccountExpires
        New account expiry date.
    .PARAMETER AccountNeverExpires
        Remove account expiry.
    .PARAMETER Shell
        New login shell.
    .PARAMETER HomeDirectory
        New home directory path.
    .PARAMETER PasswordNeverExpires
        Set the password to never expire.
    .PARAMETER UserMayChangePassword
        Not enforced on Linux; included for parameter parity.
    .EXAMPLE
        Set-LocalUser -Name alice -FullName 'Alice J. Smith'
    .EXAMPLE
        Set-LocalUser -Name alice -Password (Read-Host -AsSecureString)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter()]
        [string]$FullName,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [securestring]$Password,

        [Parameter()]
        [datetime]$AccountExpires,

        [Parameter()]
        [switch]$AccountNeverExpires,

        [Parameter()]
        [string]$Shell,

        [Parameter()]
        [string]$HomeDirectory,

        [Parameter()]
        [switch]$PasswordNeverExpires,

        [Parameter()]
        [bool]$UserMayChangePassword
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Set-LocalUser @PSBoundParameters
            } else {
                Write-Warning "Set-LocalUser: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Set-LocalUser')) {
            $usermodArgs = @()

            $gecos = if ($FullName) { $FullName } elseif ($Description) { $Description } else { $null }
            if ($null -ne $gecos) { $usermodArgs += @('--comment', $gecos) }
            if ($Shell)          { $usermodArgs += @('--shell', $Shell) }
            if ($HomeDirectory)  { $usermodArgs += @('--home', $HomeDirectory) }

            if ($AccountNeverExpires) {
                $usermodArgs += @('--expiredate', '')
            } elseif ($AccountExpires) {
                $usermodArgs += @('--expiredate', $AccountExpires.ToString('yyyy-MM-dd'))
            }

            if ($usermodArgs.Count -gt 0) {
                & usermod @usermodArgs $Name
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "usermod failed with exit code $LASTEXITCODE for user '$Name'."
                    return
                }
            }

            if ($Password) {
                $plainText = [System.Net.NetworkCredential]::new('', $Password).Password
                "${Name}:${plainText}" | & chpasswd
            }

            if ($PasswordNeverExpires) {
                & chage -M 99999 $Name | Out-Null
            }
        }
    }
}
