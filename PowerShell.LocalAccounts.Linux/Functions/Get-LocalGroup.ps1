#Requires -Version 7.2
function Get-LocalGroup {
    <#
    .SYNOPSIS
        Gets local groups on a Linux system.
    .DESCRIPTION
        Returns local groups by parsing getent group.
        Mirrors the output shape of Get-LocalGroup on Windows.
    .PARAMETER Name
        One or more group names to retrieve. Wildcards accepted.
    .EXAMPLE
        Get-LocalGroup
        Lists all local groups.
    .EXAMPLE
        Get-LocalGroup -Name sudo
        Gets the sudo group.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [string[]]$Name
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Get-LocalGroup @PSBoundParameters
            } else {
                Write-Warning "Get-LocalGroup: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        $patterns = if ($Name) { $Name } else { @('*') }

        $groupLines = & getent group 2>/dev/null
        foreach ($line in $groupLines) {
            $fields = $line -split ':'
            if ($fields.Count -lt 4) { continue }

            $groupName = $fields[0]
            $gid       = [int]$fields[2]

            $matched = $false
            foreach ($p in $patterns) {
                if ($groupName -like $p) { $matched = $true; break }
            }
            if (-not $matched) { continue }

            [PSCustomObject]@{
                PSTypeName      = 'Microsoft.PowerShell.Commands.LocalGroup'
                Name            = $groupName
                Description     = ''
                SID             = $null
                ObjectClass     = 'Group'
                PrincipalSource = 'Local'
                GID             = $gid
            }
        }
    }
}
