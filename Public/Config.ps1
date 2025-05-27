#region Configuration Functions

function Set-OpenAIKey {
    <#
    .SYNOPSIS
    Sets the OpenAI API key for authentication using SecureString
    .PARAMETER ApiKey
    Your OpenAI API key as a SecureString
    .PARAMETER Organization
    Optional organization ID
    .EXAMPLE
    $secureKey = Read-Host -AsSecureString -Prompt "Enter OpenAI API Key"
    Set-OpenAIKey -ApiKey $secureKey
    .EXAMPLE
    $secureKey = ConvertTo-SecureString "your-api-key" -AsPlainText -Force
    Set-OpenAIKey -ApiKey $secureKey -Organization "org-123"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [SecureString]$ApiKey,
        [string]$Organization = $null
    )
    
    $Global:OpenAIConfig.ApiKey = $ApiKey
    if ($Organization) {
        $Global:OpenAIConfig.Organization = $Organization
    }
    Write-Host "OpenAI API key configured successfully (stored as SecureString)" -ForegroundColor Green
}

function Get-OpenAIConfig {
    <#
    .SYNOPSIS
    Returns current OpenAI configuration
    #>
    return $Global:OpenAIConfig
}

function Set-OpenAIDefaults {
    <#
    .SYNOPSIS
    Sets default parameters for OpenAI requests with validation
    .PARAMETER Model
    Default model to use for chat completions
    .PARAMETER MaxTokens
    Default maximum tokens for completions
    .PARAMETER Temperature
    Default temperature setting for randomness
    .PARAMETER TimeoutSec
    Default timeout for HTTP requests
    .EXAMPLE
    Set-OpenAIDefaults -Model "gpt-4o" -MaxTokens 2000 -Temperature 0.5
    .EXAMPLE
    Set-OpenAIDefaults -Model "gpt-4o-mini"  # Use cheaper model as default
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("gpt-4o", "gpt-4o-mini", "gpt-4", "gpt-4-turbo", "gpt-3.5-turbo")]
        [string]$Model,
        
        [Parameter()]
        [ValidateRange(1, 4096)]
        [int]$MaxTokens,
        
        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,
        
        [Parameter()]
        [ValidateRange(30, 600)]
        [int]$TimeoutSec
    )
    
    $Changes = @()
    
    if ($PSBoundParameters.ContainsKey('Model')) { 
        $Global:OpenAIConfig.DefaultModel = $Model 
        $Changes += "Model: $Model"
    }
    if ($PSBoundParameters.ContainsKey('MaxTokens')) { 
        $Global:OpenAIConfig.MaxTokens = $MaxTokens 
        $Changes += "MaxTokens: $MaxTokens"
    }
    if ($PSBoundParameters.ContainsKey('Temperature')) { 
        $Global:OpenAIConfig.Temperature = $Temperature 
        $Changes += "Temperature: $Temperature"
    }
    if ($PSBoundParameters.ContainsKey('TimeoutSec')) { 
        $Global:OpenAIConfig.TimeoutSec = $TimeoutSec 
        $Changes += "TimeoutSec: $TimeoutSec"
    }
    
    if ($Changes.Count -gt 0) {
        Write-Host "OpenAI defaults updated: $($Changes -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "No changes specified. Current defaults:" -ForegroundColor Yellow
        Write-Host "  Model: $($Global:OpenAIConfig.DefaultModel)" -ForegroundColor Cyan
        Write-Host "  MaxTokens: $($Global:OpenAIConfig.MaxTokens)" -ForegroundColor Cyan
        Write-Host "  Temperature: $($Global:OpenAIConfig.Temperature)" -ForegroundColor Cyan
        Write-Host "  TimeoutSec: $($Global:OpenAIConfig.TimeoutSec)" -ForegroundColor Cyan
    }
}

#endregion
