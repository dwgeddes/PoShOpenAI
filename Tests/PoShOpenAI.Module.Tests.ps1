# Module-level tests for PoShOpenAI
Describe 'PoShOpenAI Module Import and Export' {
    It 'Should import the module without error' {
        { Import-Module "$PSScriptRoot/../PoShOpenAI.psd1" -Force -ErrorAction Stop } | Should -Not -Throw
    }
    It 'Should export all expected public functions' {
        Import-Module "$PSScriptRoot/../PoShOpenAI.psd1" -Force
        $expected = @(
            'Invoke-OpenAIPrompt',
            'Send-ChatMessage',
            'New-OpenAIImage',
            'ConvertTo-OpenAISpeech',
            'New-OpenAIEmbedding',
            'Test-OpenAIModeration',
            'Set-OpenAIKey',
            'Get-OpenAIConfig',
            'Add-OpenAIFile',
            'Import-OpenAIAssistantData',
            'Import-OpenAIFineTuneData',
            'Import-OpenAIBatchData',
            'Import-OpenAIVisionData'
        )
        $exported = (Get-Command -Module PoShOpenAI).Name
        foreach ($fn in $expected) {
            $exported | Should -Contain $fn
        }
    }
}

Describe 'Invoke-OpenAIPrompt Parameter Validation' {
    BeforeAll { Import-Module "$PSScriptRoot/../PoShOpenAI.psd1" -Force }
    It 'Should throw on empty prompt' {
        { Invoke-OpenAIPrompt -Prompt '' } | Should -Throw
    }
}
