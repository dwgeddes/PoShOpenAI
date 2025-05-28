#region Batch API Functions
function New-OpenAIBatch {
    <#
    .SYNOPSIS
    Creates a batch job
    .PARAMETER InputFileId
    ID of the input file containing batch requests
    .PARAMETER Endpoint
    API endpoint for the batch requests
    .PARAMETER CompletionWindow
    Time window for completion
    .PARAMETER Metadata
    Additional metadata
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFileId,
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [string]$CompletionWindow = "24h",
        [hashtable]$Metadata = @{}
    )
    
    if ($PSCmdlet.ShouldProcess($InputFileId, 'Create new OpenAI batch job')) {
        $Body = @{
            input_file_id = $InputFileId
            endpoint = $Endpoint
            completion_window = $CompletionWindow
            metadata = $Metadata
        }
        
        return Invoke-OpenAIRequest -Endpoint "batches" -Body $Body
    }
}

function Get-OpenAIBatchList {
    <#
    .SYNOPSIS
    Lists batch jobs
    .PARAMETER Limit
    Number of batches to retrieve
    .PARAMETER After
    Cursor for pagination
    #>
    param(
        [int]$Limit = 20,
        [string]$After = $null
    )
    
    $QueryParams = @("limit=$Limit")
    if ($After) { $QueryParams += "after=$After" }
    
    $Endpoint = "batches?" + ($QueryParams -join "&")
    return Invoke-OpenAIRequest -Endpoint $Endpoint -Method "GET"
}

function Get-OpenAIBatch {
    <#
    .SYNOPSIS
    Gets a specific batch job
    .PARAMETER BatchId
    ID of the batch job
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$BatchId
    )
    
    return Invoke-OpenAIRequest -Endpoint "batches/$BatchId" -Method "GET"
}

function Stop-OpenAIBatch {
    <#
    .SYNOPSIS
    Cancels a batch job
    .PARAMETER BatchId
    ID of the batch job to cancel
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BatchId
    )
    process {
        if ($PSCmdlet.ShouldProcess($BatchId, 'Cancel OpenAI batch job')) {
            return Invoke-OpenAIRequest -Endpoint "batches/$BatchId/cancel" -Method "POST"
        }
    }
}
#endregion
