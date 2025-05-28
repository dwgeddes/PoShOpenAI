# PoShOpenAI Assistant Vision Examples
# This script demonstrates how to use the PoShOpenAI module for both text and vision tasks with OpenAI Assistants

#Requires -Modules PSOpenAI

# Example 1: Create a Vision-Capable Assistant
Write-Host "🤖 Example 1: Creating a Vision-Capable Assistant" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

<#
# First, set your API key (uncomment and add your key)
Set-OpenAIKey "your-openai-api-key-here"

# Create a vision-capable assistant
$visionAssistant = New-VisionAssistant -Name "Image Analyzer" -Instructions @"
You are an expert image analyst. When users share images with you, provide detailed descriptions including:
- Main subjects and objects in the image
- Colors, lighting, and composition
- Mood or atmosphere
- Any text or writing visible
- Technical aspects if relevant (camera settings, etc.)
Be thorough but concise in your analysis.
"@

Write-Host "Assistant created with ID: $($visionAssistant.id)" -ForegroundColor Green
#>

# Example 2: Text-Only Assistant Interaction
Write-Host "`n💬 Example 2: Text-Only Assistant Interaction" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

$textExamples = @"
# Simple text query to an assistant
`$result = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "What is PowerShell?"

# Multiple questions in a pipeline
`$questions = @(
    "What are the benefits of PowerShell?",
    "How does PowerShell differ from Bash?",
    "What are PowerShell objects?"
)
`$results = `$questions | Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id"

# Continue a conversation with the same thread
`$result1 = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Tell me about PowerShell"
`$result2 = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Can you give me an example?" -ThreadId `$result1.ThreadId
"@

Write-Host $textExamples -ForegroundColor Gray

# Example 3: Vision Analysis Examples
Write-Host "`n👁️ Example 3: Vision Analysis with Images" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

$visionExamples = @"
# Analyze a single image
`$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "What do you see in this image?" -ImagePaths @("./photo.jpg")

# Analyze multiple images
`$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "Compare these images and tell me the differences" -ImagePaths @("./image1.jpg", "./image2.png")

# Specific analysis request
`$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "Analyze the composition and lighting in this photograph" -ImagePaths @("./photo.jpg")

# Text extraction from image
`$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "What text can you read in this image?" -ImagePaths @("./document.png")
"@

Write-Host $visionExamples -ForegroundColor Gray

# Example 4: Interactive Conversation
Write-Host "`n🗣️ Example 4: Interactive Assistant Conversation" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

$interactiveExample = @"
# Start an interactive conversation with a text assistant
Start-AssistantConversation -AssistantId "asst_your_assistant_id"

# Start an interactive conversation with custom instructions
Start-AssistantConversation -AssistantId "asst_your_vision_assistant_id" -Instructions "Be extra detailed in your image analysis"

# During the conversation, you can:
# - Type messages normally
# - Type 'exit' to end the conversation
# - Type 'clear' to start a new thread
# - Images can be referenced through file uploads (if assistant supports it)
"@

Write-Host $interactiveExample -ForegroundColor Gray

# Example 5: Advanced Usage with Response Analysis
Write-Host "`n📊 Example 5: Advanced Usage with Response Analysis" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

$advancedExample = @"
# Analyze response metadata
`$result = Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "Describe this image" -ImagePaths @("./photo.jpg")

# Check if the operation was successful
if (`$result.Success) {
    Write-Host "✅ Analysis completed successfully"
    Write-Host "Response: `$(`$result.Response)"
    Write-Host "Model used: `$(`$result.Model)"
    Write-Host "Processing time: `$(`$result.ProcessingTime)"
    Write-Host "Vision support: `$(`$result.SupportsVision)"
    Write-Host "Images processed: `$(`$result.ImageCount)"
    
    if (`$result.PromptTokens) {
        Write-Host "Tokens used - Prompt: `$(`$result.PromptTokens), Completion: `$(`$result.CompletionTokens), Total: `$(`$result.TotalTokens)"
    }
} else {
    Write-Host "❌ Analysis failed: `$(`$result.Error)"
}

# Batch processing multiple images
`$imageFiles = Get-ChildItem "*.jpg", "*.png" | Select-Object -First 5
`$results = `$imageFiles | ForEach-Object {
    Invoke-OpenAIAssistant -AssistantId "asst_your_vision_assistant_id" -Message "Briefly describe this image" -ImagePaths @(`$_.FullName)
}

# Analyze successful vs failed operations
`$successful = (`$results | Where-Object Success).Count
`$failed = (`$results | Where-Object { -not `$_.Success }).Count
Write-Host "Processed `$(`$imageFiles.Count) images: `$successful successful, `$failed failed"
"@

Write-Host $advancedExample -ForegroundColor Gray

# Example 6: Error Handling and Best Practices
Write-Host "`n🛡️ Example 6: Error Handling and Best Practices" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

$bestPracticesExample = @"
# Always check for API key configuration
if (-not `$Global:OpenAIConfig.ApiKey) {
    Write-Warning "Please configure your OpenAI API key first: Set-OpenAIKey 'your-key'"
    return
}

# Validate image files before processing
`$imagePaths = @("./image1.jpg", "./image2.png")
`$validImages = `$imagePaths | Where-Object { Test-Path `$_ -PathType Leaf }

if (`$validImages.Count -eq 0) {
    Write-Warning "No valid image files found"
    return
}

# Use try-catch for robust error handling
try {
    `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Analyze these images" -ImagePaths `$validImages -MaxWaitSeconds 120
    
    if (`$result.Success) {
        # Process successful result
        `$result.Response
    } else {
        Write-Warning "Assistant processing failed: `$(`$result.Error)"
    }
} catch {
    Write-Error "Unexpected error: `$(`$_.Exception.Message)"
}

# Use verbose output for debugging
`$result = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Test" -ImagePaths @("./test.jpg") -Verbose

# Monitor token usage for cost management
`$results = @()
1..10 | ForEach-Object {
    `$result = Invoke-OpenAIAssistant -AssistantId "asst_your_assistant_id" -Message "Quick analysis" -ImagePaths @("./image`$_.jpg")
    `$results += `$result
}

`$totalTokens = (`$results | Where-Object Success | Measure-Object -Property TotalTokens -Sum).Sum
Write-Host "Total tokens used: `$totalTokens"
"@

Write-Host $bestPracticesExample -ForegroundColor Gray

# Summary
Write-Host "`n✨ Summary: PoShOpenAI Vision Capabilities" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray

$summary = @"
The PoShOpenAI module provides comprehensive support for OpenAI Assistants with both text and vision capabilities:

📋 Key Features:
• Text-based assistant interactions
• Vision analysis with automatic image upload
• Support for multiple image formats (jpg, jpeg, png, gif, webp)
• Interactive conversation mode
• Comprehensive response metadata
• Automatic file cleanup
• Error handling and validation
• Token usage tracking

🎯 Use Cases:
• Image analysis and description
• Document text extraction
• Photo composition analysis
• Multi-image comparison
• Interactive AI conversations
• Batch image processing
• Educational content analysis

🚀 Getting Started:
1. Set-OpenAIKey "your-api-key"
2. `$assistant = New-VisionAssistant -Name "My Analyzer" -Instructions "..."
3. `$result = Invoke-OpenAIAssistant -AssistantId `$assistant.id -Message "Analyze this" -ImagePaths @("image.jpg")

Ready to use for production workloads! 🎉
"@

Write-Host $summary -ForegroundColor White
