function ConvertTo-ValidatedAddress {
    <#
    .SYNOPSIS
        Validates and standardizes addresses using the Nominatim (OpenStreetMap) geocoding service.

    .DESCRIPTION
        This function validates addresses against the Nominatim geocoding API to return
        standardized postal addresses. It includes retry logic and rate limiting to handle
        API timeouts and restrictions.

    .PARAMETER Address
        The address to validate and standardize.

    .PARAMETER RetryCount
        Number of retry attempts if the API call fails. Default is 3.

    .PARAMETER DelaySeconds
        Delay in seconds between retry attempts. Default is 2 seconds to respect rate limits.

    .PARAMETER TimeoutSeconds
        Timeout for the API request in seconds. Default is 30.

    .PARAMETER FallbackToLocal
        If true, falls back to local normalization if API fails. Default is true.

    .EXAMPLE
        ConvertTo-ValidatedAddress -Address "123 Main St, New York, NY"
        # Returns: "123 Main Street, New York, NY 10001, United States"

    .EXAMPLE
        ConvertTo-ValidatedAddress -Address "1600 Pennsylvania Ave" -RetryCount 1
        # Returns validated address with single retry attempt

    .NOTES
        - Uses Nominatim API which is free but rate-limited to 1 request per second
        - Requires internet connectivity
        - Falls back to local normalization if API is unavailable
        - Respects OpenStreetMap usage policy
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Address,

        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$RetryCount = 3,

        [Parameter()]
        [ValidateRange(1, 30)]
        [int]$DelaySeconds = 2,

        [Parameter()]
        [ValidateRange(5, 120)]
        [int]$TimeoutSeconds = 30,

        [Parameter()]
        [switch]$FallbackToLocal
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Address)) {
            return ''
        }

        # Pre-process address to improve API success rate
        $cleanedAddress = Optimize-AddressForAPI -Address $Address

        for ($i = 0; $i -lt $RetryCount; $i++) {
            try {
                # Add delay to respect rate limits (1 request per second)
                if ($i -gt 0) {
                    Write-Verbose "Waiting $DelaySeconds seconds before retry attempt $($i + 1)..."
                    Start-Sleep -Seconds $DelaySeconds
                }

                # Encode address for URL
                Add-Type -AssemblyName System.Web
                $encodedAddress = [System.Web.HttpUtility]::UrlEncode($cleanedAddress)

                # Build Nominatim URL
                $url = "https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&addressdetails=1&limit=1"

                Write-Verbose "Attempting to validate address: '$cleanedAddress' (attempt $($i + 1))"

                # Make API request with proper user agent and timeout
                $headers = @{
                    'User-Agent' = 'PSDataNormalizer-PowerShell/1.0'
                }

                $response = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec $TimeoutSeconds -ErrorAction Stop

                if ($response -and $response.Count -gt 0) {
                    $validatedAddress = $response[0].display_name
                    Write-Verbose "Successfully validated address: '$validatedAddress'"
                    return $validatedAddress
                } else {
                    Write-Warning "No results found for address: '$Address'"
                    break
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-Verbose "Attempt $($i + 1) failed: $errorMessage"

                if ($errorMessage -like "*Query took too long*" -or $errorMessage -like "*timeout*") {
                    Write-Warning "API timeout occurred. This may be due to rate limiting or complex address."
                } elseif ($errorMessage -like "*429*" -or $errorMessage -like "*rate*") {
                    Write-Warning "Rate limit exceeded. Increasing delay for next attempt."
                    $DelaySeconds = $DelaySeconds * 2  # Exponential backoff
                } else {
                    Write-Warning "API error: $errorMessage"
                }

                # If this is the last attempt, break out of the loop
                if ($i -eq $RetryCount - 1) {
                    Write-Warning "All $RetryCount attempts failed for address validation."
                    break
                }
            }
        }

        # Fallback to local normalization if API fails
        if ($FallbackToLocal) {
            Write-Verbose "Falling back to local address normalization"
            return ConvertTo-NormalizedAddress -Address $Address
        } else {
            Write-Warning "Address validation failed and fallback is disabled"
            return $Address
        }
    }
}
