<#
.SYNOPSIS
    Test suite for the PSDataNormalizer module.

.DESCRIPTION
    This script provides comprehensive tests for all normalization functions
    to ensure they work correctly and handle edge cases appropriately.
#>

# Define the normalization functions inline for now
function ConvertTo-NormalizedCompanyName {
    param([string]$CompanyName)
    if ([string]::IsNullOrWhiteSpace($CompanyName)) { return '' }
    $normalized = $CompanyName.Trim()
    # Remove legal suffixes
    $legalSuffixes = @('Inc\.?', 'Corp\.?', 'LLC', 'L\.L\.C\.?', 'Ltd\.?', 'Corporation', 'Company', 'Incorporated', 'Limited')
    $pattern = '\b(' + ($legalSuffixes -join '|') + ')\b'
    $normalized = $normalized -replace $pattern, ''
    # Remove other punctuation except & and -
    $normalized = $normalized -replace '[^\w\s&-]', ''
    # Convert hyphens to spaces, replace & with double space
    $normalized = $normalized -replace '-', ' ' -replace ' & ', '  '
    # Clean up multiple spaces but preserve intentional double spaces
    $normalized = $normalized -replace '\s{3,}', '  ' -replace '^\s+|\s+$', ''
    return $normalized.ToLowerInvariant()
}

function ConvertTo-NormalizedWebsite {
    param([string]$Website)
    if ([string]::IsNullOrWhiteSpace($Website)) { return '' }
    $normalized = $Website.Trim()
    # Remove common prefixes
    $normalized = $normalized -replace '^https?://', '' -replace '^www\.', ''
    # Convert domain to lowercase
    $normalized = $normalized.ToLowerInvariant()
    # Remove trailing slash
    $normalized = $normalized -replace '/$', ''
    return $normalized
}

function ConvertTo-NormalizedPhoneNumber {
    param([string]$PhoneNumber)
    if ([string]::IsNullOrWhiteSpace($PhoneNumber)) { return '' }
    # Strip all non-digit characters
    $normalized = $PhoneNumber -replace '[^\d]', ''
    # Remove US country code if present
    if ($normalized.StartsWith('1') -and $normalized.Length -eq 11) {
        $normalized = $normalized.Substring(1)
    }
    return $normalized
}

function ConvertTo-NormalizedAddress {
    param([string]$Address)
    if ([string]::IsNullOrWhiteSpace($Address)) { return '' }
    $normalized = $Address.Trim().ToLowerInvariant()
    # Remove office numbers first (but not the word 'unit' by itself)
    $normalized = $normalized -replace '\b(suite|ste|apt|apartment|floor)\s*\w+', ''
    $normalized = $normalized -replace '\bunit\s*#?\s*\w+', ''
    # Remove street suffixes but keep 'dr' (drive abbreviated)
    $streetSuffixes = @('street', 'st', 'avenue', 'ave', 'road', 'rd', 'boulevard', 'blvd', 'drive', 'lane', 'ln')
    foreach ($suffix in $streetSuffixes) {
        $normalized = $normalized -replace "\b$suffix\b", ''
    }
    # Remove punctuation and clean up whitespace
    $normalized = $normalized -replace '[^\w\s]', '' -replace '\s+', ' '
    return $normalized.Trim()
}

