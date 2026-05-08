#Requires -Version 7.2
function Disable-LocalUser {
    <#
    .SYNOPSIS
        Disables a local user account on a Linux system.
    .DESCRIPTION
        Locks a user account using usermod -L. Requires root or sudo.
    .PARAMETER Name
        The user account to disable.
    .EXAMPLE
        Disable-LocalUser -Name alice
    .EXAMPLE
        Get-LocalUser -Name 'svc*' | Disable-LocalUser
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Disable-LocalUser @PSBoundParameters
            } else {
                Write-Warning "Disable-LocalUser: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Disable-LocalUser')) {
            & usermod -L $Name
            if ($LASTEXITCODE -ne 0) {
                Write-Error "usermod -L failed with exit code $LASTEXITCODE for user '$Name'."
            }
        }
    }
}
