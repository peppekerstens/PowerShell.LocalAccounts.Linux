#Requires -Version 7.2
function New-LocalUser {
    <#
    .SYNOPSIS
        Creates a new local user account on a Linux system.
    .DESCRIPTION
        Wraps useradd to create a new local user. Requires root or sudo.
    .PARAMETER Name
        The user name for the new account.
    .PARAMETER FullName
        The full name (GECOS field) for the new account.
    .PARAMETER Description
        Description stored in the GECOS field. If both FullName and Description
        are given, FullName takes precedence.
    .PARAMETER Password
        The password as a SecureString. If omitted the account is created locked.
    .PARAMETER NoPassword
        Create the account with no password (passwordless login).
    .PARAMETER AccountExpires
        The date on which the account expires.
    .PARAMETER AccountNeverExpires
        The account does not expire.
    .PARAMETER HomeDirectory
        Path to the home directory. Defaults to /home/<Name>.
    .PARAMETER Shell
        Login shell. Defaults to /bin/bash.
    .PARAMETER Disabled
        Create the account in a disabled (locked) state.
    .EXAMPLE
        New-LocalUser -Name alice -FullName 'Alice Smith' -Password (Read-Host -AsSecureString)
    .EXAMPLE
        New-LocalUser -Name svcaccount -NoPassword -Disabled
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Password')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [string]$FullName,

        [Parameter()]
        [string]$Description,

        [Parameter(ParameterSetName = 'Password')]
        [securestring]$Password,

        [Parameter(ParameterSetName = 'NoPassword')]
        [switch]$NoPassword,

        [Parameter()]
        [datetime]$AccountExpires,

        [Parameter()]
        [switch]$AccountNeverExpires,

        [Parameter()]
        [string]$HomeDirectory,

        [Parameter()]
        [string]$Shell = '/bin/bash',

        [Parameter()]
        [switch]$Disabled
    )

    if (-not $IsLinux) {
        if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
            Microsoft.PowerShell.LocalAccounts\New-LocalUser @PSBoundParameters
        } else {
            Write-Warning "New-LocalUser: Microsoft.PowerShell.LocalAccounts is not available on this platform."
        }
        return
    }

    $cmdArgs = @('--shell', $Shell, '--create-home')

    $gecos = if ($FullName) { $FullName } elseif ($Description) { $Description } else { '' }
    if ($gecos) { $cmdArgs += @('--comment', $gecos) }

    if ($HomeDirectory) { $cmdArgs += @('--home-dir', $HomeDirectory) }

    if ($AccountExpires -and -not $AccountNeverExpires) {
        $cmdArgs += @('--expiredate', $AccountExpires.ToString('yyyy-MM-dd'))
    }

    if ($PSCmdlet.ShouldProcess($Name, 'New-LocalUser')) {
        & useradd @cmdArgs $Name
        if ($LASTEXITCODE -ne 0) {
            Write-Error "useradd failed with exit code $LASTEXITCODE for user '$Name'."
            return
        }

        if ($Password) {
            $plainText = [System.Net.NetworkCredential]::new('', $Password).Password
            "$(${Name}):${plainText}" | & chpasswd
        } elseif ($NoPassword) {
            & passwd -d $Name | Out-Null
        }

        if ($Disabled) {
            & usermod -L $Name | Out-Null
        }

        Get-LocalUser -Name $Name
    }
}
