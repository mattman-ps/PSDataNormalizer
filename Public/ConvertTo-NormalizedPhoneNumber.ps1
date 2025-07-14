function ConvertTo-NormalizedPhoneNumber {
    <#
    .SYNOPSIS
        Normalizes phone numbers by removing non-digit characters and country codes.

    .DESCRIPTION
        This function standardizes phone numbers for comparison and deduplication by:
        - Stripping all non-digit characters
        - Removing country codes and +1 for US numbers
        - Optionally formatting the result
        - Validating phone number length

    .PARAMETER PhoneNumber
        The phone number to normalize.

    .PARAMETER Format
        Optional format for the output: 'Raw' (digits only), 'Standard' (XXX-XXX-XXXX), 'Dotted' (XXX.XXX.XXXX).

    .PARAMETER CountryCode
        The country code to remove. Defaults to '1' for US/Canada.

    .EXAMPLE
        ConvertTo-NormalizedPhoneNumber -PhoneNumber "+1 (555) 123-4567"
        # Returns: "5551234567"

    .EXAMPLE
        ConvertTo-NormalizedPhoneNumber -PhoneNumber "1-555-123-4567" -Format "Standard"
        # Returns: "555-123-4567"

    .EXAMPLE
        ConvertTo-NormalizedPhoneNumber -PhoneNumber "+44 20 7946 0958" -CountryCode "44"
        # Returns: "2079460958"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$PhoneNumber,

        [Parameter()]
        [ValidateSet('Raw', 'Standard', 'Dotted')]
        [string]$Format = 'Raw',

        [Parameter()]
        [string]$CountryCode = '1'
    )

    process {
        if ([string]::IsNullOrWhiteSpace($PhoneNumber)) {
            return ''
        }

        try {
            # Strip all non-digit characters
            $digits = $PhoneNumber -replace '[^\d]', ''

            # Remove country code if present
            if ($digits.StartsWith($CountryCode) -and $digits.Length -gt $CountryCode.Length) {
                $digits = $digits.Substring($CountryCode.Length)
            }

            # Validate length for US numbers (10 digits)
            if ($CountryCode -eq '1' -and $digits.Length -ne 10) {
                Write-Warning "Phone number '$PhoneNumber' does not appear to be a valid US/Canada number (expected 10 digits, got $($digits.Length))"
            }

            # Apply formatting
            switch ($Format) {
                'Standard' {
                    if ($digits.Length -eq 10) {
                        return "$($digits.Substring(0,3))-$($digits.Substring(3,3))-$($digits.Substring(6,4))"
                    }
                }
                'Dotted' {
                    if ($digits.Length -eq 10) {
                        return "$($digits.Substring(0,3)).$($digits.Substring(3,3)).$($digits.Substring(6,4))"
                    }
                }
            }

            return $digits
        }
        catch {
            Write-Error "Failed to normalize phone number '$PhoneNumber': $($_.Exception.Message)"
            return $PhoneNumber
        }
    }
}
