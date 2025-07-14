function Test-NormalizedData {
    <#
    .SYNOPSIS
        Tests and validates normalized data for consistency and accuracy.

    .DESCRIPTION
        This function provides testing capabilities for the normalization functions,
        including validation of results and comparison of before/after data.

    .PARAMETER TestData
        An array of test data objects with 'Input', 'Expected', and 'DataType' properties.

    .PARAMETER ShowDetails
        If specified, shows detailed comparison results.

    .EXAMPLE
        $testData = @(
            @{ Input = "Microsoft Corp."; Expected = "microsoft"; DataType = "CompanyName" },
            @{ Input = "https://www.google.com/"; Expected = "google.com"; DataType = "Website" }
        )
        Test-NormalizedData -TestData $testData -ShowDetails
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [array]$TestData,

        [Parameter()]
        [switch]$ShowDetails
    )

    $results = @()

    foreach ($test in $TestData) {
        try {
            $actual = ConvertTo-NormalizedData -Data $test.Input -DataType $test.DataType

            $result = [PSCustomObject]@{
                Input = $test.Input
                Expected = $test.Expected
                Actual = $actual
                DataType = $test.DataType
                Passed = ($actual -eq $test.Expected)
                Timestamp = Get-Date
            }

            $results += $result

            if ($ShowDetails) {
                $status = if ($result.Passed) { "PASS" } else { "FAIL" }
                Write-Host "[$status] $($test.DataType): '$($test.Input)' -> '$actual'" -ForegroundColor $(if ($result.Passed) { "Green" } else { "Red" })
                if (-not $result.Passed) {
                    Write-Host "  Expected: '$($test.Expected)'" -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Error "Test failed for input '$($test.Input)': $($_.Exception.Message)"
        }
    }

    return $results
}
