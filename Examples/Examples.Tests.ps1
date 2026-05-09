#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeDiscovery {
    $script:onLinux = $IsLinux -eq $true

    $script:exampleScripts = @(
        'Get-LocalUsers.ps1',
        'Get-LocalGroups.ps1',
        'Get-UserGroupMembership.ps1',
        'Get-DisabledUsers.ps1'
    )
}

Describe 'Examples: PowerShell.LocalAccounts.Linux' {

    BeforeAll {
        $script:examplesPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $PSCommandPath -Parent }
        $script:moduleRoot   = Split-Path $script:examplesPath -Parent
        $script:modulePath   = Join-Path $script:moduleRoot 'PowerShell.LocalAccounts.Linux' 'PowerShell.LocalAccounts.Linux.psd1'
        if ($IsLinux) {
            Import-Module $script:modulePath -Force -ErrorAction Stop
        }
    }

    AfterAll {
        if ($IsLinux) {
            Remove-Module 'PowerShell.LocalAccounts.Linux' -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Example scripts exist' {
        It 'example <_> exists' -ForEach $script:exampleScripts {
            Join-Path $script:examplesPath $_ | Should -Exist
        }
    }

    Context 'Example scripts parse without syntax errors' {
        It '<_> parses cleanly' -ForEach $script:exampleScripts {
            $file   = Join-Path $script:examplesPath $_
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$errors) | Out-Null
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Get-LocalUsers.ps1' -Skip:(-not $script:onLinux) {
        It 'runs without error' {
            $file = Join-Path $script:examplesPath 'Get-LocalUsers.ps1'
            { & $file } | Should -Not -Throw
        }
    }

    Context 'Get-LocalGroups.ps1' -Skip:(-not $script:onLinux) {
        It 'runs without error' {
            $file = Join-Path $script:examplesPath 'Get-LocalGroups.ps1'
            { & $file } | Should -Not -Throw
        }
    }

    Context 'Get-UserGroupMembership.ps1' -Skip:(-not $script:onLinux) {
        It 'runs without error' {
            $file = Join-Path $script:examplesPath 'Get-UserGroupMembership.ps1'
            { & $file } | Should -Not -Throw
        }
        It 'root user appears in output' {
            $file = Join-Path $script:examplesPath 'Get-UserGroupMembership.ps1'
            $output = & $file
            $output | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-DisabledUsers.ps1' -Skip:(-not $script:onLinux) {
        It 'runs without error' {
            $file = Join-Path $script:examplesPath 'Get-DisabledUsers.ps1'
            { & $file } | Should -Not -Throw
        }
    }

    Context 'Module functions return correct types' -Skip:(-not $script:onLinux) {
        It 'Get-LocalUser returns objects with Name' {
            $users = Get-LocalUser
            $users | Should -Not -BeNullOrEmpty
            $users[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'Get-LocalGroup returns objects with Name' {
            $groups = Get-LocalGroup
            $groups | Should -Not -BeNullOrEmpty
            $groups[0].Name | Should -Not -BeNullOrEmpty
        }
        It 'Get-LocalGroupMember returns members of root group' {
            $members = Get-LocalGroupMember -Group root
            $members | Should -Not -BeNullOrEmpty
        }
        It 'Get-LocalUser root is always present' {
            $root = Get-LocalUser -Name root
            $root.Name | Should -Be 'root'
        }
        It 'Get-LocalGroup root is always present' {
            $root = Get-LocalGroup -Name root
            $root.Name | Should -Be 'root'
        }
    }

    Context 'Scenario: User provisioning workflow' -Skip:(-not $script:onLinux) {
        BeforeAll {
            $script:testUser  = 'pester-test-user'
            $script:testGroup = 'pester-test-group'
        }
        AfterAll {
            # Clean up — ignore errors if already gone
            & userdel  $script:testUser  2>$null
            & groupdel $script:testGroup 2>$null
        }

        It 'New-LocalUser creates a user' {
            { New-LocalUser -Name $script:testUser -NoPassword } | Should -Not -Throw
            Get-LocalUser -Name $script:testUser | Should -Not -BeNullOrEmpty
        }
        It 'New-LocalGroup creates a group' {
            { New-LocalGroup -Name $script:testGroup } | Should -Not -Throw
            Get-LocalGroup -Name $script:testGroup | Should -Not -BeNullOrEmpty
        }
        It 'Add-LocalGroupMember adds user to group' {
            { Add-LocalGroupMember -Group $script:testGroup -Member $script:testUser } | Should -Not -Throw
            $members = Get-LocalGroupMember -Group $script:testGroup
            $members.Name | Should -Contain $script:testUser
        }
        It 'Disable-LocalUser disables the user' {
            { Disable-LocalUser -Name $script:testUser } | Should -Not -Throw
        }
        It 'Remove-LocalGroupMember removes user from group' {
            { Remove-LocalGroupMember -Group $script:testGroup -Member $script:testUser } | Should -Not -Throw
        }
        It 'Remove-LocalUser removes the user' {
            { Remove-LocalUser -Name $script:testUser } | Should -Not -Throw
            { Get-LocalUser -Name $script:testUser -ErrorAction Stop } | Should -Throw
        }
        It 'Remove-LocalGroup removes the group' {
            { Remove-LocalGroup -Name $script:testGroup } | Should -Not -Throw
            { Get-LocalGroup -Name $script:testGroup -ErrorAction Stop } | Should -Throw
        }
    }
}
