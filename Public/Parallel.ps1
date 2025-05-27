#region PowerShell 7 Parallel Processing Functions

function Invoke-OpenAIParallelChat {
    <#
    .SYNOPSIS
    Processes multiple chat messages in parallel using PowerShell 7's ForEach-Object -Parallel
    .PARAMETER Messages  
    Array of messages to process - supports pipeline input
    .PARAMETER Model
    Model to use for all messages (cost-effective default)
    .PARAMETER ThrottleLimit
    Maximum number of parallel operations (be mindful of rate limits)
    .PARAMETER SystemMessage
    Optional system message for context
    .PARAMETER MaxTokens
    Maximum tokens per response
    .PARAMETER Temperature
    Temperature for randomness
    .EXAMPLE
    $questions | Invoke-OpenAIParallelChat -ThrottleLimit 3
    .EXAMPLE
    Get-Content "questions.txt" | Invoke-OpenAIParallelChat -Model "gpt-4o-mini" -SystemMessage "Be concise"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string[]]$Messages,
        
        [Parameter()]
        [ValidateSet("gpt-4o", "gpt-4o-mini", "gpt-4", "gpt-4-turbo", "gpt-3.5-turbo")]
        [string]$Model = "gpt-4o-mini",  # Cost-effective default for parallel processing
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$ThrottleLimit = 5,  # Conservative default to avoid rate limits
        
        [Parameter()]
        [string]$SystemMessage = $null,
        
        [Parameter()]
        [ValidateRange(1, 4096)]
        [int]$MaxTokens = 500,  # Smaller default for parallel processing cost control
        
        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature = 0.7
    )
    
    begin {
        $MessageBatch = @()
        
        # Get the plain text API key from SecureString for parallel runspaces
        $PlainApiKey = $null
        try {
            if ($Global:OpenAIConfig -and $Global:OpenAIConfig.ApiKey) {
                $PlainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Global:OpenAIConfig.ApiKey))
            } else {
                throw "OpenAI API key not configured. Please run Set-OpenAIKey first."
            }
        } catch {
            Write-Error "Failed to retrieve API key: $($_.Exception.Message)"
            return
        }
    }
    
    process {
        $MessageBatch += $Messages
    }
    
    end {
        try {
            Write-Host "Processing $($MessageBatch.Count) messages in parallel with throttle limit $ThrottleLimit" -ForegroundColor Cyan
            
            # PowerShell 7 parallel processing
            $Results = $MessageBatch | ForEach-Object -Parallel {
                # Import variables into parallel runspace
                $Config = $using:Global:OpenAIConfig
                $PlainApiKey = $using:PlainApiKey
                $Model = $using:Model
                $SystemMessage = $using:SystemMessage
                $MaxTokens = $using:MaxTokens
                $Temperature = $using:Temperature
                
                # Build message array
                $ChatMessages = @()
                if ($SystemMessage) {
                    $ChatMessages += @{ role = "system"; content = $SystemMessage }
                }
                $ChatMessages += @{ role = "user"; content = $_ }
                
                $Body = @{
                    model = $Model
                    messages = $ChatMessages
                    max_tokens = $MaxTokens
                    temperature = $Temperature
                }
                
                try {
                    $Uri = "$($Config.BaseUrl)/chat/completions"
                    $Headers = @{
                        "Authorization" = "Bearer $PlainApiKey"
                        "Content-Type" = "application/json"
                    }
                    
                    if ($Config.Organization) {
                        $Headers["OpenAI-Organization"] = $Config.Organization
                    }
                    
                    $RequestBody = ($Body | ConvertTo-Json -Depth 20 -Compress)
                    $Response = Invoke-RestMethod -Uri $Uri -Method POST -Headers $Headers -Body $RequestBody -TimeoutSec $Config.TimeoutSec
                    
                    [PSCustomObject]@{
                        Input = $_
                        Response = $Response.choices[0].message.content
                        Model = $Model
                        FinishReason = $Response.choices[0].finish_reason
                        PromptTokens = $Response.usage.prompt_tokens
                        CompletionTokens = $Response.usage.completion_tokens
                        TotalTokens = $Response.usage.total_tokens
                        ProcessedAt = Get-Date
                        ThreadId = [Threading.Thread]::CurrentThread.ManagedThreadId
                        Success = $true
                        Error = $null
                    }
                }
                catch {
                    [PSCustomObject]@{
                        Input = $_
                        Response = $null
                        Error = $_.Exception.Message
                        Model = $Model
                        ProcessedAt = Get-Date
                        ThreadId = [Threading.Thread]::CurrentThread.ManagedThreadId
                        Success = $false
                        PromptTokens = 0
                        CompletionTokens = 0
                        TotalTokens = 0
                    }
                }
            } -ThrottleLimit $ThrottleLimit
            
            # Calculate summary statistics
            $SuccessfulResults = $Results | Where-Object { $_.Success }
            $FailedResults = $Results | Where-Object { -not $_.Success }
            $TotalTokens = ($SuccessfulResults | Measure-Object -Property TotalTokens -Sum).Sum
            
            Write-Host "Parallel processing completed: $($SuccessfulResults.Count) successful, $($FailedResults.Count) failed" -ForegroundColor Green
            
            # Return comprehensive results
            [PSCustomObject]@{
                Results = $Results
                Summary = [PSCustomObject]@{
                    TotalProcessed = $Results.Count
                    Successful = $SuccessfulResults.Count
                    Failed = $FailedResults.Count
                    TotalTokens = $TotalTokens
                    Model = $Model
                    ThrottleLimit = $ThrottleLimit
                    ProcessedAt = Get-Date
                }
            }
        }
        finally {
            # Clear plain text API key from memory
            if ($PlainApiKey) {
                $PlainApiKey = $null
                [System.GC]::Collect()
            }
        }
    }
}

