function ConvertTo-StandardizedDirection {
    <#
    .SYNOPSIS
        Standardizes directional abbreviations.

    .PARAMETER Text
        The text to process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $directions = @{
        '\bN\.?\b|\bNorth\b' = 'N'
        '\bS\.?\b|\bSouth\b' = 'S'
        '\bE\.?\b|\bEast\b' = 'E'
        '\bW\.?\b|\bWest\b' = 'W'
        '\bNE\.?\b|\bNortheast\b' = 'NE'
        '\bNW\.?\b|\bNorthwest\b' = 'NW'
        '\bSE\.?\b|\bSoutheast\b' = 'SE'
        '\bSW\.?\b|\bSouthwest\b' = 'SW'
    }

    $result = $Text
    foreach ($pattern in $directions.Keys) {
        $result = $result -replace $pattern, $directions[$pattern]
    }

    return $result
}
