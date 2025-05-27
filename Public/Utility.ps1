#region Utility Functions

function Test-OpenAIConnection {
    <#
    .SYNOPSIS
    Tests the connection to OpenAI API with comprehensive diagnostics
    .EXAMPLE
    Test-OpenAIConnection
    #>
    try {
        if (-not $Global:OpenAIConfig.ApiKey) {
            Write-Host "✗ OpenAI API key not configured. Use Set-OpenAIKey first." -ForegroundColor Red
            return $false
        }
        
        Write-Host "Testing OpenAI API connection..." -ForegroundColor Cyan
        $Models = Get-OpenAIModels
        Write-Host "✓ Successfully connected to OpenAI API" -ForegroundColor Green
        Write-Host "Available models: $($Models.Count)" -ForegroundColor Cyan
        
        # Show key configuration details
        Write-Host "`nConfiguration:" -ForegroundColor Yellow
        Write-Host "  Base URL: $($Global:OpenAIConfig.BaseUrl)" -ForegroundColor Gray
        Write-Host "  Default Model: $($Global:OpenAIConfig.DefaultModel)" -ForegroundColor Gray
        Write-Host "  Timeout: $($Global:OpenAIConfig.TimeoutSec)s" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Host "✗ Failed to connect to OpenAI API: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Format-OpenAIResponse {
    <#
    .SYNOPSIS
    Formats OpenAI API responses for better readability with enhanced analytics
    .PARAMETER Response
    The response object from OpenAI
    .PARAMETER ShowMetadata
    Whether to show detailed metadata
    .EXAMPLE
    $result | Format-OpenAIResponse -ShowMetadata
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $Response,
        
        [Parameter()]
        [switch]$ShowMetadata
    )
    
    process {
        if ($Response.choices) {
            # Chat completion response
            foreach ($Choice in $Response.choices) {
                Write-Host "Response $($Choice.index + 1):" -ForegroundColor Cyan
                Write-Host $Choice.message.content -ForegroundColor White
                Write-Host "Finish Reason: $($Choice.finish_reason)" -ForegroundColor Yellow
            }
            
            if ($Response.usage) {
                Write-Host "`nToken Usage:" -ForegroundColor Magenta
                Write-Host "  Prompt: $($Response.usage.prompt_tokens)" -ForegroundColor Gray
                Write-Host "  Completion: $($Response.usage.completion_tokens)" -ForegroundColor Gray
                Write-Host "  Total: $($Response.usage.total_tokens)" -ForegroundColor Gray
            }
            
            if ($ShowMetadata) {
                Write-Host "`nMetadata:" -ForegroundColor Blue
                Write-Host "  Model: $($Response.model)" -ForegroundColor Gray
                Write-Host "  ID: $($Response.id)" -ForegroundColor Gray
                if ($Response.created) {
                    $CreatedDate = [DateTimeOffset]::FromUnixTimeSeconds($Response.created).DateTime
                    Write-Host "  Created: $CreatedDate" -ForegroundColor Gray
                }
                if ($Response.system_fingerprint) {
                    Write-Host "  System Fingerprint: $($Response.system_fingerprint)" -ForegroundColor Gray
                }
            }
        }
        elseif ($Response.data -and $Response.data[0].embedding) {
            # Embedding response
            Write-Host "Embedding Response:" -ForegroundColor Cyan
            Write-Host "  Count: $($Response.data.Count)" -ForegroundColor Gray
            Write-Host "  Dimensions: $($Response.data[0].embedding.Count)" -ForegroundColor Gray
            Write-Host "  Model: $($Response.model)" -ForegroundColor Gray
            
            if ($Response.usage) {
                Write-Host "  Total Tokens: $($Response.usage.total_tokens)" -ForegroundColor Gray
            }
        }
        elseif ($Response.data -and $Response.data[0].url) {
            # Image response
            Write-Host "Image Response:" -ForegroundColor Cyan
            Write-Host "  Count: $($Response.data.Count)" -ForegroundColor Gray
            foreach ($i in 0..($Response.data.Count - 1)) {
                Write-Host "  Image $($i + 1): $($Response.data[$i].url)" -ForegroundColor Gray
            }
        }
        else {
            # Generic response
            Write-Host "Response:" -ForegroundColor Cyan
            $Response | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Gray
        }
    }
}

