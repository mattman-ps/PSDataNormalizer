<#
.SYNOPSIS
    Comprehensive examples demonstrating the PSDataNormalizer module functionality.

.DESCRIPTION
    This script showcases the various normalization functions available in the PSDataNormalizer
    module, including company names, websites, phone numbers, and addresses.
#>

# Define the normalization functions inline
function ConvertTo-NormalizedCompanyName {
    param(
        [string]$CompanyName,
        [switch]$RemoveFillerWords
    )
    if ([string]::IsNullOrWhiteSpace($CompanyName)) { return '' }
    $normalized = $CompanyName.Trim()
    # Remove legal suffixes
    $legalSuffixes = @('Inc\.?', 'Corp\.?', 'LLC', 'L\.L\.C\.?', 'Ltd\.?', 'Corporation', 'Company', 'Incorporated', 'Limited')
    $pattern = '\b(' + ($legalSuffixes -join '|') + ')\b'
    $normalized = $normalized -replace $pattern, ''
    # Remove filler words if requested
    if ($RemoveFillerWords) {
        $fillerWords = @('The', 'A', 'An', 'And', 'Or', 'Of', 'For', 'To', 'In', 'On', 'At', 'By', 'With')
        $fillerPattern = '\b(' + ($fillerWords -join '|') + ')\b'
        $normalized = $normalized -replace $fillerPattern, ''
    }
    # Remove other punctuation except & and -
    $normalized = $normalized -replace '[^\w\s&-]', ''
    # Convert hyphens to spaces, replace & with double space
    $normalized = $normalized -replace '-', ' ' -replace ' & ', '  '
    # Clean up multiple spaces but preserve intentional double spaces
    $normalized = $normalized -replace '\s{3,}', '  ' -replace '^\s+|\s+$', ''
    return $normalized.ToLowerInvariant()
}

function ConvertTo-NormalizedWebsite {
    param(
        [string]$Website,
        [switch]$IgnorePaths,
        [switch]$KeepSubdomains
    )
    if ([string]::IsNullOrWhiteSpace($Website)) { return '' }
    $normalized = $Website.Trim()
    # Remove common prefixes
    $normalized = $normalized -replace '^https?://', '' -replace '^www\.', ''
    # Convert domain to lowercase
    $normalized = $normalized.ToLowerInvariant()
    # Handle path options
    if ($IgnorePaths) {
        $normalized = $normalized -split '/' | Select-Object -First 1
    } else {
        # Remove trailing slash
        $normalized = $normalized -replace '/$', ''
    }
    # Handle subdomain options
    if (-not $KeepSubdomains -and -not $IgnorePaths) {
        # For this example, we'll keep the current behavior
    }
    return $normalized
}

function ConvertTo-NormalizedPhoneNumber {
    param(
        [string]$PhoneNumber,
        [string]$Format = "Raw"
    )
    if ([string]::IsNullOrWhiteSpace($PhoneNumber)) { return '' }
    # Strip all non-digit characters
    $normalized = $PhoneNumber -replace '[^\d]', ''
    # Remove US country code if present
    if ($normalized.StartsWith('1') -and $normalized.Length -eq 11) {
        $normalized = $normalized.Substring(1)
    }

    # Apply formatting
    switch ($Format) {
        "Standard" {
            if ($normalized.Length -eq 10) {
                return "($($normalized.Substring(0,3))) $($normalized.Substring(3,3))-$($normalized.Substring(6,4))"
            }
        }
        "Dotted" {
            if ($normalized.Length -eq 10) {
                return "$($normalized.Substring(0,3)).$($normalized.Substring(3,3)).$($normalized.Substring(6,4))"
            }
        }
        default { return $normalized }
    }
    return $normalized
}

