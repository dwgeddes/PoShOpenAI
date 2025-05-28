#region Assistant Workflow Functions

function Invoke-OpenAIAssistant {
    <#
    .SYNOPSIS
    Simplified function to send a query to an OpenAI Assistant and get the response
    .PARAMETER AssistantId
    ID of the assistant to use
    .PARAMETER Message
    The message/query to send to the assistant - supports pipeline input
    .PARAMETER ThreadId
    Optional existing thread ID to continue a conversation
    .PARAMETER Instructions
    Optional override instructions for this run
    .PARAMETER Model
    Optional model override for this run
    .PARAMETER Tools
    Optional tools override for this run
    .PARAMETER FileIds
    Optional file IDs to attach to the message (for vision or document analysis)
    .PARAMETER ImagePaths
    Optional local image file paths - will be automatically uploaded for vision analysis
    .PARAMETER MaxWaitSeconds
    Maximum time to wait for the run to complete (default: 60 seconds)
    .PARAMETER PollIntervalSeconds
    How often to check run status (default: 2 seconds)
    .EXAMPLE
    Invoke-OpenAIAssistant -AssistantId "asst_123" -Message "What is PowerShell?"
    .EXAMPLE
    "Question 1", "Question 2" | Invoke-OpenAIAssistant -AssistantId "asst_123"
    .EXAMPLE
    $result = Invoke-OpenAIAssistant -AssistantId "asst_123" -Message "Analyze this image" -FileIds @("file_123")
    .EXAMPLE
    $result = Invoke-OpenAIAssistant -AssistantId "asst_123" -Message "What do you see in this image?" -ImagePaths @("photo.jpg")
    .EXAMPLE
    $result = Invoke-OpenAIAssistant -AssistantId "asst_123" -Message "Compare these images" -ImagePaths @("image1.jpg", "image2.png")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AssistantId,
        
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string[]]$Message,
        
        [Parameter()]
        [string]$ThreadId = $null,
        
        [Parameter()]
        [string]$Instructions = $null,
        
        [Parameter()]
        [string]$Model = $null,
        
        [Parameter()]
        [array]$Tools = $null,
        
        [Parameter()]
        [array]$FileIds = @(),
        
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
        [ValidateRange(10, 600)]
        [int]$MaxWaitSeconds = 60,
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$PollIntervalSeconds = 2
    )
    
    begin {
        if (-not $Global:OpenAIConfig.ApiKey) {
            Write-Warning "OpenAI API key not configured. Use Set-OpenAIKey first."
            return
        }
        
        # If no thread provided, we'll create one per message batch
        $UseExistingThread = -not [string]::IsNullOrEmpty($ThreadId)
    }
    
    process {
        foreach ($Msg in $Message) {
            $CurrentThreadId = $null
            $UploadedFileIds = @()
            
            try {
                # Upload images if provided
                if ($ImagePaths.Count -gt 0) {
                    Write-Verbose "Uploading $($ImagePaths.Count) image(s) for vision analysis..."
                    foreach ($ImagePath in $ImagePaths) {
                        try {
                            $UploadResult = Add-OpenAIFile -FilePath $ImagePath -Purpose "vision"
                            $UploadedFileIds += $UploadResult.id
                            Write-Verbose "Uploaded image: $ImagePath -> $($UploadResult.id)"
                        } catch {
                            Write-Warning "Failed to upload image $ImagePath`: $($_.Exception.Message)"
                        }
                    }
                }
                
                # Combine provided FileIds with uploaded image FileIds
                $AllFileIds = @()
                $AllFileIds += $FileIds
                $AllFileIds += $UploadedFileIds
                
                # Create or use existing thread
                if (-not $UseExistingThread) {
                    $Thread = New-OpenAIThread
                    $CurrentThreadId = $Thread.id
                } else {
                    $CurrentThreadId = $ThreadId
                }
                
                # Add the message to the thread with proper vision support
                $MessageParams = @{
                    ThreadId = $CurrentThreadId
                    Role = "user"
                    Content = $Msg
                }
                
                # Use structured content format for vision if images are provided
                if ($UploadedFileIds.Count -gt 0) {
                    $MessageParams.ImageFileIds = $UploadedFileIds
                }
                
                # Add any additional file IDs (non-vision files)
                if ($FileIds.Count -gt 0) {
                    $MessageParams.FileIds = $FileIds
                }
                
                $null = Add-OpenAIMessage @MessageParams
                
                # Start the run
                $RunParams = @{
                    ThreadId = $CurrentThreadId
                    AssistantId = $AssistantId
                }
                if ($Instructions) { $RunParams.Instructions = $Instructions }
                if ($Model) { $RunParams.Model = $Model }
                if ($Tools) { $RunParams.Tools = $Tools }
                
                $Run = Start-OpenAIRun @RunParams
                
                # Wait for completion
                $StartTime = Get-Date
                $RunCompleted = $false
                $FinalRun = $null
                
                do {
                    Start-Sleep -Seconds $PollIntervalSeconds
                    $FinalRun = Get-OpenAIRun -ThreadId $CurrentThreadId -RunId $Run.id
                    
                    $RunCompleted = $FinalRun.status -in @("completed", "failed", "cancelled", "expired")
                    $ElapsedSeconds = ((Get-Date) - $StartTime).TotalSeconds
                    
                    if ($ElapsedSeconds -gt $MaxWaitSeconds) {
                        # Try to cancel the run
                        try {
                            Stop-OpenAIRun -ThreadId $CurrentThreadId -RunId $Run.id | Out-Null
                        } catch {}
                        throw "Assistant run timed out after $MaxWaitSeconds seconds"
                    }
                    
                    # Handle tool calls if needed
                    if ($FinalRun.status -eq "requires_action") {
                        Write-Warning "Assistant requires tool calls - this simple function doesn't handle tool execution. Consider using the individual API functions for complex workflows."
                        break
                    }
                    
                } while (-not $RunCompleted)
                
                # Get the response
                if ($FinalRun.status -eq "completed") {
                    $Messages = Get-OpenAIMessages -ThreadId $CurrentThreadId -Limit 1 -Order "desc"
                    $ResponseMessage = $Messages.data[0]
                    
                    [PSCustomObject]@{
                        # Input Information
                        Input = $Msg
                        AssistantId = $AssistantId
                        ThreadId = $CurrentThreadId
                        FileIds = $FileIds
                        ImagePaths = $ImagePaths
                        UploadedFileIds = $UploadedFileIds
                        
                        # Response Content
                        Response = $ResponseMessage.content[0].text.value
                        ResponseRole = $ResponseMessage.role
                        ResponseId = $ResponseMessage.id
                        
                        # Run Information
                        RunId = $Run.id
                        RunStatus = $FinalRun.status
                        Model = $FinalRun.model
                        Instructions = $FinalRun.instructions
                        
                        # Token Usage (if available)
                        PromptTokens = if ($FinalRun.usage) { $FinalRun.usage.prompt_tokens } else { $null }
                        CompletionTokens = if ($FinalRun.usage) { $FinalRun.usage.completion_tokens } else { $null }
                        TotalTokens = if ($FinalRun.usage) { $FinalRun.usage.total_tokens } else { $null }
                        
                        # Timing Information
                        CreatedAt = if ($FinalRun.created_at) { [DateTimeOffset]::FromUnixTimeSeconds($FinalRun.created_at).DateTime } else { $null }
                        StartedAt = if ($FinalRun.started_at) { [DateTimeOffset]::FromUnixTimeSeconds($FinalRun.started_at).DateTime } else { $null }
                        CompletedAt = if ($FinalRun.completed_at) { [DateTimeOffset]::FromUnixTimeSeconds($FinalRun.completed_at).DateTime } else { $null }
                        ProcessingTime = if ($FinalRun.started_at -and $FinalRun.completed_at) { 
                            [DateTimeOffset]::FromUnixTimeSeconds($FinalRun.completed_at).DateTime - [DateTimeOffset]::FromUnixTimeSeconds($FinalRun.started_at).DateTime 
                        } else { $null }
                        
                        # Status Information
                        Success = ($FinalRun.status -eq "completed")
                        Error = if ($FinalRun.last_error) { $FinalRun.last_error.message } else { $null }
                        ToolCalls = ($null -ne $FinalRun.required_action)
                        
                        # Assistant Capabilities
                        SupportsVision = ($FinalRun.model -in @("gpt-4o", "gpt-4-turbo", "gpt-4-vision-preview"))
                        SupportsCodeInterpreter = ($null -ne ($FinalRun.tools | Where-Object { $_.type -eq "code_interpreter" }))
                        SupportsRetrieval = ($null -ne ($FinalRun.tools | Where-Object { $_.type -eq "retrieval" }))
                        SupportsFunctions = ($null -ne ($FinalRun.tools | Where-Object { $_.type -eq "function" }))
                        
                        # Vision Information
                        HasImageAttachments = ($AllFileIds.Count -gt 0)
                        ImageCount = $ImagePaths.Count
                        TotalFileAttachments = $AllFileIds.Count
                        
                        # Cleanup Information
                        ThreadCreated = (-not $UseExistingThread)
                        ShouldCleanupThread = (-not $UseExistingThread)
                    }
                } else {
                    [PSCustomObject]@{
                        Input = $Msg
                        AssistantId = $AssistantId
                        ThreadId = $CurrentThreadId
                        ImagePaths = $ImagePaths
                        UploadedFileIds = $UploadedFileIds
                        Response = $null
                        Success = $false
                        Error = "Run failed with status: $($FinalRun.status)"
                        RunStatus = $FinalRun.status
                        RunId = $Run.id
                        ThreadCreated = (-not $UseExistingThread)
                        ShouldCleanupThread = (-not $UseExistingThread)
                    }
                }
                
                # Clean up thread if we created it (unless user wants to keep it)
                if (-not $UseExistingThread) {
                    try {
                        Remove-OpenAIThread -ThreadId $CurrentThreadId | Out-Null
                    } catch {
                        Write-Warning "Failed to clean up thread $CurrentThreadId`: $($_.Exception.Message)"
                    }
                }
                
            } catch {
                [PSCustomObject]@{
                    Input = $Msg
                    AssistantId = $AssistantId
                    ThreadId = $CurrentThreadId
                    ImagePaths = $ImagePaths
                    UploadedFileIds = $UploadedFileIds
                    Response = $null
                    Success = $false
                    Error = $_.Exception.Message
                    ErrorType = $_.Exception.GetType().Name
                    ProcessedAt = Get-Date
                }
                
                # Clean up thread if we created it
                if (-not $UseExistingThread -and $CurrentThreadId) {
                    try {
                        Remove-OpenAIThread -ThreadId $CurrentThreadId | Out-Null
                    } catch {}
                }
            }
            finally {
                # Clean up uploaded files (they're attached to the thread/message now)
                foreach ($FileId in $UploadedFileIds) {
                    try {
                        Remove-OpenAIFile -FileId $FileId | Out-Null
                    } catch {
                        Write-Verbose "Could not clean up uploaded file $FileId`: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}

function Start-AssistantConversation {
    <#
    .SYNOPSIS
    Starts an interactive conversation with an OpenAI Assistant
    .PARAMETER AssistantId
    ID of the assistant to use
    .PARAMETER Instructions
    Optional override instructions for the conversation
    .EXAMPLE
    Start-AssistantConversation -AssistantId "asst_123"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$AssistantId,
        [string]$Instructions = $null
    )
    
    if (-not $Global:OpenAIConfig.ApiKey) {
        Write-Warning "OpenAI API key not configured. Use Set-OpenAIKey first."
        return
    }
    
    # Get assistant details
    try {
        $Assistant = Get-OpenAIAssistant -AssistantId $AssistantId
        Write-Host "Starting conversation with: $($Assistant.name ?? 'Assistant')" -ForegroundColor Cyan
        Write-Host "Model: $($Assistant.model)" -ForegroundColor Yellow
        Write-Host "Type 'exit' to quit, 'clear' to start new thread`n" -ForegroundColor Gray
    } catch {
        Write-Error "Failed to get assistant details: $($_.Exception.Message)"
        return
    }
    
    # Create initial thread
    $Thread = New-OpenAIThread
    $ThreadId = $Thread.id
    
    while ($true) {
        $UserInput = Read-Host "`nYou"
        
        if ($UserInput -eq "exit") {
            break
        }
        
        if ($UserInput -eq "clear") {
            # Clean up old thread and create new one
            try {
                Remove-OpenAIThread -ThreadId $ThreadId | Out-Null
            } catch {}
            $Thread = New-OpenAIThread
            $ThreadId = $Thread.id
            Write-Host "New conversation thread created" -ForegroundColor Yellow
            continue
        }
        
        if ([string]::IsNullOrWhiteSpace($UserInput)) {
            continue
        }
        
        try {
            Write-Host "Assistant: " -ForegroundColor Green -NoNewline
            
            $Result = Invoke-OpenAIAssistant -AssistantId $AssistantId -Message $UserInput -ThreadId $ThreadId -Instructions $Instructions
            
            if ($Result.Success) {
                Write-Host $Result.Response -ForegroundColor White
            } else {
                Write-Host "Error: $($Result.Error)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Clean up
    try {
        Remove-OpenAIThread -ThreadId $ThreadId | Out-Null
        Write-Host "`nConversation ended and thread cleaned up." -ForegroundColor Gray
    } catch {
        Write-Host "`nConversation ended." -ForegroundColor Gray
    }
}

function New-VisionAssistant {
    <#
    .SYNOPSIS
    Creates a new OpenAI Assistant with vision capabilities
    .PARAMETER Name
    Name of the assistant
    .PARAMETER Instructions
    Instructions for the assistant
    .PARAMETER Model
    Model to use (must support vision)
    .PARAMETER Description
    Description of the assistant
    .EXAMPLE
    $assistant = New-VisionAssistant -Name "Image Analyzer" -Instructions "You are an expert at analyzing images and describing what you see in detail."
    .EXAMPLE
    $assistant = New-VisionAssistant -Name "Photo Critic" -Instructions "You are a professional photographer who provides constructive feedback on images." -Model "gpt-4o"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Instructions,
        
        [Parameter()]
        [ValidateSet("gpt-4o", "gpt-4-turbo", "gpt-4-vision-preview")]
        [string]$Model = "gpt-4o",
        
        [Parameter()]
        [string]$Description = "An assistant with vision capabilities"
    )
    
    if (-not $Global:OpenAIConfig.ApiKey) {
        Write-Warning "OpenAI API key not configured. Use Set-OpenAIKey first."
        return
    }
    
    try {
        $Assistant = New-OpenAIAssistant -Name $Name -Instructions $Instructions -Model $Model -Description $Description
        
        # Add vision capability information to the response
        $Assistant | Add-Member -NotePropertyName "SupportsVision" -NotePropertyValue $true
        $Assistant | Add-Member -NotePropertyName "VisionModel" -NotePropertyValue $Model
        $Assistant | Add-Member -NotePropertyName "CreatedByVisionHelper" -NotePropertyValue $true
        
        Write-Host "✅ Vision-capable assistant created: $($Assistant.id)" -ForegroundColor Green
        Write-Host "   Name: $Name" -ForegroundColor Gray
        Write-Host "   Model: $Model" -ForegroundColor Gray
        Write-Host "   Vision Support: Enabled" -ForegroundColor Gray
        
        return $Assistant
    }
    catch {
        Write-Error "Failed to create vision assistant: $($_.Exception.Message)"
        return $null
    }
}

#endregion
