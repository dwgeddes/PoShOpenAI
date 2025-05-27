#region Model Directory Functions

function Get-OpenAIModelDirectory {
    <#
    .SYNOPSIS
    Provides a comprehensive directory of all available OpenAI models with capabilities and pricing
    .PARAMETER Category
    Filter by model category (Chat, Embedding, Image, Audio, Moderation, All)
    .PARAMETER IncludePricing
    Include detailed pricing information
    .PARAMETER IncludeDeprecated
    Include deprecated models in the results
    .PARAMETER Format
    Output format (Table, List, Grid)
    .EXAMPLE
    Get-OpenAIModelDirectory
    .EXAMPLE
    Get-OpenAIModelDirectory -Category "Chat" -IncludePricing
    .EXAMPLE
    Get-OpenAIModelDirectory -Format "Grid" | Out-GridView
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("All", "Chat", "Embedding", "Image", "Audio", "Moderation")]
        [string]$Category = "All",
        
        [Parameter()]
        [switch]$IncludePricing,
        
        [Parameter()]
        [switch]$IncludeDeprecated,
        
        [Parameter()]
        [ValidateSet("Table", "List", "Grid")]
        [string]$Format = "Table"
    )
    
    # Comprehensive model database (as of January 2025)
    $ModelDatabase = @(
        # Chat/Language Models
        @{
            ModelId = "gpt-4o"
            Name = "GPT-4 Omni"
            Category = "Chat"
            Description = "Most capable model for complex reasoning tasks"
            MaxTokens = 128000
            InputCostPer1K = 0.005
            OutputCostPer1K = 0.015
            TrainingData = "Up to Oct 2023"
            Capabilities = @("Text", "Vision", "Function Calling", "JSON Mode")
            UseCase = "Complex analysis, coding, research, multimodal tasks"
            Speed = "Fast"
            Quality = "Highest"
            Recommended = $false
            Deprecated = $false
            Notes = "Most advanced model with vision capabilities"
        },
        @{
            ModelId = "gpt-4o-mini"
            Name = "GPT-4 Omni Mini"
            Category = "Chat"
            Description = "Cost-effective model balancing quality and speed"
            MaxTokens = 128000
            InputCostPer1K = 0.00015
            OutputCostPer1K = 0.0006
            TrainingData = "Up to Oct 2023"
            Capabilities = @("Text", "Vision", "Function Calling", "JSON Mode")
            UseCase = "General tasks, high-volume applications, cost optimization"
            Speed = "Very Fast"
            Quality = "High"
            Recommended = $true
            Deprecated = $false
            Notes = "Best balance of cost and performance - recommended default"
        },
        @{
            ModelId = "gpt-4"
            Name = "GPT-4"
            Category = "Chat"
            Description = "High-intelligence model for complex tasks"
            MaxTokens = 8192
            InputCostPer1K = 0.03
            OutputCostPer1K = 0.06
            TrainingData = "Up to Sep 2021"
            Capabilities = @("Text", "Function Calling")
            UseCase = "Complex reasoning, analysis, creative writing"
            Speed = "Moderate"
            Quality = "Very High"
            Recommended = $false
            Deprecated = $false
            Notes = "Original GPT-4, consider gpt-4o for new projects"
        },
        @{
            ModelId = "gpt-4-turbo"
            Name = "GPT-4 Turbo"
            Category = "Chat"
            Description = "Enhanced GPT-4 with larger context window"
            MaxTokens = 128000
            InputCostPer1K = 0.01
            OutputCostPer1K = 0.03
            TrainingData = "Up to Apr 2024"
            Capabilities = @("Text", "Vision", "Function Calling", "JSON Mode")
            UseCase = "Long documents, detailed analysis, coding projects"
            Speed = "Fast"
            Quality = "Very High"
            Recommended = $false
            Deprecated = $false
            Notes = "Larger context window than standard GPT-4"
        },
        @{
            ModelId = "gpt-3.5-turbo"
            Name = "GPT-3.5 Turbo"
            Category = "Chat"
            Description = "Fast and cost-effective for simple tasks"
            MaxTokens = 16385
            InputCostPer1K = 0.0005
            OutputCostPer1K = 0.0015
            TrainingData = "Up to Sep 2021"
            Capabilities = @("Text", "Function Calling")
            UseCase = "Simple conversations, basic tasks, high-volume processing"
            Speed = "Very Fast"
            Quality = "Good"
            Recommended = $false
            Deprecated = $false
            Notes = "Cost-effective for simple tasks, consider gpt-4o-mini instead"
        },
        
        # Embedding Models
        @{
            ModelId = "text-embedding-3-small"
            Name = "Text Embedding 3 Small"
            Category = "Embedding"
            Description = "Improved performance over ada-002"
            MaxTokens = 8191
            InputCostPer1K = 0.00002
            OutputCostPer1K = 0
            TrainingData = "Up to Sep 2021"
            Capabilities = @("Text Embeddings", "Dimension Reduction")
            UseCase = "Semantic search, clustering, recommendations"
            Speed = "Fast"
            Quality = "High"
            Recommended = $true
            Deprecated = $false
            Notes = "1536 dimensions, best balance of cost and performance"
            Dimensions = 1536
            MaxDimensions = 1536
        },
        @{
            ModelId = "text-embedding-3-large"
            Name = "Text Embedding 3 Large"
            Category = "Embedding"
            Description = "Most capable embedding model"
            MaxTokens = 8191
            InputCostPer1K = 0.00013
            OutputCostPer1K = 0
            TrainingData = "Up to Sep 2021"
            Capabilities = @("Text Embeddings", "Dimension Reduction")
            UseCase = "Complex semantic tasks, high-precision similarity"
            Speed = "Moderate"
            Quality = "Highest"
            Recommended = $false
            Deprecated = $false
            Notes = "3072 dimensions, highest quality embeddings"
            Dimensions = 3072
            MaxDimensions = 3072
        },
        @{
            ModelId = "text-embedding-ada-002"
            Name = "Text Embedding Ada 002"
            Category = "Embedding"
            Description = "Second generation embedding model"
            MaxTokens = 8191
            InputCostPer1K = 0.0001
            OutputCostPer1K = 0
            TrainingData = "Up to Sep 2021"
            Capabilities = @("Text Embeddings")
            UseCase = "Legacy embedding tasks"
            Speed = "Fast"
            Quality = "Good"
            Recommended = $false
            Deprecated = $false
            Notes = "Consider text-embedding-3-small for new projects"
            Dimensions = 1536
            MaxDimensions = 1536
        },
        
        # Image Models
        @{
            ModelId = "dall-e-3"
            Name = "DALL-E 3"
            Category = "Image"
            Description = "Most advanced image generation model"
            MaxTokens = 4000
            InputCostPer1K = 0
            OutputCostPer1K = 0
            TrainingData = "Various image datasets"
            Capabilities = @("Image Generation", "Prompt Enhancement", "Style Control")
            UseCase = "High-quality image creation, artistic work"
            Speed = "Moderate"
            Quality = "Highest"
            Recommended = $true
            Deprecated = $false
            Notes = "1024x1024 ($0.040), 1024x1792/1792x1024 ($0.080), HD quality available"
            ImageSizes = @("1024x1024", "1024x1792", "1792x1024")
            StandardCost = @{"1024x1024" = 0.040; "1024x1792" = 0.080; "1792x1024" = 0.080}
            HDCost = @{"1024x1024" = 0.080; "1024x1792" = 0.120; "1792x1024" = 0.120}
        },
        @{
            ModelId = "dall-e-2"
            Name = "DALL-E 2"
            Category = "Image"
            Description = "Previous generation image model"
            MaxTokens = 1000
            InputCostPer1K = 0
            OutputCostPer1K = 0
            TrainingData = "Various image datasets"
            Capabilities = @("Image Generation", "Image Variations", "Multiple Images")
            UseCase = "Cost-effective image generation, multiple variations"
            Speed = "Fast"
            Quality = "Good"
            Recommended = $false
            Deprecated = $false
            Notes = "256x256 ($0.016), 512x512 ($0.018), 1024x1024 ($0.020)"
            ImageSizes = @("256x256", "512x512", "1024x1024")
            StandardCost = @{"256x256" = 0.016; "512x512" = 0.018; "1024x1024" = 0.020}
        },
        
        # Audio Models
        @{
            ModelId = "tts-1"
            Name = "Text-to-Speech 1"
            Category = "Audio"
            Description = "Standard quality text-to-speech"
            MaxTokens = 4096
            InputCostPer1K = 0.015
            OutputCostPer1K = 0
            TrainingData = "Various audio datasets"
            Capabilities = @("Text-to-Speech", "Multiple Voices", "Speed Control")
            UseCase = "Voiceovers, accessibility, content creation"
            Speed = "Fast"
            Quality = "Good"
            Recommended = $true
            Deprecated = $false
            Notes = "6 voices available, $0.015 per 1K characters"
            Voices = @("alloy", "echo", "fable", "onyx", "nova", "shimmer")
        },
        @{
            ModelId = "tts-1-hd"
            Name = "Text-to-Speech 1 HD"
            Category = "Audio"
            Description = "Higher quality text-to-speech"
            MaxTokens = 4096
            InputCostPer1K = 0.030
            OutputCostPer1K = 0
            TrainingData = "Various audio datasets"
            Capabilities = @("Text-to-Speech", "Multiple Voices", "Speed Control", "High Quality")
            UseCase = "Professional audio, high-quality voiceovers"
            Speed = "Moderate"
            Quality = "High"
            Recommended = $false
            Deprecated = $false
            Notes = "6 voices available, $0.030 per 1K characters, 2x cost of tts-1"
            Voices = @("alloy", "echo", "fable", "onyx", "nova", "shimmer")
        },
        @{
            ModelId = "whisper-1"
            Name = "Whisper"
            Category = "Audio"
            Description = "Speech-to-text transcription model"
            MaxTokens = $null
            InputCostPer1K = 0
            OutputCostPer1K = 0
            TrainingData = "Multilingual audio datasets"
            Capabilities = @("Speech-to-Text", "Translation", "Multiple Languages")
            UseCase = "Audio transcription, meeting notes, accessibility"
            Speed = "Fast"
            Quality = "High"
            Recommended = $true
            Deprecated = $false
            Notes = "$0.006 per minute, supports 50+ languages"
            CostPerMinute = 0.006
            Languages = "50+ languages supported"
        },
        
        # Moderation Models
        @{
            ModelId = "text-moderation-latest"
            Name = "Text Moderation Latest"
            Category = "Moderation"
            Description = "Latest content moderation model"
            MaxTokens = 32768
            InputCostPer1K = 0
            OutputCostPer1K = 0
            TrainingData = "Content safety datasets"
            Capabilities = @("Content Classification", "Safety Detection", "Policy Compliance")
            UseCase = "Content filtering, safety checks, compliance"
            Speed = "Very Fast"
            Quality = "High"
            Recommended = $true
            Deprecated = $false
            Notes = "Free to use, most up-to-date safety detection"
            Categories = @("hate", "harassment", "self-harm", "sexual", "violence")
        },
        @{
            ModelId = "text-moderation-stable"
            Name = "Text Moderation Stable"
            Category = "Moderation"
            Description = "Stable version of content moderation"
            MaxTokens = 32768
            InputCostPer1K = 0
            OutputCostPer1K = 0
            TrainingData = "Content safety datasets"
            Capabilities = @("Content Classification", "Safety Detection", "Policy Compliance")
            UseCase = "Production systems requiring stability"
            Speed = "Very Fast"
            Quality = "High"
            Recommended = $false
            Deprecated = $false
            Notes = "Free to use, consistent behavior over time"
            Categories = @("hate", "harassment", "self-harm", "sexual", "violence")
        }
    )
    
    # Filter by category if specified
    if ($Category -ne "All") {
        $ModelDatabase = $ModelDatabase | Where-Object { $_.Category -eq $Category }
    }
    
    # Filter deprecated models if not requested
    if (-not $IncludeDeprecated) {
        $ModelDatabase = $ModelDatabase | Where-Object { -not $_.Deprecated }
    }
    
    # Create output objects
    $Results = foreach ($Model in $ModelDatabase) {
        $OutputObject = [PSCustomObject]@{
            ModelId = $Model.ModelId
            Name = $Model.Name
            Category = $Model.Category
            Description = $Model.Description
            Quality = $Model.Quality
            Speed = $Model.Speed
            Recommended = $Model.Recommended
            UseCase = $Model.UseCase
            Capabilities = $Model.Capabilities -join ", "
            MaxTokens = $Model.MaxTokens
            TrainingData = $Model.TrainingData
            Deprecated = $Model.Deprecated
            Notes = $Model.Notes
        }
        
        # Add pricing information if requested
        if ($IncludePricing) {
            $OutputObject | Add-Member -NotePropertyName "InputCostPer1K" -NotePropertyValue $Model.InputCostPer1K
            $OutputObject | Add-Member -NotePropertyName "OutputCostPer1K" -NotePropertyValue $Model.OutputCostPer1K
            
            # Add model-specific pricing details
            switch ($Model.Category) {
                "Image" {
                    if ($Model.StandardCost) {
                        $OutputObject | Add-Member -NotePropertyName "ImageSizes" -NotePropertyValue ($Model.ImageSizes -join ", ")
                        $OutputObject | Add-Member -NotePropertyName "StandardCost" -NotePropertyValue ($Model.StandardCost.GetEnumerator() | ForEach-Object { "$($_.Key): `$($_.Value)" } | Join-String -Separator ", ")
                        if ($Model.HDCost) {
                            $OutputObject | Add-Member -NotePropertyName "HDCost" -NotePropertyValue ($Model.HDCost.GetEnumerator() | ForEach-Object { "$($_.Key): `$($_.Value)" } | Join-String -Separator ", ")
                        }
                    }
                }
                "Audio" {
                    if ($Model.CostPerMinute) {
                        $OutputObject | Add-Member -NotePropertyName "CostPerMinute" -NotePropertyValue $Model.CostPerMinute
                    }
                    if ($Model.Voices) {
                        $OutputObject | Add-Member -NotePropertyName "AvailableVoices" -NotePropertyValue ($Model.Voices -join ", ")
                    }
                    if ($Model.Languages) {
                        $OutputObject | Add-Member -NotePropertyName "Languages" -NotePropertyValue $Model.Languages
                    }
                }
                "Embedding" {
                    if ($Model.Dimensions) {
                        $OutputObject | Add-Member -NotePropertyName "Dimensions" -NotePropertyValue $Model.Dimensions
                        $OutputObject | Add-Member -NotePropertyName "MaxDimensions" -NotePropertyValue $Model.MaxDimensions
                    }
                }
                "Moderation" {
                    if ($Model.Categories) {
                        $OutputObject | Add-Member -NotePropertyName "SafetyCategories" -NotePropertyValue ($Model.Categories -join ", ")
                    }
                }
            }
        }
        
        $OutputObject
    }
    
    # Format output based on requested format
    switch ($Format) {
        "Table" {
            if ($IncludePricing) {
                $Results | Format-Table -AutoSize
            } else {
                $Results | Select-Object ModelId, Category, Quality, Speed, Recommended, UseCase | Format-Table -AutoSize
            }
        }
        "List" {
            $Results | Format-List
        }
        "Grid" {
            $Results
        }
        default {
            $Results
        }
    }
}

