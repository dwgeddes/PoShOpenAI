# Global variables for configuration - balanced defaults between quality and cost
$Global:OpenAIConfig = @{
    ApiKey = $null
    BaseUrl = "https://api.openai.com/v1"
    Organization = $null
    DefaultModel = "gpt-4o-mini"  # Best balance of quality and cost
    MaxTokens = 1000  # More cost-effective default
    Temperature = 0.7
    TimeoutSec = 300
}
