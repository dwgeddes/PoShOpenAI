#region Messages API Functions
function Add-OpenAIMessage {
    <#
    .SYNOPSIS
    Adds a message to a thread
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER Role
    Role of the message sender
    .PARAMETER Content
    Content of the message
    .PARAMETER FileIds
    File IDs attached to the message
    .PARAMETER Metadata
    Additional metadata
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$Role,
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [array]$FileIds = @(),
        [hashtable]$Metadata = @{}
    )
    
    $Body = @{
        role = $Role
        content = $Content
        file_ids = $FileIds
        metadata = $Metadata
    }
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/messages" -Body $Body
}

function Get-OpenAIMessages {
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
