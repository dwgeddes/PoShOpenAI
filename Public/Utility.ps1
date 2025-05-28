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
        $Models = Get-OpenAIModelList
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
    Saves OpenAI API responses to files with multiple format support
    .PARAMETER InputObject
    OpenAI response objects from pipeline
    .PARAMETER FilePath
    Output file path
    .PARAMETER Format
    Output format (json, csv, xml, txt)
    .PARAMETER IncludeMetadata
    Include processing metadata in output
    .PARAMETER Append
    Append to existing file instead of overwriting
    .EXAMPLE
    $results | Save-OpenAIResponse -FilePath "results.json" -Format json
    .EXAMPLE
    Get-Content "questions.txt" | Send-ChatMessage | Save-OpenAIResponse -FilePath "answers.csv" -Format csv
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$InputObject,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,
        
        [Parameter()]
        [ValidateSet("json", "csv", "xml", "txt")]
        [string]$Format = "json",
        
        [Parameter()]
        [switch]$IncludeMetadata,
        
        [Parameter()]
        [switch]$Append
    )
    
    begin {
        $AllObjects = @()
        $ProcessedCount = 0
    }
    
    process {
        $AllObjects += $InputObject
        $ProcessedCount += $InputObject.Count
    }
    
    end {
        try {
            # Ensure directory exists
            $Directory = Split-Path -Path $FilePath -Parent
            if ($Directory -and -not (Test-Path $Directory)) {
                New-Item -ItemType Directory -Path $Directory -Force | Out-Null
            }
            
            # Add metadata if requested
            if ($IncludeMetadata) {
                $MetadataObject = [PSCustomObject]@{
                    ExportedAt = Get-Date
                    TotalRecords = $AllObjects.Count
                    Format = $Format
                    ModuleVersion = if (Get-Module PSOpenAI) { (Get-Module PSOpenAI).Version } else { "Unknown" }
                    ExportedBy = $env:USERNAME
                    Summary = @{
                        SuccessfulRequests = ($AllObjects | Where-Object { $_.Success -eq $true }).Count
                        FailedRequests = ($AllObjects | Where-Object { $_.Success -eq $false }).Count
                        TotalCost = if ($AllObjects[0].EstimatedCost) {
                            ($AllObjects | Where-Object { $_.EstimatedCost } | Measure-Object EstimatedCost -Sum).Sum
                        } else { $null }
                        UniqueModels = ($AllObjects | Where-Object { $_.Model } | Select-Object -ExpandProperty Model -Unique) -join ", "
                    }
                }
                
                $ExportData = @{
                    Metadata = $MetadataObject
                    Data = $AllObjects
                }
            } else {
                $ExportData = $AllObjects
            }
            
            # Export based on format
            switch ($Format) {
                "json" {
                    $JsonOutput = $ExportData | ConvertTo-Json -Depth 20
                    if ($Append) {
                        Add-Content -Path $FilePath -Value $JsonOutput -Encoding UTF8
                    } else {
                        Set-Content -Path $FilePath -Value $JsonOutput -Encoding UTF8
                    }
                }
                "csv" {
                    if ($IncludeMetadata) {
                        Write-Warning "Metadata not supported in CSV format, exporting data only"
                        $ExportData = $AllObjects
                    }
                    if ($Append) {
                        $ExportData | Export-Csv -Path $FilePath -NoTypeInformation -Append -Encoding UTF8
                    } else {
                        $ExportData | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8
                    }
                }
                "xml" {
                    $XmlOutput = $ExportData | ConvertTo-Xml -Depth 20 -NoTypeInformation
                    if ($Append) {
                        Add-Content -Path $FilePath -Value $XmlOutput.OuterXml -Encoding UTF8
                    } else {
                        Set-Content -Path $FilePath -Value $XmlOutput.OuterXml -Encoding UTF8
                    }
                }
                "txt" {
                    $TextOutput = $AllObjects | ForEach-Object {
                        "=== $(if ($_.Type) { $_.Type } else { 'OpenAI' }) Response ===" 
                        "Input: $($_.Input)"
                        "Output: $($_.Output -or $_.Response)"
                        if ($_.Success -eq $false) { "Error: $($_.Error)" }
                        if ($_.EstimatedCost) { "Cost: `$$($_.EstimatedCost)" }
                        "Processed: $($_.ProcessedAt)"
                        ""
                    }
                    if ($Append) {
                        Add-Content -Path $FilePath -Value $TextOutput -Encoding UTF8
                    } else {
                        Set-Content -Path $FilePath -Value $TextOutput -Encoding UTF8
                    }
                }
            }
            
            [PSCustomObject]@{
                FilePath = $FilePath
                Format = $Format
                RecordsExported = $AllObjects.Count
                FileSize = (Get-Item $FilePath).Length
                Success = $true
                ExportedAt = Get-Date
            }
        }
        catch {
            Write-OpenAIError -Message "Failed to save responses to file: $($_.Exception.Message)" -Exception $_.Exception -Category WriteError -ErrorId "SaveResponseError" -TargetObject $FilePath
            
            [PSCustomObject]@{
                FilePath = $FilePath
                Format = $Format
                RecordsExported = 0
                Success = $false
                Error = $_.Exception.Message
                ExportedAt = Get-Date
            }
        }
    }
}

