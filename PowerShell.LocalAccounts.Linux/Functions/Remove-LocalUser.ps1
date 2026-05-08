#Requires -Version 7.2
function Remove-LocalUser {
    <#
    .SYNOPSIS
        Removes a local user account from a Linux system.
    .DESCRIPTION
        Wraps userdel to remove a local user account. Requires root or sudo.
    .PARAMETER Name
        The user account to remove.
    .PARAMETER RemoveHome
        Also remove the user's home directory and mail spool.
    .EXAMPLE
        Remove-LocalUser -Name alice
    .EXAMPLE
        Remove-LocalUser -Name alice -RemoveHome
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter()]
        [switch]$RemoveHome
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Remove-LocalUser @PSBoundParameters
            } else {
                Write-Warning "Remove-LocalUser: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Remove-LocalUser')) {
            $delArgs = if ($RemoveHome) { @('-r') } else { @() }
            & userdel @delArgs $Name
            if ($LASTEXITCODE -ne 0) {
                Write-Error "userdel failed with exit code $LASTEXITCODE for user '$Name'."
            }
        }
    }
}
