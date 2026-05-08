#Requires -Version 7.2
function Remove-LocalGroup {
    <#
    .SYNOPSIS
        Removes a local group from a Linux system.
    .DESCRIPTION
        Wraps groupdel to remove a local group. Requires root or sudo.
    .PARAMETER Name
        The group to remove.
    .EXAMPLE
        Remove-LocalGroup -Name developers
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Remove-LocalGroup @PSBoundParameters
            } else {
                Write-Warning "Remove-LocalGroup: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Remove-LocalGroup')) {
            & groupdel $Name
            if ($LASTEXITCODE -ne 0) {
                Write-Error "groupdel failed with exit code $LASTEXITCODE for group '$Name'."
            }
        }
    }
}
