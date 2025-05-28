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
                    
                    $AllResults += [PSCustomObject]@{
                        # Input Information
                        Text = $CurrentBatch[$j]
                        TextLength = $CurrentBatch[$j].Length
                        Model = $Model
                        
                        # Moderation Results
                        Flagged = $Result.flagged
                        Categories = $Result.categories
                        CategoryScores = $Result.category_scores
                        
                        # Individual Category Results
                        Hate = $Result.categories.hate
                        HateScore = [math]::Round($Result.category_scores.hate, 4)
                        HateThreatening = $Result.categories."hate/threatening"
                        HateThreateningScore = [math]::Round($Result.category_scores."hate/threatening", 4)
                        Harassment = $Result.categories.harassment
                        HarassmentScore = [math]::Round($Result.category_scores.harassment, 4)
                        HarassmentThreatening = $Result.categories."harassment/threatening"
                        HarassmentThreateningScore = [math]::Round($Result.category_scores."harassment/threatening", 4)
                        SelfHarm = $Result.categories."self-harm"
                        SelfHarmScore = [math]::Round($Result.category_scores."self-harm", 4)
                        SelfHarmIntent = $Result.categories."self-harm/intent"
                        SelfHarmIntentScore = [math]::Round($Result.category_scores."self-harm/intent", 4)
                        SelfHarmInstructions = $Result.categories."self-harm/instructions"
                        SelfHarmInstructionsScore = [math]::Round($Result.category_scores."self-harm/instructions", 4)
                        Sexual = $Result.categories.sexual
                        SexualScore = [math]::Round($Result.category_scores.sexual, 4)
                        SexualMinors = $Result.categories."sexual/minors"
                        SexualMinorsScore = [math]::Round($Result.category_scores."sexual/minors", 4)
                        Violence = $Result.categories.violence
                        ViolenceScore = [math]::Round($Result.category_scores.violence, 4)
                        ViolenceGraphic = $Result.categories."violence/graphic"
                        ViolenceGraphicScore = [math]::Round($Result.category_scores."violence/graphic", 4)
                        
                        # Analysis
                        HighestRiskCategory = ($Result.category_scores.PSObject.Properties | Sort-Object Value -Descending | Select-Object -First 1).Name
                        HighestRiskScore = [math]::Round(($Result.category_scores.PSObject.Properties | Sort-Object Value -Descending | Select-Object -First 1).Value, 4)
                        TotalRiskScore = [math]::Round(($Result.category_scores.PSObject.Properties.Value | Measure-Object -Sum).Sum, 4)
                        FlaggedCategoriesCount = ($Result.categories.PSObject.Properties | Where-Object Value -eq $true).Count
                        FlaggedCategories = ($Result.categories.PSObject.Properties | Where-Object Value -eq $true | Select-Object -ExpandProperty Name) -join ", "
                        
                        # Processing Information
                        ProcessedAt = Get-Date
                        Success = $true
                        Error = $null
                        
                        # Batch Information
                        BatchIndex = [math]::Floor($i / $BatchSize)
                        ItemInBatch = $j
                        GlobalIndex = $ProcessedCount - 1
                        TotalItems = $TextBatch.Count
                        
                        # Pipeline Information
                        PipelineIndex = [Array]::IndexOf($TextBatch, $CurrentBatch[$j])
                        
                        # Compliance Helpers
                        IsCompliant = (-not $Result.flagged)
                        RequiresReview = ($Result.flagged -or ([math]::Round(($Result.category_scores.PSObject.Properties.Value | Measure-Object -Sum).Sum, 4) -gt 0.5))
                        SafetyLevel = if (-not $Result.flagged -and $TotalRiskScore -lt 0.1) { "Safe" } 
                                     elseif (-not $Result.flagged -and $TotalRiskScore -lt 0.5) { "Low Risk" }
                                     elseif (-not $Result.flagged) { "Medium Risk" }
                                     else { "High Risk" }
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
                        Model = $Model
                        
                        # Error Information
                        Flagged = $null
                        Success = $false
                        Error = $_.Exception.Message
                        ErrorType = $_.Exception.GetType().Name
                        
                        # Processing Information
                        ProcessedAt = Get-Date
                        
                        # Batch Information
                        BatchIndex = [math]::Floor($i / $BatchSize)
                        GlobalIndex = $ProcessedCount - 1
                        TotalItems = $TextBatch.Count
                        
                        # Pipeline Information
                        PipelineIndex = [Array]::IndexOf($TextBatch, $FailedText)
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