function ConvertTo-NormalizedAddress {
    param(
        [string]$Address,
        [switch]$StandardizeDirections,
        [switch]$KeepStreetSuffixes
    )
    if ([string]::IsNullOrWhiteSpace($Address)) { return '' }
    $normalized = $Address.Trim().ToLowerInvariant()

    # Standardize directions if requested
    if ($StandardizeDirections) {
        $normalized = $normalized -replace '\bnorth\b', 'n' -replace '\bsouth\b', 's' -replace '\beast\b', 'e' -replace '\bwest\b', 'w'
        $normalized = $normalized -replace '\bnortheast\b', 'ne' -replace '\bnorthwest\b', 'nw' -replace '\bsoutheast\b', 'se' -replace '\bsouthwest\b', 'sw'
    }

    # Remove office numbers first
    $normalized = $normalized -replace '\b(suite|ste|apt|apartment|floor|room)\s*\w+', ''
    $normalized = $normalized -replace '\bunit\s*#?\s*\w+', ''

    # Remove street suffixes unless keeping them
    if (-not $KeepStreetSuffixes) {
        $streetSuffixes = @('street', 'st', 'avenue', 'ave', 'road', 'rd', 'boulevard', 'blvd', 'drive', 'lane', 'ln', 'parkway', 'pkwy', 'highway', 'hwy')
        foreach ($suffix in $streetSuffixes) {
            $normalized = $normalized -replace "\b$suffix\b", ''
        }
    }

    # Remove punctuation and clean up whitespace
    $normalized = $normalized -replace '[^\w\s]', '' -replace '\s+', ' '
    return $normalized.Trim()
}

function ConvertTo-NormalizedData {
    param(
        [string]$Data,
        [string]$DataType = "Auto"
    )
    if ([string]::IsNullOrWhiteSpace($Data)) { return '' }

    # Auto-detect data type if needed
    if ($DataType -eq "Auto") {
        if ($Data -match '^https?://|^www\.|\.com|\.org|\.net') {
            $DataType = "Website"
        } elseif ($Data -match '^\+?[\d\s\(\)\-\.]+$' -and $Data.Length -ge 10) {
            $DataType = "PhoneNumber"
        } elseif ($Data -match '\d+\s+\w+\s+(street|st|avenue|ave|road|rd|blvd|drive|dr|lane|ln)') {
            $DataType = "Address"
        } else {
            $DataType = "CompanyName"
        }
    }

    # Apply appropriate normalization
    switch ($DataType) {
        "CompanyName" { return ConvertTo-NormalizedCompanyName -CompanyName $Data }
        "Website" { return ConvertTo-NormalizedWebsite -Website $Data }
        "PhoneNumber" { return ConvertTo-NormalizedPhoneNumber -PhoneNumber $Data }
        "Address" { return ConvertTo-NormalizedAddress -Address $Data }
        default { return $Data.Trim().ToLowerInvariant() }
    }
}

function ConvertTo-ValidatedAddress {
    param(
        [string]$Address,
        [int]$RetryCount = 3,
        [int]$DelaySeconds = 2,
        [int]$TimeoutSeconds = 30,
        [switch]$FallbackToLocal
    )

    if ([string]::IsNullOrWhiteSpace($Address)) { return '' }

    # Pre-process address to improve API success rate
    $cleanedAddress = $Address -replace '\b(suite|ste|apt|apartment|unit|floor|room)\s*[#]?\s*[\w-]+', ''
    $cleanedAddress = $cleanedAddress -replace '[,;]+', ',' -replace '\s+', ' '
    $cleanedAddress = $cleanedAddress.Trim().Trim(',').Trim()

    for ($i = 0; $i -lt $RetryCount; $i++) {
        try {
            if ($i -gt 0) {
                Start-Sleep -Seconds $DelaySeconds
            }

            Add-Type -AssemblyName System.Web
            $encodedAddress = [System.Web.HttpUtility]::UrlEncode($cleanedAddress)
            $url = "https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&addressdetails=1&limit=1"

            $headers = @{ 'User-Agent' = 'PSDataNormalizer-PowerShell/1.0' }
            $response = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec $TimeoutSeconds -ErrorAction Stop

            if ($response -and $response.Count -gt 0) {
                return $response[0].display_name
            }
            break
        }
        catch {
            Write-Warning "Address validation attempt $($i + 1) failed: $($_.Exception.Message)"
            if ($i -eq $RetryCount - 1) {
                break
            }
        }
    }

    # Fallback to local normalization
    if ($FallbackToLocal) {
        return ConvertTo-NormalizedAddress -Address $Address
    }
    return $Address
}

