@{
    # Module manifest for PoShOpenAI
    RootModule = 'PoShOpenAI.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'PoShOpenAI'
    CompanyName = 'Community'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'PowerShell module for interacting with OpenAI APIs including GPT, DALL-E, Whisper, and more'
    
    PowerShellVersion = '7.0'
    
    RequiredModules = @()
    
    FunctionsToExport = @(
        'Invoke-OpenAIPrompt'
        'Set-OpenAIKey'
        'Get-OpenAIConfig'
        'Set-OpenAIDefaults'
        'Initialize-OpenAIConfig'
        'Invoke-OpenAIChat'
        'Send-ChatMessage'
        'Start-ChatConversation'
        'Get-OpenAIModels'
        'Get-OpenAIModel'
        'Get-OpenAIModelDirectory'
        'Get-OpenAIModelRecommendations'
        'Compare-OpenAIModels'
        'New-OpenAIImage'
        'Edit-OpenAIImage'
        'ConvertTo-OpenAISpeech'
        'ConvertFrom-OpenAISpeech'
        'New-OpenAIEmbedding'
        'Test-OpenAIModeration'
        'New-OpenAIAssistant'
        'Get-OpenAIAssistants'
        'Get-OpenAIAssistant'
        'Update-OpenAIAssistant'
        'Remove-OpenAIAssistant'
        'Invoke-OpenAIAssistant'
        'Start-AssistantConversation'
        'New-VisionAssistant'
        'Add-OpenAIFile'
        'Import-OpenAIAssistantData'
        'Import-OpenAIFineTuneData'
        'Import-OpenAIBatchData'
        'Import-OpenAIVisionData'
        'Get-OpenAIFiles'
        'Get-OpenAIFile'
        'Remove-OpenAIFile'
        'Get-OpenAIFileContent'
        'Add-OpenAIMessage'
        'Get-OpenAIMessages'
        'Get-OpenAIMessage'
        'Update-OpenAIMessage'
        'New-OpenAIFineTuningJob'
        'Get-OpenAIFineTuningJobs'
        'Get-OpenAIFineTuningJob'
        'Stop-OpenAIFineTuningJob'
        'Get-OpenAIFineTuningEvents'
        'New-OpenAIBatch'
        'Get-OpenAIBatches'
        'Get-OpenAIBatch'
        'Stop-OpenAIBatch'
        'Show-OpenAIExamples'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('OpenAI', 'AI', 'GPT', 'ChatGPT', 'DALL-E', 'Whisper', 'API', 'MachineLearning')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release with comprehensive OpenAI API support'
        }
    }
}
