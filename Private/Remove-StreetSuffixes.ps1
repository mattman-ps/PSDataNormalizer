function Remove-StreetSuffixes {
    <#
    .SYNOPSIS
        Removes common street suffixes from addresses.

    .PARAMETER Text
        The text to process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $streetSuffixes = @(
        'Street', 'St\.?', 'Avenue', 'Ave\.?', 'Road', 'Rd\.?', 'Boulevard', 'Blvd\.?',
        'Drive', 'Dr\.?', 'Lane', 'Ln\.?', 'Court', 'Ct\.?', 'Circle', 'Cir\.?',
        'Place', 'Pl\.?', 'Square', 'Sq\.?', 'Terrace', 'Ter\.?', 'Way', 'Parkway', 'Pkwy\.?',
        'Highway', 'Hwy\.?', 'Freeway', 'Fwy\.?'
    )

    $pattern = '\b(' + ($streetSuffixes -join '|') + ')\b'
    return $Text -replace $pattern, '' -replace '\s+', ' '
}