function Compare-OpenAIResponse {
    <#
    .SYNOPSIS
    Compares multiple OpenAI responses for analysis and A/B testing
    .PARAMETER Responses
    Array of OpenAI response objects to compare
    .PARAMETER CompareBy
    What to compare (Cost, Quality, Speed, Tokens)
    .PARAMETER OutputFormat
    Format for comparison output
    .EXAMPLE
    $responses | Compare-OpenAIResponse -CompareBy @("Cost", "Speed")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$Responses,
        
        [Parameter()]
        [ValidateSet("Cost", "Quality", "Speed", "Tokens", "Success")]
        [string[]]$CompareBy = @("Cost", "Tokens", "Success"),
        
        [Parameter()]
        [ValidateSet("Table", "Grid", "Summary")]
        [string]$OutputFormat = "Table"
    )
    
    begin {
        $AllResponses = @()
    }
    
    process {
        $AllResponses += $Responses
    }
    
    end {
        try {
            if ($AllResponses.Count -lt 2) {
                Write-Warning "Need at least 2 responses to compare"
                return
            }
            
            $ComparisonResults = foreach ($Response in $AllResponses) {
                [PSCustomObject]@{
                    Input = $Response.Input
                    Model = $Response.Model
                    Success = $Response.Success
                    Cost = $Response.EstimatedCost
                    Tokens = $Response.TotalTokens -or $Response.TokensUsed
                    ProcessingTime = if ($Response.ProcessedAt -and $Response.CreatedAt) {
                        ($Response.ProcessedAt - $Response.CreatedAt).TotalSeconds
                    } else { $null }
                    OutputLength = if ($Response.Output -or $Response.Response) {
                        ($Response.Output -or $Response.Response).Length
                    } else { 0 }
                    Type = $Response.Type
                }
            }
            
            switch ($OutputFormat) {
                "Table" {
                    $ComparisonResults | Format-Table -AutoSize
                }
                "Grid" {
                    $ComparisonResults
                }
                "Summary" {
                    [PSCustomObject]@{
                        TotalResponses = $AllResponses.Count
                        SuccessRate = [math]::Round((($AllResponses | Where-Object Success).Count / $AllResponses.Count) * 100, 2)
                        AverageCost = if ($AllResponses[0].EstimatedCost) {
                            [math]::Round(($AllResponses | Where-Object EstimatedCost | Measure-Object EstimatedCost -Average).Average, 6)
                        } else { $null }
                        TotalCost = if ($AllResponses[0].EstimatedCost) {
                            [math]::Round(($AllResponses | Where-Object EstimatedCost | Measure-Object EstimatedCost -Sum).Sum, 6)
                        } else { $null }
                        AverageTokens = if ($AllResponses[0].TotalTokens -or $AllResponses[0].TokensUsed) {
                            [math]::Round(($AllResponses | Where-Object { $_.TotalTokens -or $_.TokensUsed } | 
                                ForEach-Object { $_.TotalTokens -or $_.TokensUsed } | Measure-Object -Average).Average, 0)
                        } else { $null }
                        Models = ($AllResponses | Where-Object Model | Select-Object -ExpandProperty Model -Unique) -join ", "
                        Types = ($AllResponses | Where-Object Type | Select-Object -ExpandProperty Type -Unique) -join ", "
                    }
                }
            }
        }
        catch {
            Write-OpenAIError -Message "Failed to compare responses: $($_.Exception.Message)" -Exception $_.Exception -Category InvalidOperation -ErrorId "CompareResponseError"
            return $null
        }
    }
}

