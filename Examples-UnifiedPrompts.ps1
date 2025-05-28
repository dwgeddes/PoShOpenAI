# Examples for the Unified Prompt Functions in PoShOpenAI
# These examples demonstrate the simplified interfaces for common OpenAI operations

#region Prerequisites
Write-Host "=== PoShOpenAI Unified Prompt Examples ===" -ForegroundColor Green
Write-Host ""
Write-Host "Prerequisites:" -ForegroundColor Yellow
Write-Host "1. Set your OpenAI API key as an environment variable:"
Write-Host "   `$env:OPENAI_API_KEY = 'your-api-key-here'"
Write-Host "2. Or use: Set-OpenAIKey -ApiKey (ConvertTo-SecureString 'your-key' -AsPlainText -Force)"
Write-Host ""

# Check if API key is configured
if (-not $env:OPENAI_API_KEY -and -not $Global:OpenAIConfig.ApiKey) {
    Write-Host "❌ API key not found. Please set OPENAI_API_KEY environment variable." -ForegroundColor Red
    Write-Host "Example: `$env:OPENAI_API_KEY = 'sk-your-api-key-here'" -ForegroundColor Cyan
    exit 1
}
else {
    Write-Host "✅ API key found and ready to use." -ForegroundColor Green
}
#endregion

#region Basic Text Generation Examples
Write-Host "`n=== 1. Basic Text Generation ===" -ForegroundColor Cyan

Write-Host "`nExample 1.1: Simple question" -ForegroundColor Yellow
$response1 = Invoke-OpenAIPrompt -Prompt "What is the capital of France?"
Write-Host "Response: $($response1.choices[0].message.content)" -ForegroundColor White

Write-Host "`nExample 1.2: Creative writing with higher temperature" -ForegroundColor Yellow
$response2 = Invoke-OpenAIPrompt -Prompt "Write a short poem about autumn leaves" -Temperature 0.9
Write-Host "Response: $($response2.choices[0].message.content)" -ForegroundColor White

Write-Host "`nExample 1.3: Technical explanation with system message" -ForegroundColor Yellow
$response3 = Invoke-OpenAIPrompt -Prompt "Explain recursion" -SystemMessage "You are a computer science professor. Explain concepts clearly with examples."
Write-Host "Response: $($response3.choices[0].message.content)" -ForegroundColor White

Write-Host "`nExample 1.4: Using a different model" -ForegroundColor Yellow
$response4 = Invoke-OpenAIPrompt -Prompt "Summarize the theory of relativity in one sentence" -Model "gpt-4o"
Write-Host "Response: $($response4.choices[0].message.content)" -ForegroundColor White
#endregion

#region Image Generation Examples
Write-Host "`n=== 2. Image Generation ===" -ForegroundColor Cyan