function Get-OpenAIModelRecommendations {
    <#
    .SYNOPSIS
    Provides model recommendations based on use case and requirements
    .PARAMETER UseCase
    Primary use case for the model
    .PARAMETER Budget
    Budget consideration (Low, Medium, High)
    .PARAMETER Quality
    Quality requirement (Good, High, Highest)
    .PARAMETER Speed
    Speed requirement (Fast, Moderate, Any)
    .EXAMPLE
    Get-OpenAIModelRecommendations -UseCase "Chat" -Budget "Low"
    .EXAMPLE
    Get-OpenAIModelRecommendations -UseCase "Embedding" -Quality "Highest"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Chat", "Embedding", "ImageGeneration", "TextToSpeech", "SpeechToText", "Moderation")]
        [string]$UseCase,
        
        [Parameter()]
        [ValidateSet("Low", "Medium", "High")]
        [string]$Budget = "Medium",
        
        [Parameter()]
        [ValidateSet("Good", "High", "Highest")]
        [string]$Quality = "High",
        
        [Parameter()]
        [ValidateSet("Fast", "Moderate", "Any")]
        [string]$Speed = "Any"
    )
    
    $Recommendations = @{
        "Chat" = @{
            "Low" = @{
                "Primary" = "gpt-4o-mini"
                "Alternative" = "gpt-3.5-turbo"
                "Reasoning" = "gpt-4o-mini offers excellent quality at 20x lower cost than gpt-4o"
            }
            "Medium" = @{
                "Primary" = "gpt-4o-mini"
                "Alternative" = "gpt-4-turbo"
                "Reasoning" = "gpt-4o-mini provides best balance, upgrade to gpt-4-turbo for complex tasks"
            }
            "High" = @{
                "Primary" = "gpt-4o"
                "Alternative" = "gpt-4-turbo"
                "Reasoning" = "gpt-4o offers highest capability with multimodal support"
            }
        }
        "Embedding" = @{
            "Low" = @{
                "Primary" = "text-embedding-3-small"
                "Alternative" = "text-embedding-ada-002"
                "Reasoning" = "text-embedding-3-small offers best price/performance ratio"
            }
            "Medium" = @{
                "Primary" = "text-embedding-3-small"
                "Alternative" = "text-embedding-3-large"
                "Reasoning" = "text-embedding-3-small handles most use cases effectively"
            }
            "High" = @{
                "Primary" = "text-embedding-3-large"
                "Alternative" = "text-embedding-3-small"
                "Reasoning" = "text-embedding-3-large provides highest quality embeddings"
            }
        }
        "ImageGeneration" = @{
            "Low" = @{
                "Primary" = "dall-e-2"
                "Alternative" = "dall-e-3"
                "Reasoning" = "dall-e-2 is more cost-effective for basic image generation"
            }
            "Medium" = @{
                "Primary" = "dall-e-3"
                "Alternative" = "dall-e-2"
                "Reasoning" = "dall-e-3 standard quality offers good balance"
            }
            "High" = @{
                "Primary" = "dall-e-3"
                "Alternative" = $null
                "Reasoning" = "dall-e-3 with HD quality for professional results"
            }
        }
        "TextToSpeech" = @{
            "Low" = @{
                "Primary" = "tts-1"
                "Alternative" = $null
                "Reasoning" = "tts-1 provides good quality at standard pricing"
            }
            "Medium" = @{
                "Primary" = "tts-1"
                "Alternative" = "tts-1-hd"
                "Reasoning" = "tts-1 sufficient for most use cases"
            }
            "High" = @{
                "Primary" = "tts-1-hd"
                "Alternative" = "tts-1"
                "Reasoning" = "tts-1-hd for professional audio quality"
            }
        }
        "SpeechToText" = @{
            "Low" = @{
                "Primary" = "whisper-1"
                "Alternative" = $null
                "Reasoning" = "whisper-1 is the only available option and reasonably priced"
            }
            "Medium" = @{
                "Primary" = "whisper-1"
                "Alternative" = $null
                "Reasoning" = "whisper-1 offers excellent quality and language support"
            }
            "High" = @{
                "Primary" = "whisper-1"
                "Alternative" = $null
                "Reasoning" = "whisper-1 provides state-of-the-art transcription quality"
            }
        }
        "Moderation" = @{
            "Low" = @{
                "Primary" = "text-moderation-latest"
                "Alternative" = "text-moderation-stable"
                "Reasoning" = "Both moderation models are free to use"
            }
            "Medium" = @{
                "Primary" = "text-moderation-latest"
                "Alternative" = "text-moderation-stable"
                "Reasoning" = "text-moderation-latest for most current safety detection"
            }
            "High" = @{
                "Primary" = "text-moderation-latest"
                "Alternative" = "text-moderation-stable"
                "Reasoning" = "text-moderation-latest provides most up-to-date protection"
            }
        }
    }
    
    $Rec = $Recommendations[$UseCase][$Budget]
    
    [PSCustomObject]@{
        UseCase = $UseCase
        Budget = $Budget
        Quality = $Quality
        Speed = $Speed
        PrimaryRecommendation = $Rec.Primary
        AlternativeRecommendation = $Rec.Alternative
        Reasoning = $Rec.Reasoning
        AdditionalNotes = switch ($UseCase) {
            "Chat" { "Consider system message optimization and token limits for cost control" }
            "Embedding" { "Batch multiple texts together to optimize API calls" }
            "ImageGeneration" { "Use standard quality unless professional output required" }
            "TextToSpeech" { "Test different voices to find best fit for your use case" }
            "SpeechToText" { "Supports 50+ languages with automatic language detection" }
            "Moderation" { "Always use latest version unless stability is critical" }
        }
        EstimatedSavings = if ($Budget -eq "Low") {
            switch ($UseCase) {
                "Chat" { "Up to 95% vs premium models" }
                "Embedding" { "Up to 85% vs large embedding model" }
                "ImageGeneration" { "Up to 50% vs DALL-E 3" }
                default { "Varies by usage" }
            }
        } else { "N/A" }
    }
}

