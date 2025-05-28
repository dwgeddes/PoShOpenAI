#region Messages API Functions
function Add-OpenAIMessage {
    <#
    .SYNOPSIS
    Adds a message to a thread with support for structured content (text + images for vision)
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER Role
    Role of the message sender
    .PARAMETER Content
    Content of the message (can be string or structured content array)
    .PARAMETER FileIds
    File IDs attached to the message (legacy support)
    .PARAMETER ImageFileIds
    Image file IDs for vision analysis (will be structured into content)
    .PARAMETER Metadata
    Additional metadata
    .EXAMPLE
    Add-OpenAIMessage -ThreadId "thread_123" -Role "user" -Content "Hello"
    .EXAMPLE
    Add-OpenAIMessage -ThreadId "thread_123" -Role "user" -Content "What's in this image?" -ImageFileIds @("file_123")
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$Role,
        [Parameter(Mandatory = $true)]
        $Content,  # Can be string or array for structured content
        [array]$FileIds = @(),
        [array]$ImageFileIds = @(),
        [hashtable]$Metadata = @{}
    )
    
    # Build the message body
    $Body = @{
        role = $Role
        metadata = $Metadata
    }
    
    # Handle structured content for vision
    if ($ImageFileIds.Count -gt 0 -and $Content -is [string]) {
        # Create structured content with text and images for vision
        $StructuredContent = @()
        
        # Add text content
        if (-not [string]::IsNullOrWhiteSpace($Content)) {
            $StructuredContent += @{
                type = "text"
                text = $Content
            }
        }
        
        # Add image content for vision
        foreach ($ImageFileId in $ImageFileIds) {
            $StructuredContent += @{
                type = "image_file"
                image_file = @{
                    file_id = $ImageFileId
                }
            }
        }
        
        $Body.content = $StructuredContent
    }
    elseif ($Content -is [array]) {
        # Content is already structured
        $Body.content = $Content
    }
    else {
        # Simple text content
        $Body.content = $Content
    }
    
    # Add legacy file_ids support if no structured content is used
    if ($FileIds.Count -gt 0 -and $ImageFileIds.Count -eq 0) {
        $Body.file_ids = $FileIds
    }
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/messages" -Body $Body
}

function Get-OpenAIMessageList {
    <#
    .SYNOPSIS
    Lists messages in a thread
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER Limit
    Number of messages to retrieve
    .PARAMETER Order
    Sort order
    .PARAMETER After
    Cursor for pagination
    .PARAMETER Before
    Cursor for pagination
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [int]$Limit = 20,
        [string]$Order = "desc",
        [string]$After = $null,
        [string]$Before = $null
    )
    
    $QueryParams = @("limit=$Limit", "order=$Order")
    if ($After) { $QueryParams += "after=$After" }
    if ($Before) { $QueryParams += "before=$Before" }
    
    $Endpoint = "threads/$ThreadId/messages?" + ($QueryParams -join "&")
    return Invoke-OpenAIRequest -Endpoint $Endpoint -Method "GET"
}

function Get-OpenAIMessage {
    <#
    .SYNOPSIS
    Gets a specific message
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER MessageId
    ID of the message
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$MessageId
    )
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/messages/$MessageId" -Method "GET"
}

function Update-OpenAIMessage {
    <#
    .SYNOPSIS
    Updates a message
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER MessageId
    ID of the message
    .PARAMETER Metadata
    Updated metadata
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$MessageId,
        [hashtable]$Metadata = @{}
    )
    
    $Body = @{
        metadata = $Metadata
    }
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/messages/$MessageId" -Body $Body -Method "POST"
}
#endregion