Write-Host "`nExample 2.1: Basic image generation" -ForegroundColor Yellow
try {
    $image1 = Invoke-OpenAIPrompt -Prompt "A serene mountain landscape at sunset with a lake reflection" -ImageGen
    Write-Host "✅ Image generated successfully!" -ForegroundColor Green
    Write-Host "Image URL: $($image1.data[0].url)" -ForegroundColor White
    Write-Host "You can open this URL in a browser to view the image." -ForegroundColor Gray
}
catch {
    Write-Host "❌ Image generation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nExample 2.2: High-quality square image" -ForegroundColor Yellow
try {
    $image2 = Invoke-OpenAIPrompt -Prompt "A modern minimalist workspace with plants" -ImageGen -Quality "hd" -Size "1024x1024"
    Write-Host "✅ HD Image generated successfully!" -ForegroundColor Green
    Write-Host "Image URL: $($image2.data[0].url)" -ForegroundColor White
}
catch {
    Write-Host "❌ HD Image generation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nExample 2.3: Wide format image with natural style" -ForegroundColor Yellow
try {
    $image3 = Invoke-OpenAIPrompt -Prompt "A cat sitting by a window on a rainy day" -ImageGen -Size "1792x1024" -Style "natural"
    Write-Host "✅ Wide format image generated successfully!" -ForegroundColor Green
    Write-Host "Image URL: $($image3.data[0].url)" -ForegroundColor White
}
catch {
    Write-Host "❌ Wide format image generation failed: $($_.Exception.Message)" -ForegroundColor Red
}
#endregion

#region Vision Analysis Examples
Write-Host "`n=== 3. Vision Analysis ===" -ForegroundColor Cyan

# For vision examples, we'll create a simple test image if none exists
$TestImagePath = Join-Path $PWD "test-image.png"

if (-not (Test-Path $TestImagePath)) {
    Write-Host "`nℹ️  No test image found. Vision examples require an image file." -ForegroundColor Yellow
    Write-Host "Please place an image file at: $TestImagePath" -ForegroundColor Gray
    Write-Host "Supported formats: .jpg, .jpeg, .png, .gif, .bmp, .webp" -ForegroundColor Gray
    Write-Host "Skipping vision examples..." -ForegroundColor Yellow
}
else {
    Write-Host "`nExample 3.1: Basic image analysis" -ForegroundColor Yellow
    try {
        $vision1 = Invoke-OpenAIPrompt -Prompt "What do you see in this image?" -ImagePath $TestImagePath -VisionAnalysis
        Write-Host "✅ Vision analysis completed!" -ForegroundColor Green
        Write-Host "Response: $($vision1.choices[0].message.content)" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Vision analysis failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`nExample 3.2: Detailed image analysis" -ForegroundColor Yellow
    try {
        $vision2 = Invoke-OpenAIPrompt -Prompt "Describe this image in detail, including colors, objects, composition, and mood" -ImagePath $TestImagePath -VisionAnalysis -ImageDetail "high"
        Write-Host "✅ Detailed vision analysis completed!" -ForegroundColor Green
        Write-Host "Response: $($vision2.choices[0].message.content)" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Detailed vision analysis failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`nExample 3.3: Specific question about image" -ForegroundColor Yellow
    try {
        $vision3 = Invoke-OpenAIPrompt -Prompt "How many people are in this image and what are they doing?" -ImagePath $TestImagePath -VisionAnalysis -Model "gpt-4o"
        Write-Host "✅ Specific vision question completed!" -ForegroundColor Green
        Write-Host "Response: $($vision3.choices[0].message.content)" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Specific vision question failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}
#endregion

#region Assistant Prompt Examples
Write-Host "`n=== 4. Assistant Conversations ===" -ForegroundColor Cyan

Write-Host "`nExample 4.1: Simple assistant conversation" -ForegroundColor Yellow
try {
    $assistant1 = Invoke-OpenAIAssistantPrompt -Prompt "Hello! Can you help me understand machine learning?"
    Write-Host "✅ Assistant conversation completed!" -ForegroundColor Green
    Write-Host "Assistant ID: $($assistant1.AssistantId)" -ForegroundColor Gray
    Write-Host "Thread ID: $($assistant1.ThreadId)" -ForegroundColor Gray
    Write-Host "Response: $($assistant1.Response)" -ForegroundColor White
    
    # Continue the conversation
    Write-Host "`nExample 4.2: Continuing the conversation" -ForegroundColor Yellow
    $assistant2 = Invoke-OpenAIAssistantPrompt -Prompt "Can you give me a specific example?" -AssistantId $assistant1.AssistantId -ThreadId $assistant1.ThreadId
    Write-Host "✅ Conversation continued!" -ForegroundColor Green
    Write-Host "Response: $($assistant2.Response)" -ForegroundColor White
}
catch {
    Write-Host "❌ Assistant conversation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nExample 4.3: Specialized coding assistant" -ForegroundColor Yellow
try {
    $codingAssistant = Invoke-OpenAIAssistantPrompt -Prompt "Help me write a Python function to calculate fibonacci numbers" -AssistantName "Python Expert" -Instructions "You are an expert Python developer. Provide clean, well-commented code with explanations." -Tools @("code_interpreter")
    Write-Host "✅ Coding assistant conversation completed!" -ForegroundColor Green
    Write-Host "Response: $($codingAssistant.Response)" -ForegroundColor White
}
catch {
    Write-Host "❌ Coding assistant conversation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nExample 4.4: Math assistant with code interpreter" -ForegroundColor Yellow
try {
    $mathAssistant = Invoke-OpenAIAssistantPrompt -Prompt "Calculate the derivative of x^3 + 2x^2 - 5x + 1 and plot it" -AssistantName "Math Tutor" -Instructions "You are a mathematics tutor. Solve problems step by step and use code when helpful." -Tools @("code_interpreter") -Model "gpt-4o"
    Write-Host "✅ Math assistant conversation completed!" -ForegroundColor Green
    Write-Host "Response: $($mathAssistant.Response)" -ForegroundColor White
}
catch {
    Write-Host "❌ Math assistant conversation failed: $($_.Exception.Message)" -ForegroundColor Red
}
#endregion

#region Pipeline Examples
Write-Host "`n=== 5. Pipeline and Advanced Usage ===" -ForegroundColor Cyan

Write-Host "`nExample 5.1: Pipeline text processing" -ForegroundColor Yellow
try {
    $topics = @("artificial intelligence", "quantum computing", "blockchain technology")
    $summaries = $topics | ForEach-Object {
        $result = Invoke-OpenAIPrompt -Prompt "Write a one-paragraph summary of $_" -MaxTokens 150
        [PSCustomObject]@{
            Topic = $_
            Summary = $result.choices[0].message.content
            Tokens = $result.usage.total_tokens
        }
    }
    
    Write-Host "✅ Pipeline processing completed!" -ForegroundColor Green
    $summaries | Format-Table -Wrap
}
catch {
    Write-Host "❌ Pipeline processing failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nExample 5.2: Multi-step analysis workflow" -ForegroundColor Yellow
try {
    # Step 1: Generate a creative story
    $story = Invoke-OpenAIPrompt -Prompt "Write a short science fiction story about time travel" -MaxTokens 300 -Temperature 0.8
    Write-Host "✅ Story generated!" -ForegroundColor Green
    
    # Step 2: Analyze the story
    $analysis = Invoke-OpenAIPrompt -Prompt "Analyze the following story for its themes, writing style, and literary devices: `n`n$($story.choices[0].message.content)" -SystemMessage "You are a literature professor analyzing creative writing."
    Write-Host "✅ Story analyzed!" -ForegroundColor Green
    Write-Host "Analysis: $($analysis.choices[0].message.content)" -ForegroundColor White
}
catch {
    Write-Host "❌ Multi-step workflow failed: $($_.Exception.Message)" -ForegroundColor Red
}
#endregion

#region Error Handling Examples
Write-Host "`n=== 6. Error Handling and Edge Cases ===" -ForegroundColor Cyan

Write-Host "`nExample 6.1: Handling invalid image paths" -ForegroundColor Yellow
try {
    $invalidVision = Invoke-OpenAIPrompt -Prompt "What's in this image?" -ImagePath "nonexistent.jpg" -VisionAnalysis
}
catch {
    Write-Host "✅ Error properly caught: $($_.Exception.Message)" -ForegroundColor Green
}

Write-Host "`nExample 6.2: Handling model limitations" -ForegroundColor Yellow
try {
    # Try to use vision with a text-only model
    $limitationTest = Invoke-OpenAIPrompt -Prompt "Analyze this image" -ImagePath $TestImagePath -VisionAnalysis -Model "gpt-3.5-turbo"
}
catch {
    Write-Host "✅ Model limitation properly handled: $($_.Exception.Message)" -ForegroundColor Green
}
#endregion

#region Configuration Examples
Write-Host "`n=== 7. Configuration and Defaults ===" -ForegroundColor Cyan

Write-Host "`nExample 7.1: Current configuration" -ForegroundColor Yellow
$config = Get-OpenAIConfig
Write-Host "Current defaults:" -ForegroundColor White
Write-Host "  Model: $($config.DefaultModel)" -ForegroundColor Gray
Write-Host "  Max Tokens: $($config.MaxTokens)" -ForegroundColor Gray
Write-Host "  Temperature: $($config.Temperature)" -ForegroundColor Gray
Write-Host "  Timeout: $($config.TimeoutSec) seconds" -ForegroundColor Gray

Write-Host "`nExample 7.2: Updating defaults" -ForegroundColor Yellow
Set-OpenAIDefaults -Model "gpt-4o" -Temperature 0.5 -MaxTokens 1500
Write-Host "✅ Defaults updated!" -ForegroundColor Green

# Test with new defaults
$testDefault = Invoke-OpenAIPrompt -Prompt "Test message with new defaults"
Write-Host "Response with new defaults: $($testDefault.choices[0].message.content)" -ForegroundColor White

# Reset to balanced defaults
Set-OpenAIDefaults -Model "gpt-4o-mini" -Temperature 0.7 -MaxTokens 1000
Write-Host "✅ Defaults reset to balanced settings!" -ForegroundColor Green
#endregion

Write-Host "`n=== Examples Complete! ===" -ForegroundColor Green
Write-Host "All unified prompt examples have been demonstrated." -ForegroundColor White
Write-Host "Key advantages of the unified interface:" -ForegroundColor Yellow
Write-Host "• Single function for text, image generation, and vision" -ForegroundColor Gray
Write-Host "• Automatic environment variable loading" -ForegroundColor Gray
Write-Host "• Simplified assistant conversations" -ForegroundColor Gray
Write-Host "• Consistent parameter names and behavior" -ForegroundColor Gray
Write-Host "• Built-in error handling and validation" -ForegroundColor Gray
Write-Host "`nFor more information, use Get-Help Invoke-OpenAIPrompt -Full" -ForegroundColor Cyan
