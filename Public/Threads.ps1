#region Threads API Functions
function New-OpenAIThread {
    <#
    .SYNOPSIS
    Creates a new thread
    .PARAMETER Messages
    Initial messages for the thread
    .PARAMETER Metadata
    Additional metadata
    #>
    param(
        [array]$Messages = @(),
        [hashtable]$Metadata = @{}
    )
    
    $Body = @{
        messages = $Messages
        metadata = $Metadata
    }
    
    return Invoke-OpenAIRequest -Endpoint "threads" -Body $Body
}

function Get-OpenAIThread {
    <#
    .SYNOPSIS
    Gets a specific thread
    .PARAMETER ThreadId
    ID of the thread
    #>
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
    Updated metadata
    #>
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
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId
    )
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId" -Method "DELETE"
}
#endregion
