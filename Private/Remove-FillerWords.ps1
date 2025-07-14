function Remove-FillerWords {
    <#
    .SYNOPSIS
        Removes common filler words from text.

    .PARAMETER Text
        The text to process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    # Use configuration data if available, otherwise fall back to hardcoded values
    $fillerWords = if ($script:ModuleConfiguration.FillerWords) {
        $script:ModuleConfiguration.FillerWords
    } else {
        @('The', 'A', 'An', 'And', 'Or', 'Of', 'For', 'To', 'In', 'On', 'At', 'By', 'With')
    }

    $pattern = '\b(' + ($fillerWords -join '|') + ')\b'
    return $Text -replace $pattern, '' -replace '\s+', ' '
}
