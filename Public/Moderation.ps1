#region Moderation Functions

function Test-OpenAIModeration {
    <#
    .SYNOPSIS
    Checks if text violates OpenAI's usage policies with comprehensive analysis
    .PARAMETER Text
    Text to moderate - supports pipeline input
    .PARAMETER Model
    Moderation model to use
    .EXAMPLE
    Test-OpenAIModeration -Text "This is a test message"
    .EXAMPLE
    "Text 1", "Text 2" | Test-OpenAIModeration
    .EXAMPLE
    Get-Content messages.txt | Test-OpenAIModeration | Where-Object Flagged -eq $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string[]]$Text,
        
        [Parameter()]
        [ValidateSet("text-moderation-latest", "text-moderation-stable")]
        [string]$Model = "text-moderation-latest"  # Always use latest for best detection
    )
    
    begin {
        $TextBatch = @()
    }
    
    process {
        $TextBatch += $Text
    }
    
    end {
        # Process in batches (API supports multiple inputs)
        $BatchSize = 100  # Conservative batch size
        $AllResults = @()
        $ProcessedCount = 0
        
        for ($i = 0; $i -lt $TextBatch.Count; $i += $BatchSize) {
            $CurrentBatch = $TextBatch[$i..([Math]::Min($i + $BatchSize - 1, $TextBatch.Count - 1))]
            
            $Body = @{
                model = $Model
                input = $CurrentBatch
            }
            
            try {
                $Response = Invoke-OpenAIRequest -Endpoint "moderations" -Body $Body
                
                # Return comprehensive structured output for each text
                for ($j = 0; $j -lt $Response.results.Count; $j++) {
                    $Result = $Response.results[$j]
                    $ProcessedCount++
                    
                    # Calculate risk scores and analysis
                    $CategoryScores = @{
                        Hate = $Result.category_scores.hate
                        HateThreatening = $Result.category_scores.'hate/threatening'
                        Harassment = $Result.category_scores.harassment
                        HarassmentThreatening = $Result.category_scores.'harassment/threatening'
                        SelfHarm = $Result.category_scores.'self-harm'
                        SelfHarmIntent = $Result.category_scores.'self-harm/intent'
                        SelfHarmInstructions = $Result.category_scores.'self-harm/instructions'
                        Sexual = $Result.category_scores.sexual
                        SexualMinors = $Result.category_scores.'sexual/minors'
                        Violence = $Result.category_scores.violence
                        ViolenceGraphic = $Result.category_scores.'violence/graphic'
                    }
                    
                    $Categories = @{
                        Hate = $Result.categories.hate
                        HateThreatening = $Result.categories.'hate/threatening'
                        Harassment = $Result.categories.harassment
                        HarassmentThreatening = $Result.categories.'harassment/threatening'
                        SelfHarm = $Result.categories.'self-harm'
                        SelfHarmIntent = $Result.categories.'self-harm/intent'
                        SelfHarmInstructions = $Result.categories.'self-harm/instructions'
                        Sexual = $Result.categories.sexual
                        SexualMinors = $Result.categories.'sexual/minors'
                        Violence = $Result.categories.violence
                        ViolenceGraphic = $Result.categories.'violence/graphic'
                    }
                    
                    # Calculate additional analytics
                    $MaxScore = ($CategoryScores.Values | Measure-Object -Maximum).Maximum
                    $AvgScore = ($CategoryScores.Values | Measure-Object -Average).Average
                    $FlaggedCategories = $Categories.GetEnumerator() | Where-Object { $_.Value -eq $true } | ForEach-Object { $_.Key }
                    $HighRiskCategories = $CategoryScores.GetEnumerator() | Where-Object { $_.Value -gt 0.5 } | ForEach-Object { $_.Key }
                    
                    $AllResults += [PSCustomObject]@{
                        # Input Information
                        Text = $CurrentBatch[$j]
                        TextLength = $CurrentBatch[$j].Length
                        TextWordCount = ($CurrentBatch[$j] -split '\s+').Count
                        
                        # Primary Moderation Results
                        Flagged = $Result.flagged
                        FlaggedCategories = $FlaggedCategories
                        FlaggedCategoryCount = $FlaggedCategories.Count
                        
                        # Detailed Category Analysis
                        Categories = [PSCustomObject]$Categories
                        CategoryScores = [PSCustomObject]$CategoryScores
                        
                        # Risk Analysis
                        MaxRiskScore = [math]::Round($MaxScore, 4)
                        AverageRiskScore = [math]::Round($AvgScore, 4)
                        HighRiskCategories = $HighRiskCategories
                        HighRiskCategoryCount = $HighRiskCategories.Count
                        
                        # Specific Risk Categories (for easy filtering)
                        HasHate = $Result.categories.hate
                        HasHarassment = $Result.categories.harassment
                        HasSelfHarm = ($Result.categories.'self-harm' -or $Result.categories.'self-harm/intent' -or $Result.categories.'self-harm/instructions')
                        HasSexual = ($Result.categories.sexual -or $Result.categories.'sexual/minors')
                        HasViolence = ($Result.categories.violence -or $Result.categories.'violence/graphic')
                        HasThreatening = ($Result.categories.'hate/threatening' -or $Result.categories.'harassment/threatening')
                        HasMinors = $Result.categories.'sexual/minors'
                        
                        # Risk Level Classification
                        RiskLevel = if ($Result.flagged) { 
                            if ($MaxScore -gt 0.9) { "Critical" }
                            elseif ($MaxScore -gt 0.7) { "High" }
                            elseif ($MaxScore -gt 0.5) { "Medium" }
                            else { "Low" }
                        } else { "Safe" }
                        
                        # Model & Processing Information
                        Model = $Model
                        ProcessedAt = Get-Date
                        Success = $true
                        Error = $null
                        
                        # Batch Information
                        BatchIndex = [math]::Floor($i / $BatchSize)
                        BatchSize = $CurrentBatch.Count
                        ItemInBatch = $j
                        GlobalIndex = $ProcessedCount - 1
                        TotalItems = $TextBatch.Count
                        
                        # Pipeline Information
                        PipelineIndex = [Array]::IndexOf($TextBatch, $CurrentBatch[$j])
                        
                        # Compliance & Action Recommendations
                        RequiresReview = ($Result.flagged -or $MaxScore -gt 0.3)
                        RequiresImmedateAction = ($Result.flagged -and $MaxScore -gt 0.8)
                        SuggestedAction = if ($Result.flagged) {
                            if ($MaxScore -gt 0.9) { "Block/Remove" }
                            elseif ($MaxScore -gt 0.7) { "Review/Warn" }
                            elseif ($MaxScore -gt 0.5) { "Monitor" }
                            else { "Flag for Review" }
                        } else { "Allow" }
                        
                        # Helper Properties for Filtering
                        IsClean = (-not $Result.flagged -and $MaxScore -lt 0.1)
                        IsProblematic = ($Result.flagged -or $MaxScore -gt 0.5)
                        IsBorderline = (-not $Result.flagged -and $MaxScore -gt 0.2 -and $MaxScore -lt 0.5)
                        IsLongText = ($CurrentBatch[$j].Length -gt 500)
                        IsShortText = ($CurrentBatch[$j].Length -lt 50)
                    }
                }
            }
            catch {
                # Create comprehensive error objects for each text in the failed batch
                foreach ($FailedText in $CurrentBatch) {
                    $ProcessedCount++
                    $AllResults += [PSCustomObject]@{
                        # Input Information
                        Text = $FailedText
                        TextLength = $FailedText.Length
                        TextWordCount = ($FailedText -split '\s+').Count
                        
                        # Error Information
                        Flagged = $null
                        Success = $false
                        Error = $_.Exception.Message
                        ErrorType = $_.Exception.GetType().Name
                        
                        # Configuration (for troubleshooting)
                        Model = $Model
                        
                        # Processing Information
                        ProcessedAt = Get-Date
                        
                        # Batch Information
                        BatchIndex = [math]::Floor($i / $BatchSize)
                        GlobalIndex = $ProcessedCount - 1
                        TotalItems = $TextBatch.Count
                        
                        # Pipeline Information
                        PipelineIndex = [Array]::IndexOf($TextBatch, $FailedText)
                        
                        # Safe defaults for error cases
                        RiskLevel = "Unknown"
                        RequiresReview = $true  # Err on the side of caution
                        SuggestedAction = "Manual Review Required"
                    }
                }
            }
            
            # Small delay between batches
            if ($i + $BatchSize -lt $TextBatch.Count) {
                Start-Sleep -Milliseconds 50
            }
        }
        
        return $AllResults
    }
}
#endregion
