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

    # Remove patterns like "Suite 5", "#26", "Apt 3A", "Unit 10", etc.
    $patterns = @(
        'Suite\s+\w+',
        'Ste\.?\s+\w+',
        'Apartment\s+\w+',
        'Apt\.?\s+\w+',
        'Unit\s+\w+',
        'Floor\s+\w+',
        'Fl\.?\s+\w+',
        '#\s*\w+',
        'Room\s+\w+',
        'Rm\.?\s+\w+'
    )

    $result = $Text
    foreach ($pattern in $patterns) {
        $result = $result -replace $pattern, ''
    }

    return $result -replace '\s+', ' '
}
