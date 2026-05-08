#Requires -Version 7.2
function Rename-LocalUser {
    <#
    .SYNOPSIS
        Renames a local user account on a Linux system.
    .DESCRIPTION
        Wraps usermod -l to rename a user account. The home directory is NOT
        automatically renamed; use -MoveHome to also move the home directory.
        Requires root or sudo.
    .PARAMETER Name
        The current user name.
    .PARAMETER NewName
        The new user name.
    .PARAMETER MoveHome
        Also rename the home directory to match the new user name.
    .EXAMPLE
        Rename-LocalUser -Name alice -NewName alice2
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [string]$NewName,

        [Parameter()]
        [switch]$MoveHome
    )

    process {
        if (-not $IsLinux) {
            if (Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable -ErrorAction SilentlyContinue) {
                Microsoft.PowerShell.LocalAccounts\Rename-LocalUser @PSBoundParameters
            } else {
                Write-Warning "Rename-LocalUser: Microsoft.PowerShell.LocalAccounts is not available on this platform."
            }
            return
        }

        if ($PSCmdlet.ShouldProcess("$Name -> $NewName", 'Rename-LocalUser')) {
            $cmdArgs = @('-l', $NewName)
            if ($MoveHome) { $cmdArgs += @('-m', '-d', "/home/$NewName") }
            & usermod @cmdArgs $Name
            if ($LASTEXITCODE -ne 0) {
                Write-Error "usermod -l failed with exit code $LASTEXITCODE renaming '$Name' to '$NewName'."
                return
            }
            Get-LocalUser -Name $NewName
        }
    }
}
