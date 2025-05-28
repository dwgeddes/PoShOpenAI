#region Unified Prompt Interface

function Invoke-OpenAIPrompt {
    <#
    .SYNOPSIS
    Unified, user-friendly interface for OpenAI interactions with smart routing
    
    .DESCRIPTION
    A single function that intelligently routes requests to the appropriate OpenAI service
    based on the type of request and parameters provided. Supports chat, image generation,
    embeddings, moderation, and more through a single, consistent interface.
    
    .PARAMETER Prompt
    The main prompt or question - supports pipeline input
    
    .PARAMETER Type
    Type of OpenAI service to use (auto-detected if not specified)
    
    .PARAMETER Model
    Specific model to use (auto-selected if not specified)
    
    .PARAMETER SystemMessage
    System context for chat interactions
    
    .PARAMETER ImagePaths
    Local image file paths for vision analysis
    
    .PARAMETER OutputPath
    Path for saving generated content (images, audio)
    
    .PARAMETER Temperature
    Creativity level (0.0 = focused, 1.0 = creative)
    
    .PARAMETER MaxTokens
    Maximum response length
    
    .PARAMETER Quality
    Quality level for generated content
    
    .PARAMETER Voice
    Voice for text-to-speech
    
    .EXAMPLE
    Invoke-OpenAIPrompt "What is PowerShell?"
    
    .EXAMPLE
    "Question 1", "Question 2" | Invoke-OpenAIPrompt -SystemMessage "You are a helpful assistant"
    
    .EXAMPLE
    Invoke-OpenAIPrompt "A sunset over mountains" -Type "Image" -Quality "hd"
    
    .EXAMPLE
    Invoke-OpenAIPrompt "Hello world" -Type "Speech" -Voice "nova"
    
    .EXAMPLE
    Invoke-OpenAIPrompt "What's in this image?" -ImagePaths @("photo.jpg") -Type "Vision"
    
    .EXAMPLE
    Invoke-OpenAIPrompt "Create embeddings for similarity" -Type "Embedding"
    
    .EXAMPLE
    Invoke-OpenAIPrompt "Check this content for policy violations" -Type "Moderation"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Prompt,
        
        [Parameter()]
        [ValidateSet("Auto", "Chat", "Image", "Speech", "Transcription", "Embedding", "Moderation", "Vision")]
        [string]$Type = "Auto",
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Model = $null,
        
        [Parameter()]
        [string]$SystemMessage = $null,
        
        [Parameter()]
        [ValidateScript({
            foreach ($path in $_) {
                if (-not (Test-Path $path -PathType Leaf)) {
                    throw "Image file not found: $path"
                }
                $extension = [System.IO.Path]::GetExtension($path).ToLower()
                if ($extension -notin @('.jpg', '.jpeg', '.png', '.gif', '.webp')) {
                    throw "Unsupported image format: $extension. Supported formats: .jpg, .jpeg, .png, .gif, .webp"
                }
            }
            return $true
        })]
        [string[]]$ImagePaths = @(),
        
        [Parameter()]
        [string]$OutputPath = $null,
        
        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature = $Global:OpenAIConfig.Temperature,
        
        [Parameter()]
        [ValidateRange(1, 4096)]
        [int]$MaxTokens = $Global:OpenAIConfig.MaxTokens,
        
        [Parameter()]
        [ValidateSet("standard", "hd")]
        [string]$Quality = "standard",
        
        [Parameter()]
        [ValidateSet("alloy", "echo", "fable", "onyx", "nova", "shimmer")]
        [string]$Voice = "alloy"
    )
    
    begin {
        # Ensure API key is configured
        if (-not (Initialize-OpenAIConfig -Quiet)) {
            Write-OpenAIError -Message "OpenAI API key not configured. Use Set-OpenAIKey or set OPENAI_API_KEY environment variable." -Category AuthenticationError -ErrorId "ApiKeyNotConfigured"
            return
        }
    }
    
    process {
        foreach ($PromptText in $Prompt) {
            try {
                # Auto-detect type if not specified
                $DetectedType = if ($Type -eq "Auto") {
                    if ($ImagePaths.Count -gt 0) { "Vision" }
                    elseif ($PromptText -match "\b(draw|create|generate|make|design)\s+(image|picture|photo|illustration|artwork)") { "Image" }
                    elseif ($PromptText -match "\b(say|speak|voice|audio|speech)\b") { "Speech" }
                    elseif ($PromptText -match "\b(transcribe|speech to text|audio to text)\b") { "Transcription" }
                    elseif ($PromptText -match "\b(embed|embedding|similarity|vector)\b") { "Embedding" }
                    elseif ($PromptText -match "\b(moderate|moderation|policy|violation|appropriate)\b") { "Moderation" }
                    else { "Chat" }
                } else { $Type }
                
                # Route to appropriate service
                switch ($DetectedType) {
                    "Chat" {
                        try {
                            $ChatParams = @{
                                Message = $PromptText
                                Model = if ($Model) { $Model } else { $Global:OpenAIConfig.DefaultModel }
                                Temperature = $Temperature
                                MaxTokens = $MaxTokens
                            }
                            if ($SystemMessage) { $ChatParams.SystemMessage = $SystemMessage }
                            
                            $Results = Send-ChatMessage @ChatParams
                            $Result = $Results | Select-Object -First 1
                            
                            [PSCustomObject]@{
                                Type = "Chat"
                                Input = $PromptText
                                Output = $Result.Response
                                Model = $Result.Model
                                Success = $Result.Success
                                Error = $Result.Error
                                TokensUsed = $Result.TotalTokens
                                EstimatedCost = $Result.EstimatedCost
                                ProcessedAt = $Result.ProcessedAt
                                FinishReason = $Result.FinishReason
                                ResponseRole = $Result.ResponseRole
                                PipelineIndex = [Array]::IndexOf($Prompt, $PromptText)
                            }
                        }
                        catch {
                            throw "Chat processing failed: $($_.Exception.Message)"
                        }
                    }
                    
                    "Image" {
                        try {
                            $ImageParams = @{
                                Prompt = $PromptText
                                Model = if ($Model) { $Model } else { "dall-e-3" }
                                Quality = $Quality
                            }
                            if ($OutputPath) { 
                                $ImageParams.OutputPath = $OutputPath 
                            }
                            
                            $Results = New-OpenAIImage @ImageParams
                            $Result = $Results | Select-Object -First 1
                            
                            [PSCustomObject]@{
                                Type = "Image"
                                Input = $PromptText
                                Output = $Result.ImageUrl
                                OutputPath = $Result.ImageUrl
                                Model = $Result.Model
                                Success = $Result.Success
                                Error = $Result.Error
                                EstimatedCost = $Result.EstimatedCost
                                ProcessedAt = $Result.GeneratedAt
                                Quality = $Result.Quality
                                Size = $Result.ActualSize
                                RevisedPrompt = $Result.RevisedPrompt
                                PipelineIndex = [Array]::IndexOf($Prompt, $PromptText)
                            }
                        }
                        catch {
                            throw "Image generation failed: $($_.Exception.Message)"
                        }
                    }
                    
                    "Speech" {
                        try {
                            $SpeechParams = @{
                                Text = $PromptText
                                Voice = $Voice
                                Model = if ($Model) { $Model } else { "tts-1" }
                            }
                            if ($OutputPath) { $SpeechParams.OutputPath = $OutputPath }
                            
                            $Results = ConvertTo-OpenAISpeech @SpeechParams
                            $Result = $Results | Select-Object -First 1
                            
                            [PSCustomObject]@{
                                Type = "Speech"
                                Input = $PromptText
                                Output = $Result.OutputPath
                                Voice = $Result.Voice
                                Model = $Result.Model
                                Success = (-not $Result.Error)
                                Error = $Result.Error
                                ProcessedAt = $Result.ProcessedAt
                                FileSizeBytes = $Result.FileSizeBytes
                                ResponseFormat = $Result.ResponseFormat
                                PipelineIndex = [Array]::IndexOf($Prompt, $PromptText)
                            }
                        }
                        catch {
                            throw "Speech generation failed: $($_.Exception.Message)"
                        }
                    }
                    
                    "Embedding" {
                        try {
                            $EmbeddingParams = @{
                                Text = $PromptText
                                Model = if ($Model) { $Model } else { "text-embedding-3-small" }
                            }
                            
                            $Results = New-OpenAIEmbedding @EmbeddingParams
                            $Result = $Results | Select-Object -First 1
                            
                            [PSCustomObject]@{
                                Type = "Embedding"
                                Input = $PromptText
                                Output = $Result.Embedding
                                Model = $Result.Model
                                Dimensions = $Result.EmbeddingLength
                                Success = $Result.Success
                                Error = $Result.Error
                                EstimatedCost = $Result.EstimatedCost
                                ProcessedAt = $Result.ProcessedAt
                                EmbeddingMagnitude = $Result.EmbeddingMagnitude
                                TokensUsed = $Result.TotalTokens
                                PipelineIndex = [Array]::IndexOf($Prompt, $PromptText)
                            }
                        }
                        catch {
                            throw "Embedding generation failed: $($_.Exception.Message)"
                        }
                    }
                    
                    "Moderation" {
                        try {
                            $ModerationParams = @{
                                Text = $PromptText
                                Model = if ($Model) { $Model } else { "text-moderation-latest" }
                            }
                            
                            $Results = Test-OpenAIModeration @ModerationParams
                            $Result = $Results | Select-Object -First 1
                            
                            [PSCustomObject]@{
                                Type = "Moderation"
                                Input = $PromptText
                                Output = $Result.SafetyLevel
                                Flagged = $Result.Flagged
                                Categories = $Result.FlaggedCategories
                                HighestRisk = $Result.HighestRiskCategory
                                RiskScore = $Result.HighestRiskScore
                                Success = $Result.Success
                                Error = $Result.Error
                                ProcessedAt = $Result.ProcessedAt
                                IsCompliant = $Result.IsCompliant
                                RequiresReview = $Result.RequiresReview
                                PipelineIndex = [Array]::IndexOf($Prompt, $PromptText)
                            }
                        }
                        catch {
                            throw "Content moderation failed: $($_.Exception.Message)"
                        }
                    }
                    
                    "Vision" {
                        if ($ImagePaths.Count -eq 0) {
                            throw "Vision analysis requires ImagePaths parameter"
                        }
                        
                        try {
                            # Try to find a vision-capable assistant or create one
                            $Assistants = Get-OpenAIAssistants
                            $VisionAssistant = $Assistants.data | Where-Object { 
                                $_.model -in @("gpt-4o", "gpt-4-turbo", "gpt-4-vision-preview") 
                            } | Select-Object -First 1
                            
                            if (-not $VisionAssistant) {
                                Write-Warning "No vision-capable assistant found. Creating a temporary one..."
                                $VisionAssistant = New-VisionAssistant -Name "Unified Vision Assistant" -Instructions "You are a helpful assistant that can analyze images." -Model "gpt-4o"
                            }
                            
                            $VisionParams = @{
                                AssistantId = $VisionAssistant.id
                                Message = $PromptText
                                ImagePaths = $ImagePaths
                            }
                            
                            $Result = Invoke-OpenAIAssistant @VisionParams
                            
                            [PSCustomObject]@{
                                Type = "Vision"
                                Input = $PromptText
                                Output = $Result.Response
                                ImagePaths = $ImagePaths
                                AssistantId = $VisionAssistant.id
                                Success = $Result.Success
                                Error = $Result.Error
                                ProcessedAt = $Result.ProcessedAt
                                Model = $Result.Model
                                TokensUsed = $Result.TotalTokens
                                ProcessingTime = $Result.ProcessingTime
                                SupportsVision = $Result.SupportsVision
                                PipelineIndex = [Array]::IndexOf($Prompt, $PromptText)
                            }
                        }
                        catch {
                            [PSCustomObject]@{
                                Type = "Vision"
                                Input = $PromptText
                                Output = $null
                                ImagePaths = $ImagePaths
                                Success = $false
                                Error = "Vision analysis failed: $($_.Exception.Message). Use Invoke-OpenAIAssistant directly for advanced vision workflows."
                                ProcessedAt = Get-Date
                                PipelineIndex = [Array]::IndexOf($Prompt, $PromptText)
                            }
                        }
                    }
                    
                    default {
                        throw "Unknown or unsupported type: $DetectedType"
                    }
                }
            }
            catch {
                Write-OpenAIError -Message "Failed to process prompt '$PromptText': $($_.Exception.Message)" -Exception $_.Exception -Category InvalidOperation -ErrorId "PromptProcessingError" -TargetObject $PromptText
                
                [PSCustomObject]@{
                    Type = $DetectedType
                    Input = $PromptText
                    Output = $null
                    Success = $false
                    Error = $_.Exception.Message
                    ErrorType = $_.Exception.GetType().Name
                    ProcessedAt = Get-Date
                    PipelineIndex = [Array]::IndexOf($Prompt, $PromptText)
                    TotalPrompts = $Prompt.Count
                }
            }
        }
    }
}

#endregion
