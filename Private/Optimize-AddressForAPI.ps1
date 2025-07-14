function Optimize-AddressForAPI {
    <#
    .SYNOPSIS
        Optimizes an address string for better API geocoding results.

    .PARAMETER Address
        The address to optimize.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Address
    )

    # Remove suite/apartment numbers that can confuse geocoding APIs
    $cleaned = $Address -replace '\b(suite|ste|apt|apartment|unit|floor|room)\s*[#]?\s*[\w-]+', ''

    # Remove extra punctuation and normalize spacing
    $cleaned = $cleaned -replace '[,;]+', ',' -replace '\s+', ' '

    # Remove leading/trailing whitespace and commas
    $cleaned = $cleaned.Trim().Trim(',').Trim()

    # Limit to reasonable length (APIs work better with shorter queries)
    if ($cleaned.Length -gt 100) {
        $parts = $cleaned -split ','
        if ($parts.Count -gt 2) {
            # Keep first two parts (street and city/state)
            $cleaned = ($parts[0..1] -join ',').Trim()
        } else {
            # Truncate if single long string
            $cleaned = $cleaned.Substring(0, 100).Trim()
        }
    }

    return $cleaned
}
