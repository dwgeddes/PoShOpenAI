# PSOpenAI.psm1
# Main module file that imports all public and private functions

#region PSOpenAI Module

# Import private functions first
$PrivateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
    }
    catch {
        Write-Error "Failed to import private function $($Function.Name): $($_.Exception.Message)"
    }
}

# Import public functions
$PublicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
    }
    catch {
        Write-Error "Failed to import public function $($Function.Name): $($_.Exception.Message)"
    }
}

# Export public functions
$FunctionsToExport = @(
    # Core unified interface
    'Invoke-OpenAIPrompt'
    
    # Configuration
    'Set-OpenAIKey'
    'Get-OpenAIConfig'
    'Set-OpenAIDefaults'
    'Initialize-OpenAIConfig'
    
    # Chat
    'Invoke-OpenAIChat'
    'Send-ChatMessage'
    'Start-ChatConversation'
    
    # Models
    'Get-OpenAIModels'
    'Get-OpenAIModel'
    'Get-OpenAIModelDirectory'
    'Get-OpenAIModelRecommendations'
    'Compare-OpenAIModels'
    
    # Images
    'New-OpenAIImage'
    'Edit-OpenAIImage'
    
    # Audio
    'ConvertTo-OpenAISpeech'
    'ConvertFrom-OpenAISpeech'
    
    # Embeddings
    'New-OpenAIEmbedding'
    
    # Moderation
    'Test-OpenAIModeration'
    
    # Assistants
    'New-OpenAIAssistant'
    'Get-OpenAIAssistants'
    'Get-OpenAIAssistant'
    'Update-OpenAIAssistant'
    'Remove-OpenAIAssistant'
    'Invoke-OpenAIAssistant'
    'Start-AssistantConversation'
    'New-VisionAssistant'
    
    # Files
    'Add-OpenAIFile'
    'Import-OpenAIAssistantData'
    'Import-OpenAIFineTuneData'
    'Import-OpenAIBatchData'
    'Import-OpenAIVisionData'
    'Get-OpenAIFiles'
    'Get-OpenAIFile'
    'Remove-OpenAIFile'
    'Get-OpenAIFileContent'
    
    # Messages
    'Add-OpenAIMessage'
    'Get-OpenAIMessages'
    'Get-OpenAIMessage'
    'Update-OpenAIMessage'
    
    # Fine-tuning
    'New-OpenAIFineTuningJob'
    'Get-OpenAIFineTuningJobs'
    'Get-OpenAIFineTuningJob'
    'Stop-OpenAIFineTuningJob'
    'Get-OpenAIFineTuningEvents'
    
    # Batch
    'New-OpenAIBatch'
    'Get-OpenAIBatches'
    'Get-OpenAIBatch'
    'Stop-OpenAIBatch'
    
    # Examples
    'Show-OpenAIExamples'
)

Export-ModuleMember -Function $FunctionsToExport

#endregion
