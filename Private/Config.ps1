# Global variables for configuration - balanced defaults between quality and cost
# Initialize configuration with environment variable defaults
$Global:OpenAIConfig = @{
    ApiKey = $null
    BaseUrl = "https://api.openai.com/v1"
    Organization = $null
    DefaultModel = "gpt-4o-mini"  # Best balance of quality and cost
    MaxTokens = 1000  # More cost-effective default
    Temperature = 0.7
    TimeoutSec = 300
}

# Auto-load API key from environment variable if available
if ($env:OPENAI_API_KEY -and -not $Global:OpenAIConfig.ApiKey) {
    try {
        $Global:OpenAIConfig.ApiKey = ConvertTo-SecureString $env:OPENAI_API_KEY -AsPlainText -Force
        Write-Verbose "OpenAI API key loaded from OPENAI_API_KEY environment variable"
    }
    catch {
        Write-Warning "Failed to load API key from environment variable: $($_.Exception.Message)"
    }
}

# Auto-load organization from environment variable if available
if ($env:OPENAI_ORGANIZATION -and -not $Global:OpenAIConfig.Organization) {
    $Global:OpenAIConfig.Organization = $env:OPENAI_ORGANIZATION
    Write-Verbose "OpenAI organization loaded from OPENAI_ORGANIZATION environment variable"
}

function Set-OpenAIKey {
    <#
    .SYNOPSIS
    Sets the OpenAI API key for authentication using SecureString
    .DESCRIPTION
    Configures the OpenAI API key for the current session. The key is stored as a SecureString
    for enhanced security. Alternatively, you can set the OPENAI_API_KEY environment variable.
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
    .EXAMPLE
    # Alternative: Set environment variable
    $env:OPENAI_API_KEY = "your-api-key-here"
    .NOTES
    Environment variables take precedence and are automatically loaded when the module is imported.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [SecureString]$ApiKey,
        [string]$Organization = $null
    )
    
    $Global:OpenAIConfig.ApiKey = $ApiKey
    if ($Organization) {
        $Global:OpenAIConfig.Organization = $Organization
    }
    Write-Host "✅ OpenAI API key configured successfully (stored as SecureString)" -ForegroundColor Green
    
    # Test the connection
    try {
        Test-OpenAIConnection -Quiet
        Write-Host "✅ API key validated successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "API key set but validation failed: $($_.Exception.Message)"
        Write-Host "💡 You can still use the module, but please verify your API key is correct." -ForegroundColor Yellow
    }
}

function Get-OpenAIConfig {
    <#
    .SYNOPSIS
    Returns current OpenAI configuration
    .DESCRIPTION
    Displays the current configuration settings including API key status,
    default model, and other parameters. API key is masked for security.
    .EXAMPLE
    Get-OpenAIConfig
    .EXAMPLE
    $config = Get-OpenAIConfig
    Write-Host "Using model: $($config.DefaultModel)"
    #>
    
    $config = $Global:OpenAIConfig.Clone()
    
    # Mask the API key for security
    if ($config.ApiKey) {
        $config.ApiKeyStatus = "✅ Configured"
    }
    elseif ($env:OPENAI_API_KEY) {
        $config.ApiKeyStatus = "✅ From Environment Variable"
    }
    else {
        $config.ApiKeyStatus = "❌ Not Configured"
    }
    
    # Remove the actual API key from display
    $config.Remove('ApiKey')
    
    return $config
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

function Initialize-OpenAIConfig {
    <#
    .SYNOPSIS
    Ensures OpenAI API key is configured with user-friendly guidance
    .DESCRIPTION
    Checks if an API key is available and provides helpful guidance if not.
    This function is called automatically by unified prompt functions.
    .PARAMETER Quiet
    Suppress informational messages
    .EXAMPLE
    Initialize-OpenAIConfig
    .EXAMPLE
    Initialize-OpenAIConfig -Quiet
    #>
    [CmdletBinding()]
    param(
        [switch]$Quiet
    )
    
    # Check if API key is already configured
    if ($Global:OpenAIConfig.ApiKey) {
        if (-not $Quiet) {
            Write-Verbose "API key already configured"
        }
        return $true
    }
    
    # Try to load from environment variable
    if ($env:OPENAI_API_KEY) {
        try {
            $Global:OpenAIConfig.ApiKey = ConvertTo-SecureString $env:OPENAI_API_KEY -AsPlainText -Force
            if (-not $Quiet) {
                Write-Host "✅ API key loaded from OPENAI_API_KEY environment variable" -ForegroundColor Green
            }
            return $true
        }
        catch {
            Write-Warning "Failed to load API key from environment variable: $($_.Exception.Message)"
        }
    }
    
    # API key not found - provide helpful guidance
    if (-not $Quiet) {
        Write-Host "❌ OpenAI API key not configured" -ForegroundColor Red
        Write-Host ""
        Write-Host "To configure your API key, choose one of these options:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Option 1 - Environment Variable (Recommended):" -ForegroundColor Cyan
        Write-Host "  `$env:OPENAI_API_KEY = 'your-api-key-here'" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 2 - PowerShell Function:" -ForegroundColor Cyan
        Write-Host "  `$key = ConvertTo-SecureString 'your-api-key' -AsPlainText -Force" -ForegroundColor White
        Write-Host "  Set-OpenAIKey -ApiKey `$key" -ForegroundColor White
        Write-Host ""
        Write-Host "Get your API key from: https://platform.openai.com/api-keys" -ForegroundColor Gray
    }
    
    return $false
}

function Write-OpenAIError {
    <#
    .SYNOPSIS
    Standardized error writing for the module
    .PARAMETER Message
    Error message to display
    .PARAMETER Exception
    Original exception if available
    .PARAMETER Category
    Error category
    .PARAMETER ErrorId
    Unique error identifier
    .PARAMETER TargetObject
    Object that caused the error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [System.Exception]$Exception = $null,
        
        [Parameter()]
        [System.Management.Automation.ErrorCategory]$Category = [System.Management.Automation.ErrorCategory]::NotSpecified,
        
        [Parameter()]
        [string]$ErrorId = "OpenAIError",
        
        [Parameter()]
        [object]$TargetObject = $null
    )
    
    if ($Exception) {
        $ErrorRecord = New-Object System.Management.Automation.ErrorRecord(
            $Exception,
            $ErrorId,
            $Category,
            $TargetObject
        )
        $PSCmdlet.WriteError($ErrorRecord)
    } else {
        $ErrorRecord = New-Object System.Management.Automation.ErrorRecord(
            (New-Object System.Exception($Message)),
            $ErrorId,
            $Category,
            $TargetObject
        )
        $PSCmdlet.WriteError($ErrorRecord)
    }
}

function Test-OpenAIApiKey {
    <#
    .SYNOPSIS
    Tests if API key is configured and valid
    .PARAMETER Quiet
    Suppress output messages
    #>
    [CmdletBinding()]
    param([switch]$Quiet)
    
    if (-not $Global:OpenAIConfig.ApiKey) {
        if (-not $Quiet) {
            Write-Host "❌ No API key configured" -ForegroundColor Red
        }
        return $false
    }
    
    try {
        $Models = Invoke-OpenAIRequest -Endpoint "models" -Method "GET"
        if ($Models.data.Count -gt 0) {
            if (-not $Quiet) {
                Write-Host "✅ OpenAI API connection successful" -ForegroundColor Green
            }
            return $true
        }
        else {
            if (-not $Quiet) {
                Write-Host "❌ API returned no models" -ForegroundColor Red
            }
            return $false
        }
    }
    catch {
        if (-not $Quiet) {
            Write-Host "❌ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}
