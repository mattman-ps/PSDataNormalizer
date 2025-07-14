function ConvertTo-NormalizedWebsite {
    <#
    .SYNOPSIS
        Normalizes website URLs by removing common prefixes and standardizing format.

    .DESCRIPTION
        This function standardizes website URLs for comparison and deduplication by:
        - Removing common prefixes (http://, https://, www.)
        - Converting domain to lowercase
        - Optionally ignoring paths and trailing slashes
        - Trimming whitespace

    .PARAMETER Website
        The website URL to normalize.

    .PARAMETER IgnorePaths
        If specified, removes paths and query parameters, keeping only the domain.

    .PARAMETER KeepSubdomains
        If specified, preserves subdomains other than 'www'.

    .EXAMPLE
        ConvertTo-NormalizedWebsite -Website "https://www.microsoft.com/"
        # Returns: "microsoft.com"

    .EXAMPLE
        ConvertTo-NormalizedWebsite -Website "http://support.google.com/help" -IgnorePaths -KeepSubdomains
        # Returns: "support.google.com"

    .EXAMPLE
        ConvertTo-NormalizedWebsite -Website "HTTPS://WWW.APPLE.COM/PRODUCTS/"
        # Returns: "apple.com"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Website,

        [Parameter()]
        [switch]$IgnorePaths,

        [Parameter()]
        [switch]$KeepSubdomains
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Website)) {
            return ''
        }

        try {
            $normalized = $Website.Trim()

            # Remove protocol prefixes
            $normalized = $normalized -replace '^https?://', ''

            # Remove www prefix unless keeping subdomains
            if (-not $KeepSubdomains) {
                $normalized = $normalized -replace '^www\.', ''
            }

            # Convert to lowercase
            $normalized = $normalized.ToLowerInvariant()

            # Remove paths if requested
            if ($IgnorePaths) {
                $normalized = $normalized -split '[/?#]' | Select-Object -First 1
            }

            # Remove trailing slashes
            $normalized = $normalized.TrimEnd('/')

            return $normalized
        }
        catch {
            Write-Error "Failed to normalize website '$Website': $($_.Exception.Message)"
            return $Website
        }
    }
}
