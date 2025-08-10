# Static pattern arrays for auto-detection (defined once at script level for performance optimization)
# These patterns are used by the 'Auto' data type to automatically detect and classify input data

# Phone number regex patterns supporting US and international formats
$script:PhonePatterns = @(
    # US formats: (555) 123-4567, 555-123-4567, 555.123.4567, 5551234567 (exactly 10 digits)
    '^\(?[2-9][0-9]{2}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}$',
    # US with country code: +1-555-123-4567, +1 (555) 123-4567 (11 digits total)
    '^\+?1[-.\s]?\(?[2-9][0-9]{2}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}$',
    # International formats with country codes (minimum 7 digits, max 15, must start with +)
    '^\+[2-9]\d{1,2}[-.\s]?(\d{1,4}[-.\s]?){1,4}\d{1,9}$',
    # International without + but with clear international prefixes (avoid ZIP code conflicts)
    '^00[1-9]\d{1,2}[-.\s]?(\d{1,4}[-.\s]?){1,4}\d{1,9}$'
)

# Postal/ZIP code regex patterns supporting multiple countries
$script:ZipPatterns = @(
    # US ZIP codes: 12345 or 12345-6789
    '^\d{5}(-\d{4})?$',
    # Canadian postal codes: K1A 0A6 or K1A0A6
    '^[A-Za-z]\d[A-Za-z][\s-]?\d[A-Za-z]\d$',
    # UK postal codes: SW1A 1AA, M1 1AA, B33 8TH
    '^[A-Za-z]{1,2}\d[A-Za-z\d]?\s?\d[A-Za-z]{2}$',
    # General international postal codes: 3-10 alphanumeric characters with optional separators
    '^[A-Za-z0-9\s-]{3,10}$'
)

