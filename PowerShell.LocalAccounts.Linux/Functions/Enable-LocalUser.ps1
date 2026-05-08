#Requires -Version 7.2
function Enable-LocalUser {
    <#
    .SYNOPSIS
        Enables a local user account on a Linux system.
    .DESCRIPTION
        Unlocks a user account using usermod -U. Requires root or sudo.
    .PARAMETER Name
        The user account to enable.
    .EXAMPLE
        Enable-LocalUser -Name alice
    .EXAMPLE
        Get-LocalUser | Where-Object { -not $_.Enabled } | Enable-LocalUser
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Enable-LocalUser @PSBoundParameters
            } else {
                Write-Warning "Enable-LocalUser: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Enable-LocalUser')) {
            & usermod -U $Name
            if ($LASTEXITCODE -ne 0) {
                Write-Error "usermod -U failed with exit code $LASTEXITCODE for user '$Name'."
            }
        }
    }
}
