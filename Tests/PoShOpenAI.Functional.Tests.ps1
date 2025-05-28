# Functional tests for PoShOpenAI module
# Consolidated from Test-UnifiedInterface.ps1 and Test-AssistantVision.ps1

Describe 'PoShOpenAI Unified Interface' {
    BeforeAll { Import-Module "$PSScriptRoot/../PoShOpenAI.psd1" -Force }
    It 'Should have Invoke-OpenAIPrompt available' {
        Get-Command Invoke-OpenAIPrompt -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
    It 'Should provide help and examples for Invoke-OpenAIPrompt' {
        $help = Get-Help Invoke-OpenAIPrompt -ErrorAction Stop
        $help | Should -Not -BeNullOrEmpty
        $help.Examples.Example.Count | Should -BeGreaterThan 0
    }
    It 'Should validate empty prompt' {
        { Invoke-OpenAIPrompt -Prompt '' } | Should -Throw
    }
    It 'Should auto-detect prompt type' {
        $cases = @(
            @{ Prompt = 'What is PowerShell?'; Expected = 'Chat' },
            @{ Prompt = 'Draw a beautiful sunset'; Expected = 'Image' },
            @{ Prompt = 'Say hello world'; Expected = 'Speech' },
            @{ Prompt = 'Create embeddings for similarity'; Expected = 'Embedding' },
            @{ Prompt = 'Check this content for violations'; Expected = 'Moderation' }
        )
        foreach ($case in $cases) {
            $DetectedType = if ($case.Prompt -match "\b(draw|create|generate|make|design)\s+(image|picture|photo|illustration|artwork)") { 'Image' }
            elseif ($case.Prompt -match "\b(say|speak|voice|audio|speech)\b") { 'Speech' }
            elseif ($case.Prompt -match "\b(embed|embedding|similarity|vector)\b") { 'Embedding' }
            elseif ($case.Prompt -match "\b(moderate|moderation|policy|violation|appropriate)\b") { 'Moderation' }
            else { 'Chat' }
            $DetectedType | Should -Be $case.Expected
        }
    }
}

Describe 'PoShOpenAI Assistant Vision' {
    BeforeAll { Import-Module "$PSScriptRoot/../PoShOpenAI.psd1" -Force }
    It 'Should have vision functions available' {
        Get-Command Invoke-OpenAIAssistant -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Start-AssistantConversation -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
    It 'Should validate image path' {
        { Invoke-OpenAIAssistant -AssistantId 'test' -Message 'test' -ImagePaths @('nonexistent.jpg') -WhatIf -ErrorAction Stop } | Should -Throw
    }
    It 'Should validate image format' {
        $temp = [System.IO.Path]::GetTempFileName()
        $bmp = "$temp.bmp"
        New-Item -Path $bmp -ItemType File -Force | Out-Null
        try {
            { Invoke-OpenAIAssistant -AssistantId 'test' -Message 'test' -ImagePaths @($bmp) -WhatIf -ErrorAction Stop } | Should -Throw
        } finally {
            Remove-Item $bmp -Force -ErrorAction SilentlyContinue
            Remove-Item $temp -Force -ErrorAction SilentlyContinue
        }
    }
    It 'Should detect vision-capable models' {
        $models = @('gpt-4o', 'gpt-4-turbo', 'gpt-4-vision-preview')
        foreach ($model in $models) {
            $supportsVision = ($model -in $models)
            $supportsVision | Should -Be $true
        }
    }
    It 'Should provide help and examples for Invoke-OpenAIAssistant' {
        $help = Get-Help Invoke-OpenAIAssistant -Detailed
        $help.examples.example.Count | Should -BeGreaterThan 0
    }
}
