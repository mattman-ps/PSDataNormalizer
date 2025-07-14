function ConvertTo-NormalizedAddress {
    <#
    .SYNOPSIS
        Normalizes addresses by standardizing format and removing inconsistencies.

    .DESCRIPTION
        This function standardizes addresses for comparison and deduplication by:
        - Converting to lowercase
        - Removing street suffixes (Road, Blvd, etc.)
        - Removing office numbers (Suite 5, #26)
        - Removing punctuation and symbols
        - Standardizing directional abbreviations (NE, Northeast)
        - Trimming whitespace

    .PARAMETER Address
        The address to normalize.

    .PARAMETER PreserveCasing
        If specified, preserves the original casing instead of converting to lowercase.

    .PARAMETER KeepStreetSuffixes
        If specified, preserves street suffixes like "Street", "Avenue", etc.

    .PARAMETER StandardizeDirections
        If specified, standardizes directional abbreviations (Northeast -> NE).

    .EXAMPLE
        ConvertTo-NormalizedAddress -Address "123 Main Street, Suite 5"
        # Returns: "123 main"

    .EXAMPLE
        ConvertTo-NormalizedAddress -Address "456 Oak Ave NE, Apt 2B" -StandardizeDirections
        # Returns: "456 oak ne"

    .EXAMPLE
        ConvertTo-NormalizedAddress -Address "789 Broadway Blvd." -PreserveCasing -KeepStreetSuffixes
        # Returns: "789 Broadway Blvd"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Address,

        [Parameter()]
        [switch]$PreserveCasing,

        [Parameter()]
        [switch]$KeepStreetSuffixes,

        [Parameter()]
        [switch]$StandardizeDirections
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Address)) {
            return ''
        }

        try {
            $normalized = $Address.Trim()

            # Standardize directions if requested
            if ($StandardizeDirections) {
                $normalized = ConvertTo-StandardizedDirection -Text $normalized
            }

            # Remove office numbers
            $normalized = Remove-OfficeNumbers -Text $normalized

            # Remove street suffixes unless keeping them
            if (-not $KeepStreetSuffixes) {
                $normalized = Remove-StreetSuffixes -Text $normalized
            }

            # Remove punctuation and symbols (except spaces)
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
            Write-Error "Failed to normalize address '$Address': $($_.Exception.Message)"
            return $Address
        }
    }
}