Write-Host "Functions loaded successfully" -ForegroundColor Green

Write-Host "=== PSDataNormalizer Module Examples ===" -ForegroundColor Green
Write-Host

#region Company Name Normalization Examples

Write-Host "1. Company Name Normalization" -ForegroundColor Cyan
Write-Host "-----------------------------"

$companyExamples = @(
    "Microsoft Corporation",
    "Apple Inc.",
    "Google, LLC",
    "The Coca-Cola Company",
    "Amazon.com, Inc.",
    "Meta Platforms, Inc.",
    "Tesla, Inc.",
    "JPMorgan Chase & Co.",
    "Johnson & Johnson",
    "Procter & Gamble Co."
)

foreach ($company in $companyExamples) {
    $normalized = ConvertTo-NormalizedCompanyName -CompanyName $company
    $normalizedWithFillers = ConvertTo-NormalizedCompanyName -CompanyName $company -RemoveFillerWords

    Write-Host "Original: '$company'"
    Write-Host "  Standard: '$normalized'"
    Write-Host "  No Fillers: '$normalizedWithFillers'"
    Write-Host
}

#endregion

#region Website Normalization Examples

Write-Host "2. Website Normalization" -ForegroundColor Cyan
Write-Host "------------------------"

$websiteExamples = @(
    "https://www.microsoft.com/",
    "http://support.google.com/help",
    "HTTPS://WWW.APPLE.COM/PRODUCTS/",
    "www.amazon.com/books/bestsellers",
    "facebook.com",
    "https://developer.mozilla.org/en-US/docs/Web",
    "http://www.github.com/microsoft/",
    "https://stackoverflow.com/questions/tagged/powershell"
)

foreach ($website in $websiteExamples) {
    $normalized = ConvertTo-NormalizedWebsite -Website $website
    $normalizedIgnorePaths = ConvertTo-NormalizedWebsite -Website $website -IgnorePaths
    $normalizedKeepSubdomains = ConvertTo-NormalizedWebsite -Website $website -KeepSubdomains -IgnorePaths

    Write-Host "Original: '$website'"
    Write-Host "  Standard: '$normalized'"
    Write-Host "  Ignore Paths: '$normalizedIgnorePaths'"
    Write-Host "  Keep Subdomains: '$normalizedKeepSubdomains'"
    Write-Host
}

#endregion

#region Phone Number Normalization Examples

Write-Host "3. Phone Number Normalization" -ForegroundColor Cyan
Write-Host "------------------------------"

$phoneExamples = @(
    "+1 (555) 123-4567",
    "1-555-123-4567",
    "(555) 123.4567",
    "555 123 4567",
    "5551234567",
    "+1.555.123.4567",
    "1 555-123-4567 ext. 123",
    "+44 20 7946 0958"
)

foreach ($phone in $phoneExamples) {
    $normalizedRaw = ConvertTo-NormalizedPhoneNumber -PhoneNumber $phone
    $normalizedStandard = ConvertTo-NormalizedPhoneNumber -PhoneNumber $phone -Format "Standard"
    $normalizedDotted = ConvertTo-NormalizedPhoneNumber -PhoneNumber $phone -Format "Dotted"

    Write-Host "Original: '$phone'"
    Write-Host "  Raw: '$normalizedRaw'"
    Write-Host "  Standard: '$normalizedStandard'"
    Write-Host "  Dotted: '$normalizedDotted'"
    Write-Host
}

