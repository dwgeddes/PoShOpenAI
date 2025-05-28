# Help and documentation tests for PoShOpenAI
Describe 'PoShOpenAI Help and Examples' {
    BeforeAll { Import-Module "$PSScriptRoot/../PoShOpenAI.psd1" -Force }
    It 'All exported functions should have help' {
        $cmds = Get-Command -Module PoShOpenAI
        foreach ($cmd in $cmds) {
            $help = Get-Help $cmd.Name -ErrorAction SilentlyContinue
            $help | Should -Not -BeNullOrEmpty
        }
    }
    It 'All exported functions should have at least one example' {
        $cmds = Get-Command -Module PoShOpenAI
        foreach ($cmd in $cmds) {
            $help = Get-Help $cmd.Name -ErrorAction SilentlyContinue
            $help.Examples.Example.Count | Should -BeGreaterThan 0
        }
    }
}
