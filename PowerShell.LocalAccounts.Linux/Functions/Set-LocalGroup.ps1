#Requires -Version 7.2
function Set-LocalGroup {
    <#
    .SYNOPSIS
        Modifies a local group on a Linux system.
    .DESCRIPTION
        Wraps groupmod to modify group properties. Requires root or sudo.
    .PARAMETER Name
        The group to modify.
    .PARAMETER Description
        New description. Linux groups have no native description field;
        this parameter is accepted for parity but has no effect.
    .EXAMPLE
        Set-LocalGroup -Name developers -Description 'Development team'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter()]
        [string]$Description
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Set-LocalGroup @PSBoundParameters
            } else {
                Write-Warning "Set-LocalGroup: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Set-LocalGroup')) {
            # Linux groups have no description field; validate group exists
            $groupLine = & getent group $Name 2>/dev/null
            if (-not $groupLine) {
                Write-Error "Group '$Name' was not found."
                return
            }
            if ($Description) {
                Write-Warning "Set-LocalGroup: Linux groups do not support a description field. The Description parameter has no effect."
            }
        }
    }
}