#endregion

#region Address Normalization Examples

Write-Host "4. Address Normalization" -ForegroundColor Cyan
Write-Host "------------------------"

$addressExamples = @(
    "123 Main Street, Suite 5",
    "456 Oak Ave NE, Apt 2B",
    "789 Broadway Blvd., Floor 10",
    "1000 Corporate Dr., Unit #25",
    "555 North Elm Road",
    "222 South Park Avenue, Room 304",
    "100 West First Street",
    "999 Northeast Highway, Suite A-5"
)

foreach ($address in $addressExamples) {
    $normalized = ConvertTo-NormalizedAddress -Address $address
    $normalizedWithDirections = ConvertTo-NormalizedAddress -Address $address -StandardizeDirections
    $normalizedKeepSuffixes = ConvertTo-NormalizedAddress -Address $address -KeepStreetSuffixes -StandardizeDirections

    Write-Host "Original: '$address'"
    Write-Host "  Standard: '$normalized'"
    Write-Host "  With Directions: '$normalizedWithDirections'"
    Write-Host "  Keep Suffixes: '$normalizedKeepSuffixes'"
    Write-Host
}

#endregion

#region Unified Normalization Examples

Write-Host "5. Unified Normalization (Auto-Detection)" -ForegroundColor Cyan
Write-Host "------------------------------------------"

$mixedData = @(
    @{ Data = "Microsoft Corporation"; Type = "Auto" },
    @{ Data = "https://www.google.com"; Type = "Auto" },
    @{ Data = "(555) 123-4567"; Type = "Auto" },
    @{ Data = "123 Main Street"; Type = "Auto" },
    @{ Data = "Apple Inc."; Type = "CompanyName" },
    @{ Data = "www.amazon.com/books"; Type = "Website" }
)

foreach ($item in $mixedData) {
    $normalized = ConvertTo-NormalizedData -Data $item.Data -DataType $item.Type
    Write-Host "Data: '$($item.Data)' (Type: $($item.Type))"
    Write-Host "  Normalized: '$normalized'"
    Write-Host
}

#endregion

#region Batch Processing Example

Write-Host "6. Batch Processing Example" -ForegroundColor Cyan
Write-Host "---------------------------"

# Simulate a CSV dataset
$customerData = @(
    @{ ID = 1; Company = "Microsoft Corp."; Website = "https://www.microsoft.com/"; Phone = "+1 (425) 882-8080"; Address = "One Microsoft Way, Redmond, WA" },
    @{ ID = 2; Company = "Apple Inc."; Website = "www.apple.com"; Phone = "1-408-996-1010"; Address = "1 Apple Park Way, Cupertino, CA" },
    @{ ID = 3; Company = "Google LLC"; Website = "https://www.google.com/"; Phone = "(650) 253-0000"; Address = "1600 Amphitheatre Pkwy, Mountain View, CA" }
)

Write-Host "Processing customer data..."
foreach ($customer in $customerData) {
    $normalizedCustomer = [PSCustomObject]@{
        ID = $customer.ID
        OriginalCompany = $customer.Company
        NormalizedCompany = ConvertTo-NormalizedCompanyName -CompanyName $customer.Company
        OriginalWebsite = $customer.Website
        NormalizedWebsite = ConvertTo-NormalizedWebsite -Website $customer.Website
        OriginalPhone = $customer.Phone
        NormalizedPhone = ConvertTo-NormalizedPhoneNumber -PhoneNumber $customer.Phone -Format "Standard"
        OriginalAddress = $customer.Address
        NormalizedAddress = ConvertTo-NormalizedAddress -Address $customer.Address
    }

    Write-Host "Customer $($customer.ID):"
    Write-Host "  Company: '$($normalizedCustomer.OriginalCompany)' -> '$($normalizedCustomer.NormalizedCompany)'"
    Write-Host "  Website: '$($normalizedCustomer.OriginalWebsite)' -> '$($normalizedCustomer.NormalizedWebsite)'"
    Write-Host "  Phone: '$($normalizedCustomer.OriginalPhone)' -> '$($normalizedCustomer.NormalizedPhone)'"
    Write-Host "  Address: '$($normalizedCustomer.OriginalAddress)' -> '$($normalizedCustomer.NormalizedAddress)'"
    Write-Host
}

