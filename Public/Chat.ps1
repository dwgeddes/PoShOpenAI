#region Chat Functions

function Invoke-OpenAIChat {
    <#
    .SYNOPSIS
    Creates a chat completion using OpenAI's chat models with SecureString support
    .PARAMETER Messages
    Array of message objects with 'role' and 'content' properties
    .PARAMETER Model
    Model to use for chat completion
    .PARAMETER MaxTokens
    Maximum tokens to generate
    .PARAMETER Temperature
    Temperature for randomness (0.0 to 2.0)
    .PARAMETER TopP
    Alternative to temperature for nucleus sampling
    .PARAMETER FrequencyPenalty
    Penalize frequent tokens (-2.0 to 2.0)
    .PARAMETER PresencePenalty
    Penalize new tokens (-2.0 to 2.0)
    .PARAMETER Stop
    Stop sequences
    .PARAMETER Stream
    Whether to stream the response
    .PARAMETER User
    Unique user identifier
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [array]$Messages,
        
        [Parameter()]
        [ValidateSet("gpt-4o", "gpt-4o-mini", "gpt-4", "gpt-4-turbo", "gpt-3.5-turbo")]
        [string]$Model = $Global:OpenAIConfig.DefaultModel,
        
        [Parameter()]
        [ValidateRange(1, 4096)]
        [int]$MaxTokens = $Global:OpenAIConfig.MaxTokens,
        
        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature = $Global:OpenAIConfig.Temperature,
        
        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$TopP = $null,
        
        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [double]$FrequencyPenalty = 0,
        
        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [double]$PresencePenalty = 0,
        
        [Parameter()]
        [string[]]$Stop = $null,
        
        [Parameter()]
        [switch]$Stream,
        
        [Parameter()]
        [string]$User = $null
    )
    
    $Body = @{
        model = $Model
        messages = $Messages
        max_tokens = $MaxTokens
        temperature = $Temperature
        frequency_penalty = $FrequencyPenalty
        presence_penalty = $PresencePenalty
    }
    
    if ($PSBoundParameters.ContainsKey('TopP')) { $Body.top_p = $TopP }
    if ($Stop) { $Body.stop = $Stop }
    if ($Stream) { $Body.stream = $true }
    if ($User) { $Body.user = $User }
    
    return Invoke-OpenAIRequest -Endpoint "chat/completions" -Body $Body
}

