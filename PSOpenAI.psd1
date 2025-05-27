@{
    # Module manifest for PSOpenAI
    RootModule = 'PSOpenAI.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'f8c4e9b2-3d7a-4c5e-9f1b-8e6d4a2c1b9e'
    Author = 'PSOpenAI Module'
    CompanyName = 'Community'
    Copyright = '(c) 2025 PSOpenAI Module Contributors. All rights reserved.'
    Description = 'PowerShell module for interacting with OpenAI APIs (Chat, Images, Embeddings, Audio, Moderation, Files, Assistants, Threads, Runs, Batch, Utilities)'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Set-OpenAIKey', 'Get-OpenAIConfig', 'Set-OpenAIDefaults',
        'Invoke-OpenAIRequest',
        'Invoke-OpenAIChat', 'Send-ChatMessage', 'Start-ChatConversation',
        'Invoke-OpenAIParallelChat', 'Invoke-OpenAIParallelEmbedding',
        'Get-OpenAIModels', 'Get-OpenAIModel',
        'New-OpenAIImage', 'Edit-OpenAIImage', 'New-OpenAIImageVariation',
        'ConvertTo-OpenAISpeech', 'ConvertFrom-OpenAISpeech',
        'New-OpenAIEmbedding',
        'Test-OpenAIModeration',
        'Add-OpenAIFile', 'Get-OpenAIFiles', 'Get-OpenAIFile', 'Remove-OpenAIFile', 'Get-OpenAIFileContent',
        'New-OpenAIFineTuningJob', 'Get-OpenAIFineTuningJobs', 'Get-OpenAIFineTuningJob', 
        'Stop-OpenAIFineTuningJob', 'Get-OpenAIFineTuningEvents',
        'New-OpenAIAssistant', 'Get-OpenAIAssistants', 'Get-OpenAIAssistant', 
        'Update-OpenAIAssistant', 'Remove-OpenAIAssistant',
        'New-OpenAIThread', 'Get-OpenAIThread', 'Update-OpenAIThread', 'Remove-OpenAIThread',
        'Add-OpenAIMessage', 'Get-OpenAIMessages', 'Get-OpenAIMessage', 'Update-OpenAIMessage',
        'Start-OpenAIRun', 'Get-OpenAIRuns', 'Get-OpenAIRun', 'Update-OpenAIRun', 
        'Stop-OpenAIRun', 'Submit-OpenAIToolOutputs', 'Get-OpenAIRunSteps', 'Get-OpenAIRunStep',
        'New-OpenAIBatch', 'Get-OpenAIBatches', 'Get-OpenAIBatch', 'Stop-OpenAIBatch',
        'Get-OpenAIModelDirectory', 'Get-OpenAIModelRecommendations', 'Compare-OpenAIModels',
        'Test-OpenAIConnection', 'Format-OpenAIResponse', 'Save-OpenAIResponse', 'Show-OpenAIExamples'
    )
    PrivateData = @{}
}