#endregion

#region Online Address Validation Examples

Write-Host "8. Online Address Validation (Nominatim)" -ForegroundColor Cyan
Write-Host "----------------------------------------"

$validationExamples = @(
    "123 Main Street, New York, NY",
    "1600 Pennsylvania Avenue, Washington, DC",
    "One Microsoft Way, Redmond, WA",
    "1 Apple Park Way, Cupertino, CA",
    "Invalid Address That Doesn't Exist"
)

Write-Host "Testing online address validation with fallback to local normalization..." -ForegroundColor Yellow
Write-Host "Note: This requires internet connectivity and respects rate limits (2-second delays)" -ForegroundColor Yellow
Write-Host

foreach ($address in $validationExamples) {
    try {
        Write-Host "Validating: '$address'" -ForegroundColor White

        # Local normalization for comparison
        $localNormalized = ConvertTo-NormalizedAddress -Address $address

        # Online validation with fallback
        $validated = ConvertTo-ValidatedAddress -Address $address -FallbackToLocal -RetryCount 2

        Write-Host "  Local: '$localNormalized'" -ForegroundColor Gray
        Write-Host "  Online: '$validated'" -ForegroundColor Green
        Write-Host

        # Add delay to respect rate limits
        Start-Sleep -Seconds 2
    }
    catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host
    }
}

Write-Host "Online validation notes:" -ForegroundColor Yellow
Write-Host "- Uses Nominatim (OpenStreetMap) API - free but rate limited" -ForegroundColor Gray
Write-Host "- Includes retry logic and fallback to local normalization" -ForegroundColor Gray
Write-Host "- Best for postal address standardization" -ForegroundColor Gray
Write-Host "- Use local normalization for fast deduplication" -ForegroundColor Gray
Write-Host

#endregion

#region Pipeline Processing Example

Write-Host "9. Pipeline Processing Example" -ForegroundColor Cyan
Write-Host "------------------------------"

Write-Host "Company names through pipeline:"
@("Microsoft Corporation", "Apple Inc.", "Google, LLC") |
    ForEach-Object { ConvertTo-NormalizedCompanyName -CompanyName $_ } |
    ForEach-Object { Write-Host "  -> $_" }

Write-Host "`nWebsites through pipeline:"
@("https://www.microsoft.com", "www.google.com", "apple.com/products") |
    ForEach-Object { ConvertTo-NormalizedWebsite -Website $_ -IgnorePaths } |
    ForEach-Object { Write-Host "  -> $_" }

Write-Host "`nPhone numbers through pipeline:"
@("+1 (555) 123-4567", "1-555-987-6543", "(555) 111-2222") |
    ForEach-Object { ConvertTo-NormalizedPhoneNumber -PhoneNumber $_ -Format "Standard" } |
    ForEach-Object { Write-Host "  -> $_" }

#endregion

Write-Host "=== Examples Complete ===" -ForegroundColor Green
Write-Host
Write-Host "Available Functions:" -ForegroundColor Yellow
@('ConvertTo-NormalizedCompanyName', 'ConvertTo-NormalizedWebsite', 'ConvertTo-NormalizedPhoneNumber', 'ConvertTo-NormalizedAddress', 'ConvertTo-NormalizedData', 'ConvertTo-ValidatedAddress') | ForEach-Object {
    Write-Host "  - $_" -ForegroundColor White
}

Write-Host "`nFor help on any function, use: Get-Help <FunctionName> -Detailed" -ForegroundColor Yellow