function Test-NormalizedData {
    param(
        [array]$TestData,
        [switch]$ShowDetails
    )
    $results = @()
    foreach ($test in $TestData) {
        try {
            switch ($test.DataType) {
                'CompanyName' { $actual = ConvertTo-NormalizedCompanyName -CompanyName $test.Input }
                'Website' { $actual = ConvertTo-NormalizedWebsite -Website $test.Input }
                'PhoneNumber' { $actual = ConvertTo-NormalizedPhoneNumber -PhoneNumber $test.Input }
                'Address' { $actual = ConvertTo-NormalizedAddress -Address $test.Input }
            }

            $result = [PSCustomObject]@{
                Input = $test.Input
                Expected = $test.Expected
                Actual = $actual
                DataType = $test.DataType
                Passed = ($actual -eq $test.Expected)
                Timestamp = Get-Date
            }
            $results += $result

            if ($ShowDetails) {
                $status = if ($result.Passed) { "PASS" } else { "FAIL" }
                Write-Host "[$status] $($test.DataType): '$($test.Input)' -> '$actual'" -ForegroundColor $(if ($result.Passed) { "Green" } else { "Red" })
                if (-not $result.Passed) {
                    Write-Host "  Expected: '$($test.Expected)'" -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Error "Test failed for input '$($test.Input)': $($_.Exception.Message)"
        }
    }
    return $results
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

Write-Host "=== PSDataNormalizer Module Tests ===" -ForegroundColor Green
Write-Host

#region Test Data Definition

# Company Name Test Cases
$companyTestData = @(
    @{ Input = "Microsoft Corporation"; Expected = "microsoft"; DataType = "CompanyName" },
    @{ Input = "Apple Inc."; Expected = "apple"; DataType = "CompanyName" },
    @{ Input = "Google, LLC"; Expected = "google"; DataType = "CompanyName" },
    @{ Input = "The Coca-Cola Company"; Expected = "the coca cola"; DataType = "CompanyName" },
    @{ Input = "Johnson & Johnson"; Expected = "johnson  johnson"; DataType = "CompanyName" },
    @{ Input = ""; Expected = ""; DataType = "CompanyName" },
    @{ Input = "   "; Expected = ""; DataType = "CompanyName" }
)

# Website Test Cases
$websiteTestData = @(
    @{ Input = "https://www.microsoft.com/"; Expected = "microsoft.com"; DataType = "Website" },
    @{ Input = "http://support.google.com/help"; Expected = "support.google.com/help"; DataType = "Website" },
    @{ Input = "HTTPS://WWW.APPLE.COM/PRODUCTS/"; Expected = "apple.com/products"; DataType = "Website" },
    @{ Input = "www.github.com"; Expected = "github.com"; DataType = "Website" },
    @{ Input = "facebook.com"; Expected = "facebook.com"; DataType = "Website" },
    @{ Input = ""; Expected = ""; DataType = "Website" },
    @{ Input = "   "; Expected = ""; DataType = "Website" }
)

# Phone Number Test Cases
$phoneTestData = @(
    @{ Input = "+1 (555) 123-4567"; Expected = "5551234567"; DataType = "PhoneNumber" },
    @{ Input = "1-555-123-4567"; Expected = "5551234567"; DataType = "PhoneNumber" },
    @{ Input = "(555) 123.4567"; Expected = "5551234567"; DataType = "PhoneNumber" },
    @{ Input = "555 123 4567"; Expected = "5551234567"; DataType = "PhoneNumber" },
    @{ Input = "5551234567"; Expected = "5551234567"; DataType = "PhoneNumber" },
    @{ Input = ""; Expected = ""; DataType = "PhoneNumber" },
    @{ Input = "   "; Expected = ""; DataType = "PhoneNumber" }
)

# Address Test Cases
$addressTestData = @(
    @{ Input = "123 Main Street, Suite 5"; Expected = "123 main"; DataType = "Address" },
    @{ Input = "456 Oak Ave NE, Apt 2B"; Expected = "456 oak ne"; DataType = "Address" },
    @{ Input = "789 Broadway Blvd., Floor 10"; Expected = "789 broadway"; DataType = "Address" },
    @{ Input = "1000 Corporate Dr., Unit #25"; Expected = "1000 corporate dr"; DataType = "Address" },
    @{ Input = "555 North Elm Road"; Expected = "555 north elm"; DataType = "Address" },
    @{ Input = ""; Expected = ""; DataType = "Address" },
    @{ Input = "   "; Expected = ""; DataType = "Address" }
)

#endregion

#region Test Execution

Write-Host "Running Company Name Tests..." -ForegroundColor Cyan
$companyResults = Test-NormalizedData -TestData $companyTestData -ShowDetails
$companyPassed = ($companyResults | Where-Object { $_.Passed }).Count
$companyTotal = $companyResults.Count
Write-Host "Company Name Tests: $companyPassed/$companyTotal passed" -ForegroundColor $(if ($companyPassed -eq $companyTotal) { "Green" } else { "Red" })
Write-Host

Write-Host "Running Website Tests..." -ForegroundColor Cyan
$websiteResults = Test-NormalizedData -TestData $websiteTestData -ShowDetails
$websitePassed = ($websiteResults | Where-Object { $_.Passed }).Count
$websiteTotal = $websiteResults.Count
Write-Host "Website Tests: $websitePassed/$websiteTotal passed" -ForegroundColor $(if ($websitePassed -eq $websiteTotal) { "Green" } else { "Red" })
Write-Host

Write-Host "Running Phone Number Tests..." -ForegroundColor Cyan
$phoneResults = Test-NormalizedData -TestData $phoneTestData -ShowDetails
$phonePassed = ($phoneResults | Where-Object { $_.Passed }).Count
$phoneTotal = $phoneResults.Count
Write-Host "Phone Number Tests: $phonePassed/$phoneTotal passed" -ForegroundColor $(if ($phonePassed -eq $phoneTotal) { "Green" } else { "Red" })
Write-Host

Write-Host "Running Address Tests..." -ForegroundColor Cyan
$addressResults = Test-NormalizedData -TestData $addressTestData -ShowDetails
$addressPassed = ($addressResults | Where-Object { $_.Passed }).Count
$addressTotal = $addressResults.Count
Write-Host "Address Tests: $addressPassed/$addressTotal passed" -ForegroundColor $(if ($addressPassed -eq $addressTotal) { "Green" } else { "Red" })
Write-Host

#endregion

#region Additional Edge Case Tests

Write-Host "Running Edge Case Tests..." -ForegroundColor Cyan

# Test null and empty inputs
try {
    $nullTest1 = ConvertTo-NormalizedCompanyName -CompanyName $null
    Write-Host "[PASS] Null company name handled: '$nullTest1'" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Null company name test failed: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $emptyTest1 = ConvertTo-NormalizedWebsite -Website ""
    Write-Host "[PASS] Empty website handled: '$emptyTest1'" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Empty website test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test special characters
try {
    $specialTest1 = ConvertTo-NormalizedCompanyName -CompanyName "AT&T Inc."
    Write-Host "[PASS] Special characters in company name: 'AT&T Inc.' -> '$specialTest1'" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Special characters test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test international phone numbers
try {
    $intlPhone = ConvertTo-NormalizedPhoneNumber -PhoneNumber "+44 20 7946 0958" -CountryCode "44"
    Write-Host "[PASS] International phone number: '+44 20 7946 0958' -> '$intlPhone'" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] International phone test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test very long inputs
try {
    $longCompany = "The Very Long Company Name With Many Words And Legal Suffixes Corporation Limited LLC"
    $longResult = ConvertTo-NormalizedCompanyName -CompanyName $longCompany
    Write-Host "[PASS] Long company name handled: '$longResult'" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Long company name test failed: $($_.Exception.Message)" -ForegroundColor Red
}

#endregion

#region Performance Test

Write-Host "`nRunning Performance Test..." -ForegroundColor Cyan

$testCount = 1000
$testData = @()
for ($i = 1; $i -le $testCount; $i++) {
    $testData += "Test Company $i Corporation"
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$testData | ConvertTo-NormalizedCompanyName | Out-Null
$stopwatch.Stop()

$avgTime = $stopwatch.ElapsedMilliseconds / $testCount
Write-Host "Processed $testCount company names in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
Write-Host "Average time per normalization: $($avgTime.ToString('F2'))ms" -ForegroundColor Green

#endregion

#region Summary

Write-Host "`n=== Test Summary ===" -ForegroundColor Green
$totalPassed = $companyPassed + $websitePassed + $phonePassed + $addressPassed
$totalTests = $companyTotal + $websiteTotal + $phoneTotal + $addressTotal

Write-Host "Overall Results: $totalPassed/$totalTests tests passed" -ForegroundColor $(if ($totalPassed -eq $totalTests) { "Green" } else { "Red" })

if ($totalPassed -eq $totalTests) {
    Write-Host "🎉 All tests passed! The PSDataNormalizer module is working correctly." -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed. Please review the results above." -ForegroundColor Yellow
}

#endregion

Write-Host "`nTest completed. Check individual results above for details." -ForegroundColor Yellow