function Test-OpenAIQuota {
    <#
    .SYNOPSIS
    Tests current API quota and rate limits by making small test requests
    .PARAMETER Detailed
    Return detailed quota information
    .EXAMPLE
    Test-OpenAIQuota
    .EXAMPLE
    Test-OpenAIQuota -Detailed
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Detailed
    )
    
    $TestResults = @{}
    
    try {
        # Test basic connectivity
        $Models = Get-OpenAIModelList
        $TestResults.BasicConnectivity = @{
            Success = $true
            ModelsAvailable = $Models.Count
            Error = $null
        }
        
        # Test chat endpoint with minimal request
        try {
            $ChatTest = Send-ChatMessage -Message "Test" -Model "gpt-4o-mini" -MaxTokens 1
            $TestResults.ChatEndpoint = @{
                Success = $ChatTest.Success
                ResponseTime = if ($ChatTest.ProcessedAt) { $ChatTest.ProcessedAt } else { $null }
                Cost = $ChatTest.EstimatedCost
                Error = $ChatTest.Error
            }
        } catch {
            $TestResults.ChatEndpoint = @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
        
        # Test embeddings endpoint
        try {
            $EmbeddingTest = New-OpenAIEmbedding -Text "test" -Model "text-embedding-3-small"
            $TestResults.EmbeddingEndpoint = @{
                Success = $EmbeddingTest.Success
                ResponseTime = if ($EmbeddingTest.ProcessedAt) { $EmbeddingTest.ProcessedAt } else { $null }
                Cost = $EmbeddingTest.EstimatedCost
                Error = $EmbeddingTest.Error
            }
        } catch {
            $TestResults.EmbeddingEndpoint = @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
        
        # Test moderation endpoint (free)
        try {
            $ModerationTest = Test-OpenAIModeration -Text "test"
            $TestResults.ModerationEndpoint = @{
                Success = $ModerationTest.Success
                ResponseTime = if ($ModerationTest.ProcessedAt) { $ModerationTest.ProcessedAt } else { $null }
                Error = $ModerationTest.Error
            }
        } catch {
            $TestResults.ModerationEndpoint = @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
        
        # Summary
        $WorkingEndpoints = ($TestResults.Values | Where-Object { $_.Success }).Count
        $TotalEndpoints = $TestResults.Count
        
        if ($Detailed) {
            [PSCustomObject]@{
                OverallStatus = if ($WorkingEndpoints -eq $TotalEndpoints) { "All Systems Operational" } 
                               elseif ($WorkingEndpoints -gt 0) { "Partial Service Available" }
                               else { "Service Unavailable" }
                WorkingEndpoints = "$WorkingEndpoints/$TotalEndpoints"
                TestedAt = Get-Date
                Details = $TestResults
                EstimatedTestCost = ($TestResults.Values | Where-Object { $_.Cost } | ForEach-Object { $_.Cost } | Measure-Object -Sum).Sum
            }
        } else {
            [PSCustomObject]@{
                Status = if ($WorkingEndpoints -eq $TotalEndpoints) { "✅ All Systems Operational" } 
                        elseif ($WorkingEndpoints -gt 0) { "⚠️ Partial Service Available" }
                        else { "❌ Service Unavailable" }
                WorkingEndpoints = "$WorkingEndpoints/$TotalEndpoints"
                BasicConnectivity = if ($TestResults.BasicConnectivity.Success) { "✅" } else { "❌" }
                ChatAPI = if ($TestResults.ChatEndpoint.Success) { "✅" } else { "❌" }
                EmbeddingAPI = if ($TestResults.EmbeddingEndpoint.Success) { "✅" } else { "❌" }
                ModerationAPI = if ($TestResults.ModerationEndpoint.Success) { "✅" } else { "❌" }
                TestedAt = Get-Date
            }
        }
    }
    catch {
        Write-OpenAIError -Message "Failed to test quota: $($_.Exception.Message)" -Exception $_.Exception -Category ResourceUnavailable -ErrorId "QuotaTestError"
        
        [PSCustomObject]@{
            Status = "❌ Test Failed"
            Error = $_.Exception.Message
            TestedAt = Get-Date
        }
    }
}

function Show-OpenAIExample {
    <#
    .SYNOPSIS
    Displays comprehensive usage examples for the PSOpenAI module
    .EXAMPLE
    Show-OpenAIExample
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
