#region Runs API Functions
function Start-OpenAIRun {
    <#
    .SYNOPSIS
    Starts a run on a thread
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER AssistantId
    ID of the assistant
    .PARAMETER Model
    Override model for this run
    .PARAMETER Instructions
    Override instructions for this run
    .PARAMETER Tools
    Override tools for this run
    .PARAMETER Metadata
    Additional metadata
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$AssistantId,
        [string]$Model = $null,
        [string]$Instructions = $null,
        [array]$Tools = $null,
        [hashtable]$Metadata = @{}
    )
    if ($PSCmdlet.ShouldProcess($ThreadId, 'Start OpenAI run on thread')) {
        $Body = @{
            assistant_id = $AssistantId
            metadata = $Metadata
        }
        if ($Model) { $Body.model = $Model }
        if ($Instructions) { $Body.instructions = $Instructions }
        if ($Tools) { $Body.tools = $Tools }
        return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/runs" -Body $Body
    }
}

function Get-OpenAIRunList {
    <#
    .SYNOPSIS
    Lists runs for a thread
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER Limit
    Number of runs to retrieve
    .PARAMETER Order
    Sort order
    .PARAMETER After
    Cursor for pagination
    .PARAMETER Before
    Cursor for pagination
    #>
    [CmdletBinding()]
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
    
    $Endpoint = "threads/$ThreadId/runs?" + ($QueryParams -join "&")
    return Invoke-OpenAIRequest -Endpoint $Endpoint -Method "GET"
}

function Get-OpenAIRun {
    <#
    .SYNOPSIS
    Gets a specific run
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER RunId
    ID of the run
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$RunId
    )
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/runs/$RunId" -Method "GET"
}

function Update-OpenAIRun {
    <#
    .SYNOPSIS
    Updates a run
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER RunId
    ID of the run
    .PARAMETER Metadata
    Updated metadata
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$RunId,
        [hashtable]$Metadata = @{}
    )
    
    $Body = @{
        metadata = $Metadata
    }
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/runs/$RunId" -Body $Body -Method "POST"
}

function Stop-OpenAIRun {
    <#
    .SYNOPSIS
    Cancels a run
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER RunId
    ID of the run to cancel
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$RunId
    )
    process {
        if ($PSCmdlet.ShouldProcess($RunId, 'Cancel OpenAI run')) {
            return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/runs/$RunId/cancel" -Method "POST"
        }
    }
}

function Submit-OpenAIToolOutput {
    <#
    .SYNOPSIS
    Submits tool output to continue a run
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER RunId
    ID of the run
    .PARAMETER ToolOutputs
    Array of tool outputs
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$RunId,
        [Parameter(Mandatory = $true)]
        [array]$ToolOutputs
    )
    
    $Body = @{
        tool_outputs = $ToolOutputs
    }
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/runs/$RunId/submit_tool_outputs" -Body $Body
}

function Get-OpenAIRunStepList {
    <#
    .SYNOPSIS
    Lists run steps
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER RunId
    ID of the run
    .PARAMETER Limit
    Number of steps to retrieve
    .PARAMETER Order
    Sort order
    .PARAMETER After
    Cursor for pagination
    .PARAMETER Before
    Cursor for pagination
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$RunId,
        [int]$Limit = 20,
        [string]$Order = "desc",
        [string]$After = $null,
        [string]$Before = $null
    )
    
    $QueryParams = @("limit=$Limit", "order=$Order")
    if ($After) { $QueryParams += "after=$After" }
    if ($Before) { $QueryParams += "before=$Before" }
    
    $Endpoint = "threads/$ThreadId/runs/$RunId/steps?" + ($QueryParams -join "&")
    return Invoke-OpenAIRequest -Endpoint $Endpoint -Method "GET"
}

function Get-OpenAIRunStep {
    <#
    .SYNOPSIS
    Gets a specific run step
    .PARAMETER ThreadId
    ID of the thread
    .PARAMETER RunId
    ID of the run
    .PARAMETER StepId
    ID of the step
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThreadId,
        [Parameter(Mandatory = $true)]
        [string]$RunId,
        [Parameter(Mandatory = $true)]
        [string]$StepId
    )
    
    return Invoke-OpenAIRequest -Endpoint "threads/$ThreadId/runs/$RunId/steps/$StepId" -Method "GET"
}
#endregion
