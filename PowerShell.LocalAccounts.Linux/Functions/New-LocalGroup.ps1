#Requires -Version 7.2
function New-LocalGroup {
    <#
    .SYNOPSIS
        Creates a new local group on a Linux system.
    .DESCRIPTION
        Wraps groupadd to create a new local group. Requires root or sudo.
    .PARAMETER Name
        The name for the new group.
    .PARAMETER Description
        Description for the group (stored as a comment — Linux groups have no
        native description field; this is a no-op for compatibility).
    .EXAMPLE
        New-LocalGroup -Name developers
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [string]$Description
    )

    if (-not $IsLinux) {
        if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
            Microsoft.PowerShell.LocalAccounts\New-LocalGroup @PSBoundParameters
        } else {
            Write-Warning "New-LocalGroup: Microsoft.PowerShell.LocalAccounts is not available on this platform."
        }
        return
    }

    if ($PSCmdlet.ShouldProcess($Name, 'New-LocalGroup')) {
        & groupadd $Name
        if ($LASTEXITCODE -ne 0) {
            Write-Error "groupadd failed with exit code $LASTEXITCODE for group '$Name'."
            return
        }
        Get-LocalGroup -Name $Name
    }
}
