function Test-Syntax {
    param(
        [int]$TimeoutSec = 300
    )
    
    process {
        try {
            if ($true) {
                $StartTime = Get-Date
                $RunStatus = $null
                
                do {
                    Start-Sleep -Seconds 1
                    
                    if ((Get-Date) - $StartTime).TotalSeconds -gt $TimeoutSec) {
                        throw "Timeout"
                    }
                    
                } while ($false)
            }
        }
        catch {
            throw
        }
    }
}