function Save-OpenAIResponse {
    <#
    .SYNOPSIS
    Saves OpenAI response to a file with flexible formatting options
    .PARAMETER Response
    The response to save
    .PARAMETER FilePath
    Path to save the file
    .PARAMETER Format
    Format to save (json, text, csv)
    .PARAMETER IncludeMetadata
    Whether to include metadata in the saved file
    .EXAMPLE
    $result | Save-OpenAIResponse -FilePath "response.json" -IncludeMetadata
    .EXAMPLE
    $results | Save-OpenAIResponse -FilePath "chat_results.csv" -Format csv
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $Response,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [ValidateSet("json", "text", "csv")]
        [string]$Format = "json",
        
        [Parameter()]
        [switch]$IncludeMetadata
    )
    
    begin {
        $AllResponses = @()
    }
    
    process {
        $AllResponses += $Response
    }
    
    end {
        $Directory = Split-Path $FilePath -Parent
        if ($Directory -and -not (Test-Path $Directory)) {
            New-Item -ItemType Directory -Path $Directory -Force | Out-Null
        }
        
        switch ($Format.ToLower()) {
            "json" {
                $AllResponses | ConvertTo-Json -Depth 10 | Out-File -FilePath $FilePath -Encoding UTF8
            }
            "text" {
                $TextContent = foreach ($Resp in $AllResponses) {
                    if ($Resp.choices) {
                        $Resp.choices[0].message.content
                    }
                    elseif ($Resp.Response) {
                        $Resp.Response
                    }
                    else {
                        $Resp | Out-String
                    }
                    ""  # Add blank line between responses
                }
                $TextContent | Out-File -FilePath $FilePath -Encoding UTF8
            }
            "csv" {
                $CsvData = foreach ($Resp in $AllResponses) {
                    if ($Resp.Input -and $Resp.Response) {
                        # Chat message format
                        [PSCustomObject]@{
                            Input = $Resp.Input
                            Response = $Resp.Response
                            Model = $Resp.Model
                            TotalTokens = $Resp.TotalTokens
                            EstimatedCost = $Resp.EstimatedCost
                            ProcessedAt = $Resp.ProcessedAt
                        }
                    }
                    else {
                        # Generic format
                        $Resp
                    }
                }
                $CsvData | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8
            }
        }
        
        Write-Host "Response(s) saved to: $FilePath" -ForegroundColor Green
        Write-Host "  Count: $($AllResponses.Count)" -ForegroundColor Gray
        Write-Host "  Format: $Format" -ForegroundColor Gray
        
        $FileInfo = Get-Item $FilePath
        Write-Host "  Size: $([math]::Round($FileInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
    }
}

function Show-OpenAIExamples {
    <#
    .SYNOPSIS
    Displays comprehensive usage examples for the PSOpenAI module
    .EXAMPLE
    Show-OpenAIExamples
    #>
    
    Write-Host @"

PSOpenAI Module - Usage Examples
================================

🔧 BASIC SETUP:
1. Set your API key:
   Set-OpenAIKey -ApiKey (Read-Host -AsSecureString -Prompt "API Key")

2. Test connection:
   Test-OpenAIConnection

3. Configure defaults:
   Set-OpenAIDefaults -Model "gpt-4o-mini" -MaxTokens 500

💬 CHAT EXAMPLES:
4. Simple chat:
   Send-ChatMessage -Message "What is PowerShell?"

5. Pipeline processing:
   "Question 1", "Question 2" | Send-ChatMessage -SystemMessage "Be concise"

6. Batch processing from file:
   Get-Content "questions.txt" | Send-ChatMessage -Model "gpt-4o" | Export-Csv "results.csv"

🖼️ IMAGE EXAMPLES:
7. Generate image:
   New-OpenAIImage -Prompt "A sunset over mountains" -Quality "hd"

8. Multiple images:
   New-OpenAIImage -Prompt "Abstract art" -Count 2 -Size "1024x1024"

🔊 AUDIO EXAMPLES:
9. Text to speech:
   ConvertTo-OpenAISpeech -Text "Hello world" -Voice "alloy" -OutputPath "hello.mp3"

10. Speech to text:
    ConvertFrom-OpenAISpeech -AudioPath "recording.mp3" -Model "whisper-1"

📊 EMBEDDINGS:
11. Create embeddings:
    New-OpenAIEmbedding -Input "Sample text for embedding"

12. Batch embeddings:
    Get-Content "documents.txt" | New-OpenAIEmbedding -Model "text-embedding-3-small"

🛡️ MODERATION:
13. Content moderation:
    Test-OpenAIModeration -Input "Text to check for policy violations"

⚡ PARALLEL PROCESSING:
14. Parallel chat:
    Get-Content "questions.txt" | Invoke-OpenAIParallelChat -ThrottleLimit 3

15. Parallel embeddings:
    Get-Content "texts.txt" | Invoke-OpenAIParallelEmbedding -BatchSize 100

💰 COST TRACKING:
16. Analyze costs:
    `$results = "Question 1", "Question 2" | Send-ChatMessage
    (`$results | Measure-Object EstimatedCost -Sum).Sum

📁 UTILITY FUNCTIONS:
17. Format responses:
    `$result | Format-OpenAIResponse -ShowMetadata

18. Save responses:
    `$results | Save-OpenAIResponse -FilePath "output.json" -IncludeMetadata

For more information, visit: https://github.com/your-repo/PSOpenAI

"@ -ForegroundColor Cyan
}

#endregion
