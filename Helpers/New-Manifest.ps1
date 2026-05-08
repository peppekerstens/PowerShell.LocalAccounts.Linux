$params = @{
    Path              = 'C:\Users\peppe\OneDrive\GitHub\PowerShell.LocalAccounts.Linux\PowerShell.LocalAccounts.Linux\PowerShell.LocalAccounts.Linux.psd1'
    RootModule        = 'PowerShell.LocalAccounts.Linux.psm1'
    ModuleVersion     = '0.1.0'
    Author            = 'Peppe Kerstens'
    Description       = 'Linux peer module for Microsoft.PowerShell.LocalAccounts. Wraps useradd/usermod/groupadd/getent to provide the full cmdlet surface of the Windows LocalAccounts module on Linux.'
    PowerShellVersion = '7.2'
    FunctionsToExport = @(
        'Get-LocalUser','New-LocalUser','Set-LocalUser','Enable-LocalUser','Disable-LocalUser',
        'Remove-LocalUser','Rename-LocalUser',
        'Get-LocalGroup','New-LocalGroup','Set-LocalGroup','Remove-LocalGroup','Rename-LocalGroup',
        'Get-LocalGroupMember','Add-LocalGroupMember','Remove-LocalGroupMember'
    )
    AliasesToExport   = @()
    Tags              = @('Linux','LocalAccounts','Users','Groups')
    ProjectUri        = 'https://github.com/peppekerstens/PowerShell.LocalAccounts.Linux'
    LicenseUri        = 'https://github.com/peppekerstens/PowerShell.LocalAccounts.Linux/blob/main/LICENSE'
}
New-ModuleManifest @params
Write-Host 'Manifest created'
