#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeDiscovery {
    $script:moduleName = 'PowerShell.LocalAccounts.Linux'
    $script:onLinux    = $IsLinux -eq $true

    $script:allFunctions = @(
        'Get-LocalUser','New-LocalUser','Set-LocalUser','Enable-LocalUser','Disable-LocalUser',
        'Remove-LocalUser','Rename-LocalUser',
        'Get-LocalGroup','New-LocalGroup','Set-LocalGroup','Remove-LocalGroup','Rename-LocalGroup',
        'Get-LocalGroupMember','Add-LocalGroupMember','Remove-LocalGroupMember'
    )

    $script:readFunctions  = @('Get-LocalUser','Get-LocalGroup','Get-LocalGroupMember')
    $script:writeFunctions = $script:allFunctions | Where-Object { $_ -notin $script:readFunctions }
}

Describe 'Module: PowerShell.LocalAccounts.Linux' {

    BeforeAll {
        $script:moduleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $PSCommandPath -Parent }
        $script:modulePath = Join-Path $script:moduleRoot 'PowerShell.LocalAccounts.Linux.psd1'
        if ($IsLinux) {
            Import-Module $script:modulePath -Force -ErrorAction Stop
        }
    }

    AfterAll {
        if ($IsLinux) {
            Remove-Module 'PowerShell.LocalAccounts.Linux' -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Manifest' {
        It 'psd1 file exists' {
            $script:modulePath | Should -Exist
        }
        It 'manifest is valid' -Skip:(-not $script:onLinux) {
            { Test-ModuleManifest -Path $script:modulePath -ErrorAction Stop } | Should -Not -Throw
        }
        It 'exports 15 functions' -Skip:(-not $script:onLinux) {
            $m = Get-Module 'PowerShell.LocalAccounts.Linux'
            ($m.ExportedFunctions.Keys | Measure-Object).Count | Should -Be 15
        }
        It 'exports no aliases' -Skip:(-not $script:onLinux) {
            $m = Get-Module 'PowerShell.LocalAccounts.Linux'
            ($m.ExportedAliases.Keys | Measure-Object).Count | Should -Be 0
        }
    }

    Context 'Module surface' -Skip:(-not $script:onLinux) {
        It 'exports function <_>' -ForEach $script:allFunctions {
            Get-Command -Module $script:moduleName -Name $_ | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Linux-only guard' {
        It 'throws on non-Linux import attempt' -Skip:$script:onLinux {
            { Import-Module $script:modulePath -Force -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Get-LocalUser' -Skip:(-not $script:onLinux) {
        It 'returns at least one user' {
            $users = Get-LocalUser
            $users | Should -Not -BeNullOrEmpty
        }
        It 'returns objects with Name property' {
            $users = Get-LocalUser
            $users[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'returns objects with Enabled property' {
            $users = Get-LocalUser
            $users[0].Enabled | Should -BeOfType [bool]
        }
        It 'returns objects with PasswordRequired property' {
            $users = Get-LocalUser
            $users[0].PasswordRequired | Should -BeOfType [bool]
        }
        It 'returns objects with UID property' {
            $users = Get-LocalUser
            $users[0].UID | Should -BeOfType [int]
        }
        It 'root user exists' {
            $root = Get-LocalUser -Name root
            $root | Should -Not -BeNullOrEmpty
            $root.Name | Should -Be 'root'
        }
        It 'wildcard filter works' {
            $users = Get-LocalUser -Name 'r*'
            $users | Should -Not -BeNullOrEmpty
            $users | ForEach-Object { $_.Name | Should -BeLike 'r*' }
        }
        It 'returns nothing for nonexistent user' {
            $result = Get-LocalUser -Name 'thereisnosuchuser_xyzzy'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Get-LocalGroup' -Skip:(-not $script:onLinux) {
        It 'returns at least one group' {
            $groups = Get-LocalGroup
            $groups | Should -Not -BeNullOrEmpty
        }
        It 'returns objects with Name property' {
            $groups = Get-LocalGroup
            $groups[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'returns objects with GID property' {
            $groups = Get-LocalGroup
            $groups[0].GID | Should -BeOfType [int]
        }
        It 'root group exists' {
            $root = Get-LocalGroup -Name root
            $root | Should -Not -BeNullOrEmpty
            $root.Name | Should -Be 'root'
        }
        It 'wildcard filter works' {
            $groups = Get-LocalGroup -Name 'r*'
            $groups | Should -Not -BeNullOrEmpty
            $groups | ForEach-Object { $_.Name | Should -BeLike 'r*' }
        }
        It 'returns nothing for nonexistent group' {
            $result = Get-LocalGroup -Name 'thereisnosuchgroup_xyzzy'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Get-LocalGroupMember' -Skip:(-not $script:onLinux) {
        It 'returns members of root group' {
            $members = Get-LocalGroupMember -Group root
            $members | Should -Not -BeNullOrEmpty
        }
        It 'returned members have Name property' {
            $members = Get-LocalGroupMember -Group root
            $members[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'returned members have ObjectClass property' {
            $members = Get-LocalGroupMember -Group root
            $members[0].ObjectClass | Should -Be 'User'
        }
        It 'errors on nonexistent group' {
            { Get-LocalGroupMember -Group 'thereisnosuchgroup_xyzzy' -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Write functions require SupportsShouldProcess' -Skip:(-not $script:onLinux) {
        It '<_> supports -WhatIf' -ForEach $script:writeFunctions {
            $cmd = Get-Command -Module $script:moduleName -Name $_
            $cmd.Parameters.ContainsKey('WhatIf') | Should -BeTrue
        }
    }

    Context 'Write functions do not execute with -WhatIf' -Skip:(-not $script:onLinux) {
        It 'New-LocalUser -WhatIf does not throw' {
            { New-LocalUser -Name 'testuser_whatif_xyzzy' -WhatIf } | Should -Not -Throw
        }
        It 'New-LocalGroup -WhatIf does not throw' {
            { New-LocalGroup -Name 'testgroup_whatif_xyzzy' -WhatIf } | Should -Not -Throw
        }
        It 'Remove-LocalUser -WhatIf does not throw (nonexistent user)' {
            { Remove-LocalUser -Name 'testuser_whatif_xyzzy' -WhatIf } | Should -Not -Throw
        }
    }
}
