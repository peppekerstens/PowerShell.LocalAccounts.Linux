#Requires -Version 7.2
function Add-LocalGroupMember {
    <#
    .SYNOPSIS
        Adds a user to a local group on a Linux system.
    .DESCRIPTION
        Wraps usermod -aG to add a user to the specified group.
        Requires root or sudo.
    .PARAMETER Group
        The group to add the member to.
    .PARAMETER Member
        One or more user names to add to the group.
    .EXAMPLE
        Add-LocalGroupMember -Group sudo -Member alice
    .EXAMPLE
        Add-LocalGroupMember -Group developers -Member alice,bob
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Group,

        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Member
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Add-LocalGroupMember @PSBoundParameters
            } else {
                Write-Warning "Add-LocalGroupMember: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        foreach ($m in $Member) {
            if ($PSCmdlet.ShouldProcess("$m -> $Group", 'Add-LocalGroupMember')) {
                & usermod -aG $Group $m
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "usermod -aG failed with exit code $LASTEXITCODE adding '$m' to group '$Group'."
                }
            }
        }
    }
}
