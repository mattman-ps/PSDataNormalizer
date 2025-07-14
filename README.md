# PSDataNormalizer

A PowerShell module for normalizing various data elements: company names, websites, phone numbers, and addresses for deduplication and standardization purposes.

## 🚀 Quick Start

```powershell
# Import the module
Import-Module .\PSDataNormalizer.psd1

# Normalize a company name
ConvertTo-NormalizedCompanyName -CompanyName "Microsoft Corporation"
# Returns: "microsoft"

# Normalize a website
ConvertTo-NormalizedWebsite -Website "https://www.google.com/"
# Returns: "google.com"

# Normalize a phone number
ConvertTo-NormalizedPhoneNumber -PhoneNumber "+1 (555) 123-4567"
# Returns: "5551234567"

# Normalize an address
ConvertTo-NormalizedAddress -Address "123 Main Street, Suite 5"
# Returns: "123 main"
```

## 📦 Available Functions

### Public Functions

- `ConvertTo-NormalizedCompanyName` - Normalize company names
- `ConvertTo-NormalizedWebsite` - Normalize website URLs
- `ConvertTo-NormalizedPhoneNumber` - Normalize phone numbers
- `ConvertTo-NormalizedAddress` - Normalize addresses
- `ConvertTo-NormalizedData` - Unified normalization with auto-detection
- `ConvertTo-ValidatedAddress` - Validate addresses using geocoding API
- `Test-NormalizedData` - Test and validate normalization results

## 📚 Detailed Function Examples

### ConvertTo-NormalizedCompanyName

Standardizes company names by removing legal suffixes, punctuation, and filler words.

```powershell
# Basic usage
ConvertTo-NormalizedCompanyName -CompanyName "Microsoft Corporation"
# Returns: "microsoft"

# Preserve original casing
ConvertTo-NormalizedCompanyName -CompanyName "Apple Inc." -PreserveCasing
# Returns: "Apple"

# Remove filler words
ConvertTo-NormalizedCompanyName -CompanyName "The Google LLC" -RemoveFillerWords
# Returns: "google"

# Combined options
ConvertTo-NormalizedCompanyName -CompanyName "The Amazon.com, Inc." -PreserveCasing -RemoveFillerWords
# Returns: "Amazon"

# Pipeline support
@("Microsoft Corp", "Apple Inc.", "Google LLC") | ConvertTo-NormalizedCompanyName
# Returns: "microsoft", "apple", "google"
```

### ConvertTo-NormalizedWebsite

Normalizes website URLs by removing protocols, www prefixes, and standardizing format.

```powershell
# Basic usage
ConvertTo-NormalizedWebsite -Website "https://www.microsoft.com/"
# Returns: "microsoft.com"

# Keep subdomains
ConvertTo-NormalizedWebsite -Website "https://support.google.com" -KeepSubdomains
# Returns: "support.google.com"

# Ignore paths
ConvertTo-NormalizedWebsite -Website "https://www.github.com/users/login" -IgnorePaths
# Returns: "github.com"

# Combined options
ConvertTo-NormalizedWebsite -Website "http://api.example.com/v1/data" -KeepSubdomains -IgnorePaths
# Returns: "api.example.com"

# Handle various formats
@("HTTPS://WWW.APPLE.COM", "http://facebook.com/", "www.twitter.com") | ConvertTo-NormalizedWebsite
# Returns: "apple.com", "facebook.com", "twitter.com"
```

### ConvertTo-NormalizedPhoneNumber

Normalizes phone numbers by removing formatting and country codes.

```powershell
# Basic usage (US/Canada)
ConvertTo-NormalizedPhoneNumber -PhoneNumber "+1 (555) 123-4567"
# Returns: "5551234567"

# Standard formatting
ConvertTo-NormalizedPhoneNumber -PhoneNumber "1-555-123-4567" -Format Standard
# Returns: "555-123-4567"

# Dotted formatting
ConvertTo-NormalizedPhoneNumber -PhoneNumber "(555) 123.4567" -Format Dotted
# Returns: "555.123.4567"

# Different country codes
ConvertTo-NormalizedPhoneNumber -PhoneNumber "+44 20 7946 0958" -CountryCode "44"
# Returns: "2079460958"

# Batch processing
$phoneNumbers = @("(555) 123-4567", "555.123.4568", "+1-555-123-4569")
$phoneNumbers | ConvertTo-NormalizedPhoneNumber -Format Standard
# Returns: "555-123-4567", "555-123-4568", "555-123-4569"
```

### ConvertTo-NormalizedAddress

Normalizes addresses by removing office numbers, standardizing suffixes and directions.

```powershell
# Basic usage
ConvertTo-NormalizedAddress -Address "123 Main Street, Suite 5"
# Returns: "123 main"

# Preserve casing
ConvertTo-NormalizedAddress -Address "456 Oak Avenue" -PreserveCasing
# Returns: "456 Oak"

# Keep street suffixes
ConvertTo-NormalizedAddress -Address "789 Broadway Blvd." -KeepStreetSuffixes
# Returns: "789 broadway blvd"

# Standardize directions
ConvertTo-NormalizedAddress -Address "100 First St Northeast, Apt 2B" -StandardizeDirections
# Returns: "100 first st ne"

# Combined options
ConvertTo-NormalizedAddress -Address "200 Second Avenue North, Floor 3" -PreserveCasing -KeepStreetSuffixes -StandardizeDirections
# Returns: "200 Second Avenue N"

# Remove various office formats
$addresses = @("123 Main St #5", "456 Oak Ave Suite 10", "789 Pine Rd Unit 2A")
$addresses | ConvertTo-NormalizedAddress
# Returns: "123 main st", "456 oak ave", "789 pine rd"
```

