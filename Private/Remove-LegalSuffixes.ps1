function Remove-LegalSuffixes {
    <#
    .SYNOPSIS
        Removes common legal suffixes from company names.

    .PARAMETER Text
        The text to process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    # Use configuration data if available, otherwise fall back to hardcoded values
    $legalSuffixes = if ($script:ModuleConfiguration.LegalSuffixes) {
        $script:ModuleConfiguration.LegalSuffixes
    } else {
        @(
            'Inc\.?', 'Incorporated', 'Corp\.?', 'Corporation', 'Co\.?', 'Company',
            'Ltd\.?', 'Limited', 'LLC', 'L\.L\.C\.?', 'LLP', 'L\.L\.P\.?',
            'LP', 'L\.P\.?', 'PC', 'P\.C\.?', 'PA', 'P\.A\.?', 'PLLC', 'P\.L\.L\.C\.?',
            'Professional Corporation', 'Professional Association', 'Limited Liability Company',
            'Limited Liability Partnership', 'Limited Partnership'
        )
    }

    $pattern = '\b(' + ($legalSuffixes -join '|') + ')\b'
    return $Text -replace $pattern, '' -replace '\s+', ' '
}
