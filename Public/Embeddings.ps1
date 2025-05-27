#region Embeddings Functions

function New-OpenAIEmbedding {
    <#
    .SYNOPSIS
    Creates embeddings for text using OpenAI's embedding models with full pipeline support
    .PARAMETER Text
    Text or array of texts to embed - supports pipeline input
    .PARAMETER Model
    Embedding model to use
    .PARAMETER EncodingFormat
    Format for the embeddings (float or base64)
    .PARAMETER Dimensions
    Number of dimensions for the embedding (only for text-embedding-3 models)
    .PARAMETER User
    Unique user identifier
    .EXAMPLE
    New-OpenAIEmbedding -Text "Hello world"
    .EXAMPLE
    "Text 1", "Text 2" | New-OpenAIEmbedding -Model "text-embedding-3-large"
    .EXAMPLE
    Get-Content documents.txt | New-OpenAIEmbedding -Dimensions 512
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string[]]$Text,
        
        [Parameter()]
        [ValidateSet("text-embedding-3-small", "text-embedding-3-large", "text-embedding-ada-002")]
        [string]$Model = "text-embedding-3-small",  # Best balance of quality and cost
        
        [Parameter()]
        [ValidateSet("float", "base64")]
        [string]$EncodingFormat = "float",
        
        [Parameter()]
        [ValidateRange(1, 3072)]
        [int]$Dimensions = $null,  # Only valid for text-embedding-3 models
        
        [Parameter()]
        [string]$User = $null
    )
    
    begin {
        $TextBatch = @()
    }
    
    process {
        $TextBatch += $Text
    }
    
    end {
        # Process in batches to optimize API calls (max 2048 inputs per request)
        $BatchSize = 100  # Conservative batch size for reliability
        $AllResults = @()
        $ProcessedCount = 0
        
        for ($i = 0; $i -lt $TextBatch.Count; $i += $BatchSize) {
            $CurrentBatch = $TextBatch[$i..([Math]::Min($i + $BatchSize - 1, $TextBatch.Count - 1))]
            
            $Body = @{
                model = $Model
                input = $CurrentBatch
                encoding_format = $EncodingFormat
            }
            
            # Track original parameters
            $OriginalDimensions = $Dimensions
            $Warnings = @()
            
            # Only add dimensions for text-embedding-3 models
            if ($Dimensions -and $Model -like "text-embedding-3-*") {
                $Body.dimensions = $Dimensions
            } elseif ($Dimensions -and $Model -eq "text-embedding-ada-002") {
                $Warnings += "Dimensions parameter is not supported for text-embedding-ada-002 model. Using default dimensions."
            }
            
            if ($User) { $Body.user = $User }
            
            try {
                $Response = Invoke-OpenAIRequest -Endpoint "embeddings" -Body $Body
                
                # Return comprehensive structured output for each text
                for ($j = 0; $j -lt $Response.data.Count; $j++) {
                    $EmbeddingData = $Response.data[$j]
                    $ProcessedCount++
                    
                    $AllResults += [PSCustomObject]@{
                        # Input Information
                        Text = $CurrentBatch[$j]
                        TextLength = $CurrentBatch[$j].Length
                        TextWordCount = ($CurrentBatch[$j] -split '\s+').Count
                        
                        # Embedding Data
                        Embedding = $EmbeddingData.embedding
                        EmbeddingLength = $EmbeddingData.embedding.Count
                        EncodingFormat = $EncodingFormat
                        
                        # Model & Configuration
                        Model = $Model
                        RequestedDimensions = $OriginalDimensions
                        ActualDimensions = $EmbeddingData.embedding.Count
                        DimensionsSupported = ($Model -like "text-embedding-3-*")
                        DimensionsReduced = ($OriginalDimensions -and $OriginalDimensions -lt $EmbeddingData.embedding.Count)
                        
                        # API Response Details
                        ApiIndex = $EmbeddingData.index
                        ObjectType = $EmbeddingData.object
                        
                        # Cost Estimation (approximate USD)
                        EstimatedCost = switch ($Model) {
                            "text-embedding-3-small" { [math]::Round(($Response.usage.total_tokens * 0.00000002), 8) }
                            "text-embedding-3-large" { [math]::Round(($Response.usage.total_tokens * 0.00000013), 8) }
                            "text-embedding-ada-002" { [math]::Round(($Response.usage.total_tokens * 0.0000001), 8) }
                            default { $null }
                        }
                        
                        # Token Usage (shared across batch, calculated per item)
                        PromptTokens = if ($Response.usage) { [math]::Round($Response.usage.prompt_tokens / $Response.data.Count) } else { $null }
                        TotalTokens = if ($Response.usage) { [math]::Round($Response.usage.total_tokens / $Response.data.Count) } else { $null }
                        TokensPerCharacter = if ($Response.usage -and $CurrentBatch[$j].Length -gt 0) { 
                            [math]::Round(($Response.usage.total_tokens / $Response.data.Count) / $CurrentBatch[$j].Length, 4) 
                        } else { $null }
                        
                        # Embedding Analysis
                        EmbeddingMagnitude = if ($EmbeddingData.embedding) { 
                            [math]::Round([math]::Sqrt(($EmbeddingData.embedding | ForEach-Object { $_ * $_ } | Measure-Object -Sum).Sum), 4)
                        } else { $null }
                        EmbeddingMean = if ($EmbeddingData.embedding) { 
                            [math]::Round(($EmbeddingData.embedding | Measure-Object -Average).Average, 4) 
                        } else { $null }
                        EmbeddingStdDev = if ($EmbeddingData.embedding -and $EmbeddingData.embedding.Count -gt 1) {
                            $mean = ($EmbeddingData.embedding | Measure-Object -Average).Average
                            $variance = ($EmbeddingData.embedding | ForEach-Object { ($_ - $mean) * ($_ - $mean) } | Measure-Object -Average).Average
                            [math]::Round([math]::Sqrt($variance), 4)
                        } else { $null }
                        
                        # Processing Information
                        ProcessedAt = Get-Date
                        Success = $true
                        Error = $null
                        Warnings = $Warnings
                        HasWarnings = ($Warnings.Count -gt 0)
                        
                        # Batch Information
                        BatchIndex = [math]::Floor($i / $BatchSize)
                        BatchSize = $CurrentBatch.Count
                        ItemInBatch = $j
                        GlobalIndex = $ProcessedCount - 1
                        TotalItems = $TextBatch.Count
                        
                        # Pipeline Information
                        PipelineIndex = if ($Text.Count -gt 1) { [Array]::IndexOf($TextBatch, $CurrentBatch[$j]) } else { 0 }
                        
                        # Model Capabilities
                        MaxDimensions = switch ($Model) {
                            "text-embedding-3-small" { 1536 }
                            "text-embedding-3-large" { 3072 }
                            "text-embedding-ada-002" { 1536 }
                            default { $null }
                        }
                        ModelGeneration = if ($Model -like "text-embedding-3-*") { 3 } elseif ($Model -like "*ada-002") { 2 } else { $null }
                        
                        # User Information
                        User = $User
                        
                        # Helper Properties for Analysis
                        IsLongText = ($CurrentBatch[$j].Length -gt 1000)
                        IsShortText = ($CurrentBatch[$j].Length -lt 100)
                        HasSpecialChars = ($CurrentBatch[$j] -match '[^\w\s]')
                        LanguageDetected = $null  # Could be enhanced with language detection
                        
                        # Similarity Helpers (for future use)
                        EmbeddingHash = if ($EmbeddingData.embedding) {
                            # Simple hash for duplicate detection
                            $hashInput = ($EmbeddingData.embedding[0..9] | ForEach-Object { [math]::Round($_, 3) }) -join ','
                            [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($hashInput)) | 
                                ForEach-Object { $_.ToString("x2") } | Select-Object -First 8 | Join-String
                        } else { $null }
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
                        Embedding = $null
                        Success = $false
                        Error = $_.Exception.Message
                        ErrorType = $_.Exception.GetType().Name
                        
                        # Configuration (for troubleshooting)
                        Model = $Model
                        RequestedDimensions = $OriginalDimensions
                        EncodingFormat = $EncodingFormat
                        
                        # Processing Information
                        ProcessedAt = Get-Date
                        Warnings = $Warnings
                        
                        # Batch Information
                        BatchIndex = [math]::Floor($i / $BatchSize)
                        GlobalIndex = $ProcessedCount - 1
                        TotalItems = $TextBatch.Count
                        
                        # Pipeline Information
                        PipelineIndex = [Array]::IndexOf($TextBatch, $FailedText)
                    }
                }
            }
            
            # Small delay between batches to avoid rate limits
            if ($i + $BatchSize -lt $TextBatch.Count) {
                Start-Sleep -Milliseconds 100
            }
        }
        
        return $AllResults
    }
}

#endregion