function Compare-OpenAIModels {
    <#
    .SYNOPSIS
    Compares OpenAI models side by side for decision making
    .PARAMETER Models
    Array of model IDs to compare
    .PARAMETER Criteria
    Comparison criteria to focus on
    .EXAMPLE
    Compare-OpenAIModels -Models @("gpt-4o", "gpt-4o-mini") -Criteria @("Cost", "Quality", "Speed")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Models,
        
        [Parameter()]
        [ValidateSet("Cost", "Quality", "Speed", "Capabilities", "Limits")]
        [string[]]$Criteria = @("Cost", "Quality", "Speed")
    )
    
    $AllModels = Get-OpenAIModelDirectory -Format "Grid" -IncludePricing
    $SelectedModels = $AllModels | Where-Object { $_.ModelId -in $Models }
    
    if ($SelectedModels.Count -eq 0) {
        Write-Warning "No models found matching the specified IDs"
        return
    }
    
    Write-Host "`nModel Comparison:" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    foreach ($Model in $SelectedModels) {
        Write-Host "`n$($Model.Name) ($($Model.ModelId))" -ForegroundColor Yellow
        Write-Host "Category: $($Model.Category)" -ForegroundColor White
        
        if ("Quality" -in $Criteria) {
            Write-Host "Quality: $($Model.Quality)" -ForegroundColor Green
        }
        if ("Speed" -in $Criteria) {
            Write-Host "Speed: $($Model.Speed)" -ForegroundColor Green
        }
        if ("Cost" -in $Criteria -and $Model.InputCostPer1K) {
            Write-Host "Cost: Input `$($Model.InputCostPer1K)/1K, Output `$($Model.OutputCostPer1K)/1K" -ForegroundColor Green
        }
        if ("Capabilities" -in $Criteria) {
            Write-Host "Capabilities: $($Model.Capabilities)" -ForegroundColor Green
        }
        if ("Limits" -in $Criteria -and $Model.MaxTokens) {
            Write-Host "Max Tokens: $($Model.MaxTokens)" -ForegroundColor Green
        }
        
        Write-Host "Use Case: $($Model.UseCase)" -ForegroundColor Cyan
        if ($Model.Recommended) {
            Write-Host "⭐ Recommended" -ForegroundColor Yellow
        }
    }
    
    # Cost comparison table if cost is a criteria
    if ("Cost" -in $Criteria -and ($SelectedModels | Where-Object { $_.InputCostPer1K }).Count -gt 1) {
        Write-Host "`nCost Comparison (per 1K tokens):" -ForegroundColor Cyan
        $SelectedModels | Where-Object { $_.InputCostPer1K } | 
            Select-Object ModelId, @{N='Input';E={"$" + $_.InputCostPer1K}}, @{N='Output';E={"$" + $_.OutputCostPer1K}} |
            Format-Table -AutoSize
    }
}

#endregion