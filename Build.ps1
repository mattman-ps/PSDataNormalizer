#Requires -Version 5.1

<#
.SYNOPSIS
    Build script for the PSDataNormalizer PowerShell module.

.DESCRIPTION
    This script provides build automation for the PSDataNormalizer module including:
    - Running Pester tests
    - Code analysis with PSScriptAnalyzer
    - Building documentation
    - Creating module packages

.PARAMETER Task
    The build task to execute. Valid values: Test, Analyze, Documentation, Package, All

.PARAMETER Configuration
    The build configuration. Valid values: Debug, Release

.EXAMPLE
    .\Build.ps1 -Task Test

.EXAMPLE
    .\Build.ps1 -Task All -Configuration Release
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Test', 'Analyze', 'Documentation', 'Package', 'All')]
    [string]$Task = 'Test',

    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug'
)

# Build configuration
$BuildConfig = @{
    ModuleName = 'PSDataNormalizer'
    ModuleRoot = $PSScriptRoot
    OutputPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tests\TestResults'
    TestsPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tests'
    DocsPath = Join-Path -Path $PSScriptRoot -ChildPath 'Docs'
}

# Ensure output directory exists
if (-not (Test-Path -Path $BuildConfig.OutputPath)) {
    New-Item -Path $BuildConfig.OutputPath -ItemType Directory -Force | Out-Null
}

function Invoke-TestTask {
    Write-Host "Running Pester tests..." -ForegroundColor Green

    # Check if Pester is available
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Pester module not found. Installing..."
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }

    # Import Pester
    Import-Module -Name Pester -Force

    # Configure Pester
    $PesterConfig = New-PesterConfiguration
    $PesterConfig.Run.Path = $BuildConfig.TestsPath
    $PesterConfig.Output.Verbosity = 'Detailed'
    $PesterConfig.CodeCoverage.Enabled = $true
    $PesterConfig.CodeCoverage.Path = Join-Path -Path $BuildConfig.ModuleRoot -ChildPath "*.psm1"
    $PesterConfig.CodeCoverage.OutputPath = Join-Path -Path $BuildConfig.OutputPath -ChildPath 'CodeCoverage.xml'
    $PesterConfig.TestResult.Enabled = $true
    $PesterConfig.TestResult.OutputPath = Join-Path -Path $BuildConfig.OutputPath -ChildPath 'TestResults.xml'

    # Run tests
    $TestResults = Invoke-Pester -Configuration $PesterConfig

    if ($TestResults.Failed.Count -gt 0) {
        throw "One or more tests failed. Check the test results for details."
    }

    Write-Host "All tests passed!" -ForegroundColor Green
}

function Invoke-AnalyzeTask {
    Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Green

    # Check if PSScriptAnalyzer is available
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-Warning "PSScriptAnalyzer module not found. Installing..."
        Install-Module -Name PSScriptAnalyzer -Force
    }

    # Import PSScriptAnalyzer
    Import-Module -Name PSScriptAnalyzer -Force

    # Analyze the module
    $AnalysisResults = Invoke-ScriptAnalyzer -Path $BuildConfig.ModuleRoot -Recurse -ReportSummary

    # Filter out informational messages for cleaner output
    $Issues = $AnalysisResults | Where-Object { $_.Severity -ne 'Information' }

    if ($Issues.Count -gt 0) {
        Write-Host "PSScriptAnalyzer found the following issues:" -ForegroundColor Yellow
        $Issues | Format-Table -Property Severity, RuleName, ScriptName, Line, Message -AutoSize

        # Only fail on Error severity issues
        $Errors = $Issues | Where-Object { $_.Severity -eq 'Error' }
        if ($Errors.Count -gt 0) {
            throw "PSScriptAnalyzer found $($Errors.Count) error(s). Please fix these issues before continuing."
        }
    } else {
        Write-Host "No issues found by PSScriptAnalyzer!" -ForegroundColor Green
    }

    # Save analysis results
    $AnalysisResults | Export-Csv -Path (Join-Path -Path $BuildConfig.OutputPath -ChildPath 'AnalysisResults.csv') -NoTypeInformation
}

function Invoke-DocumentationTask {
    Write-Host "Generating documentation..." -ForegroundColor Green

    # Check if platyPS is available
    if (-not (Get-Module -Name platyPS -ListAvailable)) {
        Write-Warning "platyPS module not found. Installing..."
        Install-Module -Name platyPS -Force
    }

    # Import platyPS and the module
    Import-Module -Name platyPS -Force
    Import-Module -Path (Join-Path -Path $BuildConfig.ModuleRoot -ChildPath "$($BuildConfig.ModuleName).psd1") -Force

    # Create docs directory if it doesn't exist
    if (-not (Test-Path -Path $BuildConfig.DocsPath)) {
        New-Item -Path $BuildConfig.DocsPath -ItemType Directory -Force | Out-Null
    }

    # Generate markdown help files
    try {
        New-MarkdownHelp -Module $BuildConfig.ModuleName -OutputFolder $BuildConfig.DocsPath -Force
        Write-Host "Documentation generated successfully!" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to generate documentation: $($_.Exception.Message)"
    }
}

function Invoke-PackageTask {
    Write-Host "Creating module package..." -ForegroundColor Green

    $PackageRoot = Join-Path -Path $BuildConfig.OutputPath -ChildPath $BuildConfig.ModuleName

    # Clean existing package directory
    if (Test-Path -Path $PackageRoot) {
        Remove-Item -Path $PackageRoot -Recurse -Force
    }

    # Create package directory
    New-Item -Path $PackageRoot -ItemType Directory -Force | Out-Null

    # Copy module files
    $FilesToCopy = @(
        "$($BuildConfig.ModuleName).psd1",
        "$($BuildConfig.ModuleName).psm1",
        'Public',
        'Private',
        'Data',
        'README.md'
    )

    foreach ($File in $FilesToCopy) {
        $SourcePath = Join-Path -Path $BuildConfig.ModuleRoot -ChildPath $File
        if (Test-Path -Path $SourcePath) {
            Copy-Item -Path $SourcePath -Destination $PackageRoot -Recurse -Force
        }
    }

    Write-Host "Module package created at: $PackageRoot" -ForegroundColor Green
}

# Main execution
try {
    Write-Host "Starting build process for $($BuildConfig.ModuleName) module..." -ForegroundColor Cyan
    Write-Host "Task: $Task, Configuration: $Configuration" -ForegroundColor Cyan

    switch ($Task) {
        'Test' { Invoke-TestTask }
        'Analyze' { Invoke-AnalyzeTask }
        'Documentation' { Invoke-DocumentationTask }
        'Package' { Invoke-PackageTask }
        'All' {
            Invoke-TestTask
            Invoke-AnalyzeTask
            Invoke-DocumentationTask
            Invoke-PackageTask
        }
    }

    Write-Host "Build completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Build failed: $($_.Exception.Message)"
    exit 1
}