function ConvertTo-NormalizedData {
    <#
    .SYNOPSIS
        Normalizes various types of data using intelligent auto-detection or explicit type specification.

    .DESCRIPTION
        This unified normalization function processes different data types including company names,
        websites, phone numbers, addresses, and postal codes. It features intelligent auto-detection
        capabilities that can identify data types using comprehensive regex patterns for US and
        international formats.

        When using 'Auto' mode, the function applies the following detection priority:
        1. Phone numbers (US and international formats)
        2. Website URLs
        3. Street addresses
        4. Postal/ZIP codes (US, Canadian, UK, and international)
        5. Company names (default fallback)

    .PARAMETER Data
        The data string to normalize. Can be piped from other cmdlets.

    .PARAMETER DataType
        The type of data to normalize. Valid values:
        - 'CompanyName': Normalizes business names
        - 'Website': Normalizes URLs and domain names
        - 'PhoneNumber': Normalizes phone numbers
        - 'Address': Normalizes street addresses
        - 'Zip': Normalizes postal/ZIP codes (US, Canadian, UK, international)
        - 'Auto': Automatically detects data type using regex patterns

    .PARAMETER Options
        A hashtable of options to pass to the specific normalization function.
        Options vary by data type - see individual normalization functions for details.

    .EXAMPLE
        ConvertTo-NormalizedData -Data "Microsoft Corporation, Inc." -DataType "CompanyName"
        # Returns: "microsoft"

    .EXAMPLE
        ConvertTo-NormalizedData -Data "https://www.google.com/search" -DataType "Website"
        # Returns: "google.com"

    .EXAMPLE
        ConvertTo-NormalizedData -Data "(555) 123-4567 ext. 123" -DataType "PhoneNumber"
        # Returns normalized phone number

    .EXAMPLE
        ConvertTo-NormalizedData -Data "+44 20 7946 0958" -DataType "Auto"
        # Auto-detects as phone number and normalizes accordingly

    .EXAMPLE
        ConvertTo-NormalizedData -Data "12345-6789" -DataType "Zip"
        # Returns: "12345-6789"

    .EXAMPLE
        ConvertTo-NormalizedData -Data "SW1A 1AA" -DataType "Zip"
        # Returns: "SW1A 1AA"

    .EXAMPLE
        # Process multiple items through pipeline with auto-detection
        @("Microsoft Corp", "(555) 123-4567", "12345-6789", "www.example.com") |
            ConvertTo-NormalizedData -DataType "Auto"

    .NOTES
        Auto-detection uses pre-compiled regex patterns stored at script level for optimal performance.
        Phone number patterns support US, Canadian, UK, and general international formats.
        Postal code patterns support US ZIP, Canadian, UK, and general international formats.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Data,

        [Parameter(Mandatory)]
        [ValidateSet('CompanyName', 'Website', 'PhoneNumber', 'Address', 'Zip', 'Auto')]
        [string]$DataType,

        [Parameter()]
        [hashtable]$Options = @{}
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Data)) {
            return ''
        }

        try {
            switch ($DataType) {
                'CompanyName' {
                    return ConvertTo-NormalizedCompanyName -CompanyName $Data @Options
                }
                'Website' {
                    return ConvertTo-NormalizedWebsite -Website $Data @Options
                }
                'PhoneNumber' {
                    return ConvertTo-NormalizedPhoneNumber -PhoneNumber $Data @Options
                }
                'Address' {
                    return ConvertTo-NormalizedAddress -Address $Data @Options
                }
                'Zip' {
                    # Normalize postal/ZIP codes with basic formatting
                    # Supports US ZIP, Canadian postal codes, UK postal codes, and international formats
                    $zipMatch = $false
                    foreach ($pattern in $script:ZipPatterns) {
                        if ($Data -match $pattern) {
                            $zipMatch = $true
                            break
                        }
                    }

                    if ($zipMatch) {
                        # Return postal code with basic formatting (trimmed and uppercase)
                        return $Data.Trim().ToLower()
                    } else {
                        # If no pattern matches, return as-is with basic cleanup
                        return $Data.Trim()
                    }
                }
                'Auto' {
                    # Intelligent auto-detection using optimized regex patterns
                    # Priority order: Phone → Website → Address → Postal Code → Company Name

                    # Apply pattern matching with priority-based detection
                    switch -Regex ($Data) {
                        # Priority 1: Phone numbers (US and international formats)
                        # Matches: (555) 123-4567, +1-555-123-4567, +44 20 7946 0958, etc.
                        {
                            $phoneMatch = $false
                            foreach ($pattern in $script:PhonePatterns) {
                                if ($_ -match $pattern) {
                                    $phoneMatch = $true
                                    break
                                }
                            }
                            $phoneMatch
                        } {
                            return ConvertTo-NormalizedPhoneNumber -PhoneNumber $Data @Options
                        }

                        # Priority 2: Website URLs and domains
                        # Matches: https://example.com, www.site.org, domain.net
                        '^https?://|^www\.|\.com$|\.org$|\.net$' {
                            return ConvertTo-NormalizedWebsite -Website $Data @Options
                        }

                        # Priority 3: Street addresses with common patterns
                        # Matches: 123 Main Street, 456 Oak Ave, 789 First Blvd
                        '\d+\s+\w+\s+(street|st|avenue|ave|road|rd|boulevard|blvd)' {
                            return ConvertTo-NormalizedAddress -Address $Data @Options
                        }

                        # Priority 4: Postal/ZIP codes (US, Canadian, UK, international)
                        # Matches: 12345, 12345-6789, K1A 0A6, SW1A 1AA
                        {
                            $zipMatch = $false
                            foreach ($pattern in $script:ZipPatterns) {
                                if ($_ -match $pattern) {
                                    $zipMatch = $true
                                    break
                                }
                            }
                            $zipMatch
                        } {
                            # Delegate to Zip data type for consistent processing
                            return ConvertTo-NormalizedData -Data $Data -DataType 'Zip' @Options
                        }

                        # Priority 5: Default fallback - treat as company name
                        # Applies company name normalization rules
                        default {
                            return ConvertTo-NormalizedCompanyName -CompanyName $Data @Options
                        }
                    }
                }
            }
        }
        catch {
            Write-Error "Failed to normalize data '$Data' as $DataType`: $($_.Exception.Message)"
            return $Data
        }
    }
}
