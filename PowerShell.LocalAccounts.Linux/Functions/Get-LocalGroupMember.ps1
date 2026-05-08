#Requires -Version 7.2
function Get-LocalGroupMember {
    <#
    .SYNOPSIS
        Gets members of a local group on a Linux system.
    .DESCRIPTION
        Returns the members of the specified local group by parsing getent group.
        Primary group members (users whose primary GID matches the group) are
        also included.
    .PARAMETER Group
        The name of the group to query.
    .EXAMPLE
        Get-LocalGroupMember -Group sudo
        Gets all members of the sudo group.
    .EXAMPLE
        Get-LocalGroup | Get-LocalGroupMember
        Gets members of every local group.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Group
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Get-LocalGroupMember @PSBoundParameters
            } else {
                Write-Warning "Get-LocalGroupMember: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        $groupLine = & getent group $Group 2>/dev/null
        if (-not $groupLine) {
            Write-Error "Group '$Group' was not found."
            return
        }

        $fields  = $groupLine -split ':'
        $gid     = [int]$fields[2]
        $members = if ($fields[3]) { $fields[3] -split ',' | Where-Object { $_ -ne '' } } else { @() }

        # Also include users for whom this is their primary group
        $primaryMembers = & getent passwd 2>/dev/null |
            ForEach-Object {
                $f = $_ -split ':'
                if ($f.Count -ge 4 -and [int]$f[3] -eq $gid) { $f[0] }
            }

        $allMembers = ($members + $primaryMembers) | Sort-Object -Unique

        foreach ($member in $allMembers) {
            [PSCustomObject]@{
                PSTypeName      = 'Microsoft.PowerShell.Commands.LocalPrincipal'
                Name            = $member
                ObjectClass     = 'User'
                PrincipalSource = 'Local'
                SID             = $null
            }
        }
    }
}
