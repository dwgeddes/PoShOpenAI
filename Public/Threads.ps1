#region Threads API Functions

function New-OpenAIThread {
    <#
    .SYNOPSIS
    Creates a new conversation thread
    .PARAMETER Messages
    Optional initial messages for the thread
    .PARAMETER Metadata
    Optional metadata for the thread
    #>
    [CmdletBinding()]
    param(
        [array]$Messages = @(),
        [hashtable]$Metadata = @{}
    )
    
    $Body = @{
        metadata = $Metadata
    }
    
    if ($Messages.Count -gt 0) {
        $Body.messages = $Messages
    }
    
    return Invoke-OpenAIRequest -Endpoint "threads" -Body $Body
}

function Get-OpenAIThread {
    <#
    .SYNOPSIS
    Gets a specific thread
    .PARAMETER ThreadId
    ID of the thread to retrieve
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId
    )
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId" -Method "GET"
}

function Update-OpenAIThread {
    <#
    .SYNOPSIS
    Updates a thread
    .PARAMETER ThreadId
    ID of the thread to update
    .PARAMETER Metadata
    Updated metadata for the thread
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [hashtable]$Metadata = @{}
    )
    
    $Body = @{
        metadata = $Metadata
    }
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId" -Body $Body -Method "POST"
}

function Remove-OpenAIThread {
    <#
    .SYNOPSIS
    Deletes a thread
    .PARAMETER ThreadId
    ID of the thread to delete
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId
    )
    process {
        if ($PSCmdlet.ShouldProcess($ThreadId, 'Delete OpenAI thread')) {
            return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId" -Method "DELETE"
        }
    }
}

#endregion
