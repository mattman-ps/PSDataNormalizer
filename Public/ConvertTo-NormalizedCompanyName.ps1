function ConvertTo-NormalizedCompanyName {
    <#
    .SYNOPSIS
        Normalizes company names by removing legal suffixes, punctuation, symbols, and filler words.

    .DESCRIPTION
        This function standardizes company names for comparison and deduplication by:
        - Converting to lowercase
        - Removing legal suffixes (Inc, Corp, LLC, etc.)
        - Removing punctuation and symbols
        - Removing filler words (The, A, An, etc.)
        - Trimming whitespace
        - Optionally preserving original casing

    .PARAMETER CompanyName
        The company name to normalize.

    .PARAMETER PreserveCasing
        If specified, preserves the original casing instead of converting to lowercase.

    .PARAMETER RemoveFillerWords
        If specified, removes common filler words like "The", "A", "And", etc.

    .EXAMPLE
        ConvertTo-NormalizedCompanyName -CompanyName "Microsoft Corporation"
        # Returns: "microsoft"

    .EXAMPLE
        ConvertTo-NormalizedCompanyName -CompanyName "The Apple Inc." -RemoveFillerWords
        # Returns: "apple"

    .EXAMPLE
        ConvertTo-NormalizedCompanyName -CompanyName "Google, LLC" -PreserveCasing
        # Returns: "Google"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$CompanyName,

        [Parameter()]
        [switch]$PreserveCasing,

        [Parameter()]
        [switch]$RemoveFillerWords
    )

    process {
        if ([string]::IsNullOrWhiteSpace($CompanyName)) {
            return ''
        }

        try {
            $normalized = $CompanyName.Trim()

            # Remove legal suffixes
            $normalized = Remove-LegalSuffixes -Text $normalized

            # Remove filler words if requested
            if ($RemoveFillerWords) {
                $normalized = Remove-FillerWords -Text $normalized
            }

            # Remove punctuation and symbols
            $normalized = $normalized -replace '[^\w\s]', ''

            # Convert to lowercase unless preserving casing
            if (-not $PreserveCasing) {
                $normalized = $normalized.ToLowerInvariant()
            }

            # Clean up whitespace
            $normalized = $normalized -replace '\s+', ' '
            $normalized = $normalized.Trim()

            return $normalized
        }
        catch {
            Write-Error "Failed to normalize company name '$CompanyName': $($_.Exception.Message)"
            return $CompanyName
        }
    }
}
