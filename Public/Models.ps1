#region Basic Model Functions
function Get-OpenAIModelList {
    <#
    .SYNOPSIS
    Lists available OpenAI models from the API
    .EXAMPLE
    Get-OpenAIModelList
    .EXAMPLE
    Get-OpenAIModelList | Where-Object id -like "*gpt-4*"
    #>
    [CmdletBinding()]
    param()
    
    $Response = Invoke-OpenAIRequest -Endpoint "models" -Method "GET"
    return $Response.data | Sort-Object id
}

function Get-OpenAIModel {
    <#
    .SYNOPSIS
    Gets details about a specific model from the API
    .PARAMETER ModelId
    ID of the model to retrieve
    .EXAMPLE
    Get-OpenAIModel -ModelId "gpt-4o"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModelId
    )
    
    return Invoke-OpenAIRequest -Endpoint "models/$ModelId" -Method "GET"
}
#endregion
