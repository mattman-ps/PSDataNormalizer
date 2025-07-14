# PSDataNormalizer PowerShell Module
# A comprehensive module for normalizing various data elements

# Get the module root path
$ModuleRoot = $PSScriptRoot

# Import configuration data
$ConfigurationPath = Join-Path -Path $ModuleRoot -ChildPath 'Data\Configuration.psd1'
if (Test-Path -Path $ConfigurationPath) {
    $script:ModuleConfiguration = Import-PowerShellDataFile -Path $ConfigurationPath
} else {
    Write-Warning "Configuration file not found at: $ConfigurationPath"
    $script:ModuleConfiguration = @{}
}

# Import all private functions
$PrivateFunctions = Get-ChildItem -Path (Join-Path -Path $ModuleRoot -ChildPath 'Private') -Filter '*.ps1' -Recurse
foreach ($Function in $PrivateFunctions) {
    Write-Verbose "Importing private function: $($Function.Name)"
    . $Function.FullName
}

# Import all public functions
$PublicFunctions = Get-ChildItem -Path (Join-Path -Path $ModuleRoot -ChildPath 'Public') -Filter '*.ps1' -Recurse
foreach ($Function in $PublicFunctions) {
    Write-Verbose "Importing public function: $($Function.Name)"
    . $Function.FullName
}

# Export only the public functions
$FunctionsToExport = $PublicFunctions | ForEach-Object {
    [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
}

Export-ModuleMember -Function $FunctionsToExport

# Module cleanup
$ExecutionContext.SessionState.Module.OnRemove = {
    # Clean up any module-level variables
    Remove-Variable -Name ModuleConfiguration -Scope Script -ErrorAction SilentlyContinue
}
