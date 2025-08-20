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

    $result = $Text

    # Define patterns that should remove everything from the keyword to the end of the string or next major delimiter
    $officePatterns = @(
        # Suite patterns - match "Suite" or "Ste" followed by anything until end or semicolon (allow commas in suite numbers)
        '(?i)\b(Suite|Ste\.?)\s*#?\s*.*?(?=\s*[;]|\s*$)',

        # Apartment patterns
        '(?i)\b(Apartment|Apt\.?)\s+.*?(?=\s*[;]|\s*$)',

        # Unit patterns
        '(?i)\bUnit\s+.*?(?=\s*[;]|\s*$)',

        # Floor patterns
        '(?i)\b(Floor|Fl\.?)\s+.*?(?=\s*[;]|\s*$)',

        # Room patterns
        '(?i)\b(Room|Rm\.?)\s+.*?(?=\s*[;]|\s*$)',

        # Building patterns
        '(?i)\b(Building|Bldg\.?)\s+.*?(?=\s*[;]|\s*$)',

        # Hash patterns for standalone numbers (be careful not to match building numbers)
        '(?i)(?<!\d)\s*#\s*[\w\s&\-,]*?(?=\s*[;]|\s*$)'
    )

    # Apply each pattern
    foreach ($pattern in $officePatterns) {
        $result = $result -replace $pattern, ''
    }

    # Clean up extra whitespace
    $result = $result -replace '\s+', ' '
    $result = $result.Trim()

    return $result
}