function Remove-OfficeNumbers {
    <#
    .SYNOPSIS
        Removes office/suite numbers from addresses.

    .PARAMETER Text
        The text to process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    # Use configuration data if available, otherwise fall back to hardcoded values
    $patterns = if ($script:ModuleConfiguration.OfficePatterns) {
        $script:ModuleConfiguration.OfficePatterns
    } else {
        @(
            'Suite\s+\w+',
            'Ste\.?\s+\w+',
            'Apartment\s+\w+',
            'Apt\.?\s+\w+',
            'Unit\s+\w+',
            'Floor\s+\w+',
            'Fl\.?\s+\w+',
            '#\s*\w+',
            'Room\s+\w+',
            '\bRm\.?\s+\w+'
        )
    }

    $result = $Text
    foreach ($pattern in $patterns) {
        $result = $result -replace $pattern, ''
    }

    return $result -replace '\s+', ' '
}