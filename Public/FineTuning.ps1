#region Fine-tuning Functions
function New-OpenAIFineTuningJob {
    <#
    .SYNOPSIS
    Creates a fine-tuning job
    .PARAMETER TrainingFile
    ID of the training file
    .PARAMETER Model
    Base model to fine-tune
    .PARAMETER ValidationFile
    Optional validation file ID
    .PARAMETER Hyperparameters
    Hyperparameters for fine-tuning
    .PARAMETER Suffix
    Suffix for the fine-tuned model name
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$TrainingFile,
        [Parameter(Mandatory = $true)]
        [string]$Model,
        [string]$ValidationFile = $null,
        [hashtable]$Hyperparameters = $null,
        [string]$Suffix = $null
    )
    
    $Body = @{
        training_file = $TrainingFile
        model = $Model
    }
    
    if ($ValidationFile) { $Body.validation_file = $ValidationFile }
    if ($Hyperparameters) { $Body.hyperparameters = $Hyperparameters }
    if ($Suffix) { $Body.suffix = $Suffix }
    
    return Invoke-OpenAIRequest -Endpoint "fine_tuning/jobs" -Body $Body
}

function Get-OpenAIFineTuningJobs {
    <#
    .SYNOPSIS
    Lists fine-tuning jobs
    .PARAMETER Limit
    Number of jobs to retrieve
    .PARAMETER After
    Cursor for pagination
    #>
    param(
        [int]$Limit = 20,
        [string]$After = $null
    )
    
    $QueryParams = @("limit=$Limit")
    if ($After) { $QueryParams += "after=$After" }
    
    $Endpoint = "fine_tuning/jobs"
    if ($QueryParams.Count -gt 0) {
        $Endpoint += "?" + ($QueryParams -join "&")
    }
    
    return Invoke-OpenAIRequest -Endpoint $Endpoint -Method "GET"
}

function Get-OpenAIFineTuningJob {
    <#
    .SYNOPSIS
    Gets details about a fine-tuning job
    .PARAMETER JobId
    ID of the fine-tuning job
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$JobId
    )
    
    return Invoke-OpenAIRequest -Endpoint "fine_tuning/jobs/$JobId" -Method "GET"
}

function Stop-OpenAIFineTuningJob {
    <#
    .SYNOPSIS
    Cancels a fine-tuning job
    .PARAMETER JobId
    ID of the fine-tuning job to cancel
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$JobId
    )
    
    return Invoke-OpenAIRequest -Endpoint "fine_tuning/jobs/$JobId/cancel" -Method "POST"
}

function Get-OpenAIFineTuningEvents {
    <#
    .SYNOPSIS
    Gets events for a fine-tuning job
    .PARAMETER JobId
    ID of the fine-tuning job
    .PARAMETER Limit
    Number of events to retrieve
    .PARAMETER After
    Cursor for pagination
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$JobId,
        [int]$Limit = 20,
        [string]$After = $null
    )
    
    $QueryParams = @("limit=$Limit")
    if ($After) { $QueryParams += "after=$After" }
    
    $Endpoint = "fine_tuning/jobs/$JobId/events"
    if ($QueryParams.Count -gt 0) {
        $Endpoint += "?" + ($QueryParams -join "&")
    }
    
    return Invoke-OpenAIRequest -Endpoint $Endpoint -Method "GET"
}
#endregion