### ConvertTo-NormalizedData

Unified normalization function with automatic data type detection.

```powershell
# Auto-detect company name
ConvertTo-NormalizedData -Data "Microsoft Corporation" -DataType Auto
# Returns: "microsoft"

# Auto-detect website
ConvertTo-NormalizedData -Data "https://www.google.com" -DataType Auto
# Returns: "google.com"

# Auto-detect phone number
ConvertTo-NormalizedData -Data "+1 (555) 123-4567" -DataType Auto
# Returns: "5551234567"

# Auto-detect address
ConvertTo-NormalizedData -Data "123 Main Street" -DataType Auto
# Returns: "123 main"

# Explicit data type with options
$options = @{ Format = 'Standard' }
ConvertTo-NormalizedData -Data "(555) 123-4567" -DataType PhoneNumber -Options $options
# Returns: "555-123-4567"

# Batch processing with mixed data types
$mixedData = @("Apple Inc.", "https://microsoft.com", "(555) 123-4567", "123 Oak St")
$mixedData | ForEach-Object { ConvertTo-NormalizedData -Data $_ -DataType Auto }
# Returns: "apple", "microsoft.com", "5551234567", "123 oak st"
```

### ConvertTo-ValidatedAddress

Validates and standardizes addresses using online geocoding services.

```powershell
# Basic validation
ConvertTo-ValidatedAddress -Address "123 Main St, New York, NY"
# Returns: "123 Main Street, New York, NY 10001, United States"

# With fallback to local normalization
ConvertTo-ValidatedAddress -Address "1600 Pennsylvania Ave" -FallbackToLocal
# Returns validated address or local normalization if API fails

# Custom retry settings
ConvertTo-ValidatedAddress -Address "456 Oak Ave, Seattle, WA" -RetryCount 1 -DelaySeconds 5
# Returns validated address with custom retry logic

# Batch validation (with rate limiting)
$addresses = @("123 Main St, Boston, MA", "456 Oak Ave, Portland, OR")
foreach ($addr in $addresses) {
    ConvertTo-ValidatedAddress -Address $addr -FallbackToLocal
    Start-Sleep -Seconds 2  # Respect rate limits
}
```

### Test-NormalizedData

Tests and validates normalization results for quality assurance.

```powershell
# Define test cases
$testData = @(
    @{ Input = "Microsoft Corp."; Expected = "microsoft"; DataType = "CompanyName" },
    @{ Input = "https://www.google.com/"; Expected = "google.com"; DataType = "Website" },
    @{ Input = "+1 (555) 123-4567"; Expected = "5551234567"; DataType = "PhoneNumber" },
    @{ Input = "123 Main Street, Suite 5"; Expected = "123 main"; DataType = "Address" }
)

# Run tests with detailed output
$results = Test-NormalizedData -TestData $testData -ShowDetails
# Shows: [PASS] CompanyName: 'Microsoft Corp.' -> 'microsoft'
#        [PASS] Website: 'https://www.google.com/' -> 'google.com'
#        etc.

# Check results programmatically
$passedTests = $results | Where-Object { $_.Passed }
$failedTests = $results | Where-Object { -not $_.Passed }

Write-Host "Passed: $($passedTests.Count), Failed: $($failedTests.Count)"

# Export results for analysis
$results | Export-Csv -Path "normalization-test-results.csv" -NoTypeInformation
```

## 🔄 Advanced Usage Examples

### Pipeline Processing

```powershell
# Process CSV data
$companies = Import-Csv "companies.csv"
$companies | ForEach-Object {
    $_.NormalizedName = ConvertTo-NormalizedCompanyName -CompanyName $_.CompanyName
    $_.NormalizedWebsite = ConvertTo-NormalizedWebsite -Website $_.Website
    $_
} | Export-Csv "normalized-companies.csv" -NoTypeInformation

# Deduplicate data
$contacts = Import-Csv "contacts.csv"
$normalizedContacts = $contacts | ForEach-Object {
    [PSCustomObject]@{
        OriginalName = $_.Company
        NormalizedName = ConvertTo-NormalizedCompanyName -CompanyName $_.Company
        OriginalPhone = $_.Phone
        NormalizedPhone = ConvertTo-NormalizedPhoneNumber -PhoneNumber $_.Phone
    }
}

# Find duplicates based on normalized data
$duplicates = $normalizedContacts | Group-Object NormalizedName, NormalizedPhone |
    Where-Object { $_.Count -gt 1 }
```

### Custom Configuration

```powershell
# Modify configuration for specific use cases
$customOptions = @{
    PreserveCasing = $true
    RemoveFillerWords = $true
}

# Apply to multiple company names
$companies = @("The Microsoft Corporation", "Apple Inc.", "Google LLC")
$companies | ConvertTo-NormalizedCompanyName @customOptions
# Returns: "Microsoft", "Apple", "Google"
```

## 🔧 Build and Development

### Prerequisites

- PowerShell 5.1 or later
- Pester (for testing)
- PSScriptAnalyzer (for code analysis)
- platyPS (for documentation generation)
