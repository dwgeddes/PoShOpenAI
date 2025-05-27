# PSOpenAI.psm1
# Main module file that imports all public and private functions

# Dot-source all Public functions
Get-ChildItem -Path $PSScriptRoot/Public/*.ps1 | ForEach-Object {
    . $_.FullName
}

# Dot-source all Private functions
Get-ChildItem -Path $PSScriptRoot/Private/*.ps1 | ForEach-Object {
    . $_.FullName
}
