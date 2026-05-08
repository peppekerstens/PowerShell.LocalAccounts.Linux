#Requires -Version 7.2
function Remove-LocalGroupMember {
    <#
    .SYNOPSIS
        Removes a user from a local group on a Linux system.
    .DESCRIPTION
        Wraps gpasswd -d to remove a user from the specified group.
        Requires root or sudo.
    .PARAMETER Group
        The group to remove the member from.
    .PARAMETER Member
        One or more user names to remove from the group.
    .EXAMPLE
        Remove-LocalGroupMember -Group sudo -Member alice
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Group,

        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Member
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Remove-LocalGroupMember @PSBoundParameters
            } else {
                Write-Warning "Remove-LocalGroupMember: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        foreach ($m in $Member) {
            if ($PSCmdlet.ShouldProcess("$m from $Group", 'Remove-LocalGroupMember')) {
                & gpasswd -d $m $Group
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "gpasswd -d failed with exit code $LASTEXITCODE removing '$m' from group '$Group'."
                }
            }
        }
    }
}
