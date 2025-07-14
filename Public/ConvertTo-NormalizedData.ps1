function ConvertTo-NormalizedData {
    <#
    .SYNOPSIS
        Normalizes various types of data using the appropriate normalization function.

    .DESCRIPTION
        This unified function automatically detects the data type and applies the appropriate
        normalization function. It can process company names, websites, phone numbers, and addresses.

    .PARAMETER Data
        The data to normalize.

    .PARAMETER DataType
        The type of data to normalize: 'CompanyName', 'Website', 'PhoneNumber', 'Address', or 'Auto'.

    .PARAMETER Options
        A hashtable of options to pass to the specific normalization function.

    .EXAMPLE
        ConvertTo-NormalizedData -Data "Microsoft Corporation" -DataType "CompanyName"
        # Returns: "microsoft"

    .EXAMPLE
        ConvertTo-NormalizedData -Data "https://www.google.com" -DataType "Website"
        # Returns: "google.com"

    .EXAMPLE
        $options = @{ Format = 'Standard' }
        ConvertTo-NormalizedData -Data "(555) 123-4567" -DataType "PhoneNumber" -Options $options
        # Returns: "555-123-4567"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Data,

        [Parameter(Mandatory)]
        [ValidateSet('CompanyName', 'Website', 'PhoneNumber', 'Address', 'Auto')]
        [string]$DataType,

        [Parameter()]
        [hashtable]$Options = @{}
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Data)) {
            return ''
        }

        try {
            switch ($DataType) {
                'CompanyName' {
                    return ConvertTo-NormalizedCompanyName -CompanyName $Data @Options
                }
                'Website' {
                    return ConvertTo-NormalizedWebsite -Website $Data @Options
                }
                'PhoneNumber' {
                    return ConvertTo-NormalizedPhoneNumber -PhoneNumber $Data @Options
                }
                'Address' {
                    return ConvertTo-NormalizedAddress -Address $Data @Options
                }
                'Auto' {
                    # Simple auto-detection logic
                    if ($Data -match '^https?://|^www\.|\.com$|\.org$|\.net$') {
                        return ConvertTo-NormalizedWebsite -Website $Data @Options
                    }
                    elseif ($Data -match '^\+?[\d\s\-\(\)\.]+$') {
                        return ConvertTo-NormalizedPhoneNumber -PhoneNumber $Data @Options
                    }
                    elseif ($Data -match '\d+\s+\w+\s+(street|st|avenue|ave|road|rd|boulevard|blvd)') {
                        return ConvertTo-NormalizedAddress -Address $Data @Options
                    }
                    else {
                        return ConvertTo-NormalizedCompanyName -CompanyName $Data @Options
                    }
                }
            }
        }
        catch {
            Write-Error "Failed to normalize data '$Data' as $DataType`: $($_.Exception.Message)"
            return $Data
        }
    }
}
