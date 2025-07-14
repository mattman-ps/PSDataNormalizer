BeforeAll {
    # Import the module
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\PSDataNormalizer.psd1'
    Import-Module $ModulePath -Force
}

Describe 'PSDataNormalizer Module Tests' {

    Context 'Module Import' {
        It 'Should import the module successfully' {
            Get-Module -Name PSDataNormalizer | Should -Not -BeNullOrEmpty
        }

        It 'Should export all expected functions' {
            $ExportedFunctions = (Get-Module -Name PSDataNormalizer).ExportedFunctions.Keys
            $ExpectedFunctions = @(
                'ConvertTo-NormalizedCompanyName',
                'ConvertTo-NormalizedWebsite',
                'ConvertTo-NormalizedPhoneNumber',
                'ConvertTo-NormalizedAddress',
                'ConvertTo-NormalizedData',
                'ConvertTo-ValidatedAddress',
                'Test-NormalizedData'
            )

            foreach ($Function in $ExpectedFunctions) {
                $ExportedFunctions | Should -Contain $Function
            }
        }
    }

    Context 'Company Name Normalization' {
        It 'Should normalize company names correctly' {
            ConvertTo-NormalizedCompanyName -CompanyName 'Microsoft Corporation' | Should -Be 'microsoft'
            ConvertTo-NormalizedCompanyName -CompanyName 'Apple Inc.' | Should -Be 'apple'
            ConvertTo-NormalizedCompanyName -CompanyName 'Google, LLC' | Should -Be 'google'
        }

        It 'Should handle empty input' {
            ConvertTo-NormalizedCompanyName -CompanyName '' | Should -Be ''
            ConvertTo-NormalizedCompanyName -CompanyName '   ' | Should -Be ''
        }

        It 'Should preserve casing when requested' {
            ConvertTo-NormalizedCompanyName -CompanyName 'Microsoft Corp' -PreserveCasing | Should -Be 'Microsoft'
        }

        It 'Should remove filler words when requested' {
            ConvertTo-NormalizedCompanyName -CompanyName 'The Apple Inc.' -RemoveFillerWords | Should -Be 'apple'
        }
    }

    Context 'Website Normalization' {
        It 'Should normalize websites correctly' {
            ConvertTo-NormalizedWebsite -Website 'https://www.microsoft.com/' | Should -Be 'microsoft.com'
            ConvertTo-NormalizedWebsite -Website 'HTTP://WWW.GOOGLE.COM' | Should -Be 'google.com'
            ConvertTo-NormalizedWebsite -Website 'apple.com/' | Should -Be 'apple.com'
        }

        It 'Should handle subdomains when requested' {
            ConvertTo-NormalizedWebsite -Website 'https://support.microsoft.com' -KeepSubdomains | Should -Be 'support.microsoft.com'
        }

        It 'Should ignore paths when requested' {
            ConvertTo-NormalizedWebsite -Website 'https://www.google.com/search?q=test' -IgnorePaths | Should -Be 'google.com'
        }
    }

    Context 'Phone Number Normalization' {
        It 'Should normalize phone numbers correctly' {
            ConvertTo-NormalizedPhoneNumber -PhoneNumber '+1 (555) 123-4567' | Should -Be '5551234567'
            ConvertTo-NormalizedPhoneNumber -PhoneNumber '1-555-123-4567' | Should -Be '5551234567'
            ConvertTo-NormalizedPhoneNumber -PhoneNumber '555.123.4567' | Should -Be '5551234567'
        }

        It 'Should format phone numbers when requested' {
            ConvertTo-NormalizedPhoneNumber -PhoneNumber '5551234567' -Format 'Standard' | Should -Be '555-123-4567'
            ConvertTo-NormalizedPhoneNumber -PhoneNumber '5551234567' -Format 'Dotted' | Should -Be '555.123.4567'
        }
    }

    Context 'Address Normalization' {
        It 'Should normalize addresses correctly' {
            ConvertTo-NormalizedAddress -Address '123 Main Street, Suite 5' | Should -Be '123 main'
            ConvertTo-NormalizedAddress -Address '456 Oak Ave.' | Should -Be '456 oak'
        }

        It 'Should standardize directions when requested' {
            ConvertTo-NormalizedAddress -Address '123 Main St NE' -StandardizeDirections | Should -Be '123 main ne'
            ConvertTo-NormalizedAddress -Address '456 Oak Avenue North' -StandardizeDirections | Should -Be '456 oak n'
        }

        It 'Should keep street suffixes when requested' {
            ConvertTo-NormalizedAddress -Address '123 Main Street' -KeepStreetSuffixes | Should -Be '123 main street'
        }
    }

    Context 'Unified Data Normalization' {
        It 'Should detect and normalize different data types' {
            ConvertTo-NormalizedData -Data 'Microsoft Corp' -DataType 'CompanyName' | Should -Be 'microsoft'
            ConvertTo-NormalizedData -Data 'https://www.google.com' -DataType 'Website' | Should -Be 'google.com'
            ConvertTo-NormalizedData -Data '(555) 123-4567' -DataType 'PhoneNumber' | Should -Be '5551234567'
            ConvertTo-NormalizedData -Data '123 Main St' -DataType 'Address' | Should -Be '123 main'
        }
    }

    Context 'Test Function' {
        It 'Should run tests and return results' {
            $TestData = @(
                @{ Input = 'Microsoft Corp.'; Expected = 'microsoft'; DataType = 'CompanyName' }
            )

            $Results = Test-NormalizedData -TestData $TestData
            $Results | Should -Not -BeNullOrEmpty
            $Results[0].Passed | Should -Be $true
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module -Name DataNormalization -Force -ErrorAction SilentlyContinue
}