function Send-ChatMessage {
    <#
    .SYNOPSIS
    Simplified function to send chat messages with full pipeline support and comprehensive analytics
    .PARAMETER Message
    The message(s) to send - supports pipeline input
    .PARAMETER SystemMessage
    Optional system message for context
    .PARAMETER Role
    Role of the message sender (user, assistant, system)
    .PARAMETER Model
    Model to use for chat completion
    .PARAMETER MaxTokens
    Maximum tokens to generate
    .PARAMETER Temperature
    Temperature for randomness (0.0 to 2.0)
    .PARAMETER TopP
    Alternative to temperature for nucleus sampling
    .PARAMETER FrequencyPenalty
    Penalize frequent tokens (-2.0 to 2.0)
    .PARAMETER PresencePenalty
    Penalize new tokens (-2.0 to 2.0)
    .EXAMPLE
    Send-ChatMessage -Message "What is PowerShell?"
    .EXAMPLE
    "Question 1", "Question 2" | Send-ChatMessage -SystemMessage "You are a helpful assistant"
    .EXAMPLE
    Get-Content questions.txt | Send-ChatMessage -Model "gpt-4o" -MaxTokens 500
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string[]]$Message,
        
        [Parameter()]
        [string]$SystemMessage = $null,
        
        [Parameter()]
        [ValidateSet("user", "assistant", "system")]
        [string]$Role = "user",
        
        [Parameter()]
        [ValidateSet("gpt-4o", "gpt-4o-mini", "gpt-4", "gpt-4-turbo", "gpt-3.5-turbo")]
        [string]$Model = $Global:OpenAIConfig.DefaultModel,
        
        [Parameter()]
        [ValidateRange(1, 4096)]
        [int]$MaxTokens = $Global:OpenAIConfig.MaxTokens,
        
        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature = $Global:OpenAIConfig.Temperature,
        
        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$TopP = $null,
        
        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [double]$FrequencyPenalty = 0,
        
        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [double]$PresencePenalty = 0
    )
    
    process {
        foreach ($Msg in $Message) {
            $Messages = @()
            
            # Add system message if provided
            if ($SystemMessage) {
                $Messages += @{
                    role = "system"
                    content = $SystemMessage
                }
            }
            
            # Add user message
            $Messages += @{
                role = $Role
                content = $Msg
            }
            
            $ChatParams = @{
                Messages = $Messages
                Model = $Model
                MaxTokens = $MaxTokens
                Temperature = $Temperature
                FrequencyPenalty = $FrequencyPenalty
                PresencePenalty = $PresencePenalty
            }
            
            if ($PSBoundParameters.ContainsKey('TopP')) {
                $ChatParams.TopP = $TopP
            }
            
            try {
                $Response = Invoke-OpenAIChat @ChatParams
                
                # Create comprehensive, PowerShell-friendly object
                [PSCustomObject]@{
                    # Input Information
                    Input = $Msg
                    SystemMessage = $SystemMessage
                    InputRole = $Role
                    
                    # Response Content
                    Response = $Response.choices[0].message.content
                    ResponseRole = $Response.choices[0].message.role
                    FinishReason = $Response.choices[0].finish_reason
                    
                    # Model & Configuration
                    Model = $Response.model
                    RequestedModel = $Model
                    Temperature = $Temperature
                    MaxTokens = $MaxTokens
                    FrequencyPenalty = $FrequencyPenalty
                    PresencePenalty = $PresencePenalty
                    
                    # Token Usage & Cost Tracking
                    PromptTokens = $Response.usage.prompt_tokens
                    CompletionTokens = $Response.usage.completion_tokens
                    TotalTokens = $Response.usage.total_tokens
                    EstimatedCost = switch ($Response.model) {
                        "gpt-4o" { [math]::Round(($Response.usage.prompt_tokens * 0.000005 + $Response.usage.completion_tokens * 0.000015), 6) }
                        "gpt-4o-mini" { [math]::Round(($Response.usage.prompt_tokens * 0.00000015 + $Response.usage.completion_tokens * 0.0000006), 6) }
                        "gpt-4" { [math]::Round(($Response.usage.prompt_tokens * 0.00003 + $Response.usage.completion_tokens * 0.00006), 6) }
                        "gpt-4-turbo" { [math]::Round(($Response.usage.prompt_tokens * 0.00001 + $Response.usage.completion_tokens * 0.00003), 6) }
                        "gpt-3.5-turbo" { [math]::Round(($Response.usage.prompt_tokens * 0.0000005 + $Response.usage.completion_tokens * 0.0000015), 6) }
                        default { $null }
                    }
                    
                    # API Response Metadata
                    ResponseId = $Response.id
                    Created = if ($Response.created) { [DateTimeOffset]::FromUnixTimeSeconds($Response.created).DateTime } else { $null }
                    SystemFingerprint = $Response.system_fingerprint
                    
                    # Processing Information
                    ProcessedAt = Get-Date
                    Success = $true
                    Error = $null
                    
                    # Advanced Information (for debugging/analysis)
                    ChoiceIndex = $Response.choices[0].index
                    HasMultipleChoices = ($Response.choices.Count -gt 1)
                    LogProbs = $Response.choices[0].logprobs
                    
                    # Pipeline Information
                    PipelineIndex = if ($Message.Count -gt 1) { [Array]::IndexOf($Message, $Msg) } else { 0 }
                    BatchSize = $Message.Count
                }
            }
            catch {
                [PSCustomObject]@{
                    # Input Information
                    Input = $Msg
                    SystemMessage = $SystemMessage
                    InputRole = $Role
                    
                    # Error Information
                    Response = $null
                    Success = $false
                    Error = $_.Exception.Message
                    ErrorType = $_.Exception.GetType().Name
                    
                    # Model & Configuration (for troubleshooting)
                    Model = $Model
                    Temperature = $Temperature
                    MaxTokens = $MaxTokens
                    
                    # Processing Information
                    ProcessedAt = Get-Date
                    
                    # Pipeline Information
                    PipelineIndex = if ($Message.Count -gt 1) { [Array]::IndexOf($Message, $Msg) } else { 0 }
                    BatchSize = $Message.Count
                }
            }
        }
    }
}

function Start-ChatConversation {
    <#
    .SYNOPSIS
    Starts an interactive chat conversation with SecureString API key support
    .PARAMETER SystemMessage
    Optional system message to set context
    .PARAMETER Model
    Model to use for the conversation
    #>
    param(
        [string]$SystemMessage = $null,
        [string]$Model = $Global:OpenAIConfig.DefaultModel
    )
    
    $Messages = @()
    
    if ($SystemMessage) {
        $Messages += @{
            role = "system"
            content = $SystemMessage
        }
    }
    
    Write-Host "Starting OpenAI Chat (type 'exit' to quit, 'clear' to reset)" -ForegroundColor Cyan
    Write-Host "Model: $Model" -ForegroundColor Yellow
    
    while ($true) {
        $UserInput = Read-Host "`nYou"
        
        if ($UserInput -eq "exit") {
            break
        }
        
        if ($UserInput -eq "clear") {
            $Messages = if ($SystemMessage) { @(@{ role = "system"; content = $SystemMessage }) } else { @() }
            Write-Host "Conversation cleared" -ForegroundColor Yellow
            continue
        }
        
        $Messages += @{
            role = "user"
            content = $UserInput
        }
        
        try {
            Write-Host "Assistant: " -ForegroundColor Green -NoNewline
            $Response = Invoke-OpenAIChat -Messages $Messages -Model $Model
            $AssistantMessage = $Response.choices[0].message.content
            Write-Host $AssistantMessage -ForegroundColor White
            
            $Messages += @{
                role = "assistant"
                content = $AssistantMessage
            }
        }
        catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

#endregion
