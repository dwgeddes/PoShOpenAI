# PoShOpenAI

**PoShOpenAI** is a PowerShell module for interacting with OpenAI APIs, including GPT, DALL-E, Whisper, Assistants, Vision, and more. It provides a unified, user-friendly interface for chat, image, audio, embeddings, moderation, and assistant workflows.

---

## Features

- Unified prompt interface (`Invoke-OpenAIPrompt`) for chat, image, audio, embeddings, moderation, and vision
- Assistant and Vision support (including image analysis and interactive conversations)
- Batch and parallel processing for large workloads
- Secure API key management (SecureString and environment variable support)
- Cost tracking and analytics
- Comprehensive error handling and best practices
- Utility functions for formatting and saving responses

---

## Quick Start

1. **Install the module** (from source or PowerShell Gallery, if available):

   ```powershell
   # From source
   Import-Module ./PoShOpenAI.psd1

   # Or (when published)
   Install-Module PoShOpenAI
   ```

2. **Configure your OpenAI API key**:

   ```powershell
   # Recommended: Use environment variable
   $env:OPENAI_API_KEY = 'sk-your-api-key-here'

   # Or use SecureString
   Set-OpenAIKey -ApiKey (Read-Host -AsSecureString -Prompt "API Key")
   ```

3. **Test your connection**:

   ```powershell
   Test-OpenAIConnection
   ```

4. **Try a simple chat**:

   ```powershell
   Send-ChatMessage -Message "What is PowerShell?"
   ```

---

## Examples

### Unified Prompt

```powershell
# Simple chat
Invoke-OpenAIPrompt -Prompt "Explain PowerShell in simple terms"

# Image generation
Invoke-OpenAIPrompt -Prompt "A sunset over mountains" -Type Image -Quality hd

# Vision analysis (image understanding)
Invoke-OpenAIPrompt -Prompt "What do you see in this image?" -ImagePaths @("photo.jpg")

# Content moderation
Invoke-OpenAIPrompt -Prompt "Check this content for policy violations" -Type Moderation
```

### Assistant & Vision

```powershell
# Create a vision-capable assistant
$assistant = New-VisionAssistant -Name "Image Analyzer" -Instructions "You are an expert at analyzing images."

# Analyze an image
$result = Invoke-OpenAIAssistant -AssistantId $assistant.id -Message "Describe this image" -ImagePaths @("photo.jpg")

# Start an interactive conversation
Start-AssistantConversation -AssistantId $assistant.id
```

### Batch & Parallel

```powershell
# Batch process multiple questions
Get-Content "questions.txt" | Send-ChatMessage -Model "gpt-4o-mini"

# Parallel processing for speed
Get-Content "questions.txt" | Invoke-OpenAIParallelChat -ThrottleLimit 3
```

---

## Best Practices

- Always check API key configuration before making requests.
- Validate image/audio files before processing.
- Use try/catch for robust error handling.
- Monitor token usage and costs for budget control.
- Use SecureString or environment variables for API keys.
- Leverage batching and parallelism for large workloads.

---

## Documentation

- For full usage examples, run:  
  ```powershell
  Show-OpenAIExample
  ```
- For detailed help on any function:  
  ```powershell
  Get-Help <FunctionName> -Full
  ```

---

## License

MIT License.  
See [LICENSE](LICENSE) for details.

---

## Links

- [OpenAI API Documentation](https://platform.openai.com/docs/)
- [PowerShell Gallery (when available)](https://www.powershellgallery.com/packages/PoShOpenAI)
- [Project Issues](https://github.com/your-repo/PSOpenAI/issues)

---