function Invoke-OpenAIParallelEmbedding {
    <#
    .SYNOPSIS
    Creates embeddings for multiple texts in parallel using PowerShell 7
    .PARAMETER Texts
    Array of texts to embed
    .PARAMETER Model
    Embedding model to use
    .PARAMETER ThrottleLimit
    Maximum number of parallel operations
    .PARAMETER BatchSize
    Number of texts to process in each API call
    .EXAMPLE
    $texts | Invoke-OpenAIParallelEmbedding -ThrottleLimit 3
    .EXAMPLE
    Get-Content "documents.txt" | Invoke-OpenAIParallelEmbedding -Model "text-embedding-3-large"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Texts,
        
        [Parameter()]
        [ValidateSet("text-embedding-3-small", "text-embedding-3-large", "text-embedding-ada-002")]
        [string]$Model = "text-embedding-3-small",
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$ThrottleLimit = 3,
        
        [Parameter()]
        [ValidateRange(1, 2048)]
        [int]$BatchSize = 100
    )
    
    begin {
        $TextBatch = @()
        
        # Get the plain text API key from SecureString for parallel runspaces
        $PlainApiKey = $null
        try {
            if ($Global:OpenAIConfig -and $Global:OpenAIConfig.ApiKey) {
                $PlainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Global:OpenAIConfig.ApiKey))
            } else {
                throw "OpenAI API key not configured. Please run Set-OpenAIKey first."
            }
        } catch {
            Write-Error "Failed to retrieve API key: $($_.Exception.Message)"
            return
        }
    }
    
    process {
        $TextBatch += $Texts
    }
    
    end {
        try {
            # Split into batches for efficient API usage
            $Batches = for ($i = 0; $i -lt $TextBatch.Count; $i += $BatchSize) {
                , $TextBatch[$i..([Math]::Min($i + $BatchSize - 1, $TextBatch.Count - 1))]
            }
            
            Write-Host "Processing $($TextBatch.Count) texts in $($Batches.Count) batches with throttle limit $ThrottleLimit" -ForegroundColor Cyan
            
            $AllResults = $Batches | ForEach-Object -Parallel {
                # Import variables into parallel runspace
                $Config = $using:Global:OpenAIConfig
                $PlainApiKey = $using:PlainApiKey
                $Model = $using:Model
                $CurrentBatch = $_
                
                $Body = @{
                    model = $Model
                    input = $CurrentBatch
                    encoding_format = "float"
                }
                
                try {
                    $Uri = "$($Config.BaseUrl)/embeddings"
                    $Headers = @{
                        "Authorization" = "Bearer $PlainApiKey"
                        "Content-Type" = "application/json"
                    }
                    
                    if ($Config.Organization) {
                        $Headers["OpenAI-Organization"] = $Config.Organization
                    }
                    
                    $RequestBody = ($Body | ConvertTo-Json -Depth 20 -Compress)
                    $Response = Invoke-RestMethod -Uri $Uri -Method POST -Headers $Headers -Body $RequestBody -TimeoutSec $Config.TimeoutSec
                    
                    # Return embeddings for this batch
                    for ($j = 0; $j -lt $Response.data.Count; $j++) {
                        [PSCustomObject]@{
                            Text = $CurrentBatch[$j]
                            Embedding = $Response.data[$j].embedding
                            Model = $Model
                            Dimensions = $Response.data[$j].embedding.Count
                            Index = $Response.data[$j].index
                            ProcessedAt = Get-Date
                            ThreadId = [Threading.Thread]::CurrentThread.ManagedThreadId
                            Success = $true
                            Error = $null
                        }
                    }
                }
                catch {
                    # Return error results for all texts in this batch
                    foreach ($Text in $CurrentBatch) {
                        [PSCustomObject]@{
                            Text = $Text
                            Embedding = $null
                            Error = $_.Exception.Message
                            Model = $Model
                            ProcessedAt = Get-Date
                            ThreadId = [Threading.Thread]::CurrentThread.ManagedThreadId
                            Success = $false
                            Dimensions = 0
                        }
                    }
                }
            } -ThrottleLimit $ThrottleLimit
            
            # Calculate summary statistics
            $SuccessfulResults = $AllResults | Where-Object { $_.Success }
            $FailedResults = $AllResults | Where-Object { -not $_.Success }
            
            Write-Host "Parallel embedding completed: $($SuccessfulResults.Count) successful, $($FailedResults.Count) failed" -ForegroundColor Green
            
            # Return comprehensive results
            [PSCustomObject]@{
                Results = $AllResults
                Summary = [PSCustomObject]@{
                    TotalProcessed = $AllResults.Count
                    Successful = $SuccessfulResults.Count
                    Failed = $FailedResults.Count
                    Model = $Model
                    ThrottleLimit = $ThrottleLimit
                    BatchSize = $BatchSize
                    BatchCount = $Batches.Count
                    Dimensions = if ($SuccessfulResults) { $SuccessfulResults[0].Dimensions } else { 0 }
                    ProcessedAt = Get-Date
                }
            }
        }
        finally {
            # Clear plain text API key from memory
            if ($PlainApiKey) {
                $PlainApiKey = $null
                [System.GC]::Collect()
            }
        }
    }
}

#endregion
