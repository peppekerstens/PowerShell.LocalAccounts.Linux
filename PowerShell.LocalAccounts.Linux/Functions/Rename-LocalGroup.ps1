#Requires -Version 7.2
function Rename-LocalGroup {
    <#
    .SYNOPSIS
        Renames a local group on a Linux system.
    .DESCRIPTION
        Wraps groupmod -n to rename a local group. Requires root or sudo.
    .PARAMETER Name
        The current group name.
    .PARAMETER NewName
        The new group name.
    .EXAMPLE
        Rename-LocalGroup -Name developers -NewName engineering
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [string]$NewName
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Rename-LocalGroup @PSBoundParameters
            } else {
                Write-Warning "Rename-LocalGroup: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        if ($PSCmdlet.ShouldProcess("$Name -> $NewName", 'Rename-LocalGroup')) {
            & groupmod -n $NewName $Name
            if ($LASTEXITCODE -ne 0) {
                Write-Error "groupmod -n failed with exit code $LASTEXITCODE renaming '$Name' to '$NewName'."
                return
            }
            Get-LocalGroup -Name $NewName
        }
    }
}
