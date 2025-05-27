#region Assistants API Functions
function New-OpenAIAssistant {
    <#
    .SYNOPSIS
    Creates a new assistant
    .PARAMETER Model
    Model to use for the assistant
    .PARAMETER Name
    Name of the assistant
    .PARAMETER Description
    Description of the assistant
    .PARAMETER Instructions
    System instructions for the assistant
    .PARAMETER Tools
    Array of tools the assistant can use
    .PARAMETER FileIds
    Array of file IDs for the assistant
    .PARAMETER Metadata
    Additional metadata
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Model,
        [string]$Name = $null,
        [string]$Description = $null,
        [string]$Instructions = $null,
        [array]$Tools = @(),
        [array]$FileIds = @(),
        [hashtable]$Metadata = @{}
    )
    
    $Body = @{
        model = $Model
        tools = $Tools
        file_ids = $FileIds
        metadata = $Metadata
    }
    
    if ($Name) { $Body.name = $Name }
    if ($Description) { $Body.description = $Description }
    if ($Instructions) { $Body.instructions = $Instructions }
    
    return Invoke-OpenAIRequest -Endpoint "assistants" -Body $Body
}

function Get-OpenAIAssistants {
    <#
    .SYNOPSIS
    Lists assistants
    .PARAMETER Limit
    Number of assistants to retrieve
    .PARAMETER Order
    Sort order (asc or desc)
    .PARAMETER After
    Cursor for pagination
    .PARAMETER Before
    Cursor for pagination
    #>
    param(
        [int]$Limit = 20,
        [string]$Order = "desc",
        [string]$After = $null,
        [string]$Before = $null
    )
    
    $QueryParams = @("limit=$Limit", "order=$Order")
    if ($After) { $QueryParams += "after=$After" }
    if ($Before) { $QueryParams += "before=$Before" }
    
    $Endpoint = "assistants?" + ($QueryParams -join "&")
    return Invoke-OpenAIRequest -Endpoint $Endpoint -Method "GET"
}

function Get-OpenAIAssistant {
    <#
    .SYNOPSIS
    Gets a specific assistant
    .PARAMETER AssistantId
    ID of the assistant
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$AssistantId
    )
    
    return Invoke-OpenAIRequest -Endpoint "assistants/$AssistantId" -Method "GET"
}

function Update-OpenAIAssistant {
    <#
    .SYNOPSIS
    Updates an assistant
    .PARAMETER AssistantId
    ID of the assistant to update
    .PARAMETER Model
    Model to use
    .PARAMETER Name
    Name of the assistant
    .PARAMETER Description
    Description of the assistant
    .PARAMETER Instructions
    System instructions
    .PARAMETER Tools
    Array of tools
    .PARAMETER FileIds
    Array of file IDs
    .PARAMETER Metadata
    Additional metadata
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$AssistantId,
        [string]$Model = $null,
        [string]$Name = $null,
        [string]$Description = $null,
        [string]$Instructions = $null,
        [array]$Tools = $null,
        [array]$FileIds = $null,
        [hashtable]$Metadata = $null
    )
    
    $Body = @{}
    if ($Model) { $Body.model = $Model }
    if ($Name) { $Body.name = $Name }
    if ($Description) { $Body.description = $Description }
    if ($Instructions) { $Body.instructions = $Instructions }
    if ($Tools) { $Body.tools = $Tools }
    if ($FileIds) { $Body.file_ids = $FileIds }
    if ($Metadata) { $Body.metadata = $Metadata }
    
    return Invoke-OpenAIRequest -Endpoint "assistants/$AssistantId" -Body $Body -Method "POST"
}

function Remove-OpenAIAssistant {
    <#
    .SYNOPSIS
    Deletes an assistant
    .PARAMETER AssistantId
    ID of the assistant to delete
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$AssistantId
    )
    
    return Invoke-OpenAIRequest -Endpoint "assistants/$AssistantId" -Method "DELETE"
}
#endregion
