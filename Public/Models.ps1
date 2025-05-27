#region Model Functions
function Get-OpenAIModels {
    <#
    .SYNOPSIS
    Lists available OpenAI models
    #>
    $Response = Invoke-OpenAIRequest -Endpoint "models" -Method "GET"
    return $Response.data | Sort-Object id
}

function Get-OpenAIModel {
    <#
    .SYNOPSIS
    Gets details about a specific model
    .PARAMETER ModelId
    ID of the model to retrieve
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModelId
    )
    
    return Invoke-OpenAIRequest -Endpoint "models/$ModelId" -Method "GET"
}

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
        }
        # Additional models would be included in the full implementation
    )
    
    # Filter by category if specified
    if ($Category -ne "All") {
        $ModelDatabase = $ModelDatabase | Where-Object { $_.Category -eq $Category }
    }
    
    # Filter deprecated models if not requested
    if (-not $IncludeDeprecated) {
        $ModelDatabase = $ModelDatabase | Where-Object { -not $_.Deprecated }
    }
    
    # Create output objects with formatting logic
    $Output = switch ($Format) {
        "Table" {
            $ModelDatabase | Format-Table -Property ModelId, Name, Category, Description, MaxTokens, InputCostPer1K, OutputCostPer1K, TrainingData, Capabilities, UseCase, Speed, Quality, Recommended, Deprecated, Notes -AutoSize
        }
        "List" {
            $ModelDatabase | Format-List -Property ModelId, Name, Category, Description, MaxTokens, InputCostPer1K, OutputCostPer1K, TrainingData, Capabilities, UseCase, Speed, Quality, Recommended, Deprecated, Notes
        }
        "Grid" {
            $ModelDatabase | Out-GridView -Title "OpenAI Model Directory"
            $null # Out-GridView doesn't return objects to pipeline
        }
    }
    
    return $Output
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
    
    # recommendation logic
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
        # Additional recommendations would be included
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
    
    # Create a comparison object for each selected model
    $ComparisonResults = @()
    foreach ($Model in $SelectedModels) {
        $ComparisonObject = [PSCustomObject]@{
            ModelId = $Model.ModelId
            Name = $Model.Name
            Category = $Model.Category
            Description = $Model.Description
            MaxTokens = $Model.MaxTokens
            InputCostPer1K = $Model.InputCostPer1K
            OutputCostPer1K = $Model.OutputCostPer1K
            TrainingData = $Model.TrainingData
            Capabilities = $Model.Capabilities -join ", "
            UseCase = $Model.UseCase
            Speed = $Model.Speed
            Quality = $Model.Quality
            Recommended = $Model.Recommended
            Deprecated = $Model.Deprecated
            Notes = $Model.Notes
        }
        
        # Add criteria-specific details
        foreach ($Criterion in $Criteria) {
            switch ($Criterion) {
                "Cost" {
                    $ComparisonObject | Add-Member -MemberType NoteProperty -Name "EstimatedMonthlyCost" -Value ([math]::Round(($Model.InputCostPer1K + $Model.OutputCostPer1K) * 1000 * 30, 2))
                }
                "Quality" {
                    $ComparisonObject | Add-Member -MemberType NoteProperty -Name "QualityRating" -Value (if ($Model.Quality -eq "Highest") { 5 } elseif ($Model.Quality -eq "High") { 4 } else { 3 })
                }
                "Speed" {
                    $ComparisonObject | Add-Member -MemberType NoteProperty -Name "SpeedRating" -Value (if ($Model.Speed -eq "Very Fast") { 5 } elseif ($Model.Speed -eq "Fast") { 4 } else { 3 })
                }
                "Capabilities" {
                    $ComparisonObject | Add-Member -MemberType NoteProperty -Name "CapabilitiesDetail" -Value ($Model.Capabilities -join ", ")
                }
                "Limits" {
                    $ComparisonObject | Add-Member -MemberType NoteProperty -Name "TokenLimit" -Value $Model.MaxTokens
                }
            }
        }
        
        $ComparisonResults += $ComparisonObject
    }
    
    # Format the output
    switch ($Format) {
        "Table" {
            $ComparisonResults | Format-Table -Property ModelId, Name, Category, Description, MaxTokens, InputCostPer1K, OutputCostPer1K, TrainingData, CapabilitiesDetail, UseCase, Speed, Quality, Recommended, Deprecated, Notes, EstimatedMonthlyCost, QualityRating, SpeedRating -AutoSize
        }
        "List" {
            $ComparisonResults | Format-List -Property ModelId, Name, Category, Description, MaxTokens, InputCostPer1K, OutputCostPer1K, TrainingData, CapabilitiesDetail, UseCase, Speed, Quality, Recommended, Deprecated, Notes, EstimatedMonthlyCost, QualityRating, SpeedRating
        }
        "Grid" {
            $ComparisonResults | Out-GridView -Title "OpenAI Model Comparison"
            $null # Out-GridView doesn't return objects to pipeline
        }
    }
    
    return $ComparisonResults
}
#endregion
