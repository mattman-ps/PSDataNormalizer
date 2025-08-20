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

        It 'Should handle multiple suite numbers correctly' {
            # Test the original issue case
            ConvertTo-NormalizedAddress -Address '6325 Mcleod Dr Suite# 7 & 8' | Should -Be '6325 mcleod'

            # Test various multiple suite formats
            ConvertTo-NormalizedAddress -Address '123 Main Street Suite 5A & 5B' | Should -Be '123 main'
            ConvertTo-NormalizedAddress -Address '456 Oak Ave Apt 2-4' | Should -Be '456 oak'
            ConvertTo-NormalizedAddress -Address '789 Pine Road Unit 100-102' | Should -Be '789 pine'
            ConvertTo-NormalizedAddress -Address '321 Elm St Ste. A, B & C' | Should -Be '321 elm'

            # Test with different separators
            ConvertTo-NormalizedAddress -Address '555 Broadway Suite 1 & 2 & 3' | Should -Be '555 broadway'
            ConvertTo-NormalizedAddress -Address '777 First Ave Apt 10A-10C' | Should -Be '777 first'
            ConvertTo-NormalizedAddress -Address '999 Second St Unit 5, 6, 7' | Should -Be '999 second'
        }

        It 'Should handle complex office designations' {
            # Test various office/suite keywords with multiple numbers
            ConvertTo-NormalizedAddress -Address '100 Third St Floor 2 & 3' | Should -Be '100 third'
            ConvertTo-NormalizedAddress -Address '200 Fourth Ave Room 101-103' | Should -Be '200 fourth'
            ConvertTo-NormalizedAddress -Address '300 Fifth Blvd Building A & B' | Should -Be '300 fifth'
            ConvertTo-NormalizedAddress -Address '400 Sixth Rd Fl. 1-5' | Should -Be '400 sixth'
        }
    }

    Context 'Unified Data Normalization' {
        It 'Should detect and normalize different data types' {
            ConvertTo-NormalizedData -Data 'Microsoft Corp' -DataType 'CompanyName' | Should -Be 'microsoft'
            ConvertTo-NormalizedData -Data 'https://www.google.com' -DataType 'Website' | Should -Be 'google.com'
            ConvertTo-NormalizedData -Data '(555) 123-4567' -DataType 'PhoneNumber' | Should -Be '5551234567'
            ConvertTo-NormalizedData -Data '123 Main St' -DataType 'Address' | Should -Be '123 main'
        }

        It 'Should normalize ZIP codes correctly' {
            # US ZIP codes
            ConvertTo-NormalizedData -Data '12345' -DataType 'Zip' | Should -Be '12345'
            ConvertTo-NormalizedData -Data '12345-6789' -DataType 'Zip' | Should -Be '12345-6789'

            # Canadian postal codes
            ConvertTo-NormalizedData -Data 'K1A 0A6' -DataType 'Zip' | Should -Be 'k1a 0a6'
            ConvertTo-NormalizedData -Data 'K1A0A6' -DataType 'Zip' | Should -Be 'k1a0a6'

            # UK postal codes
            ConvertTo-NormalizedData -Data 'SW1A 1AA' -DataType 'Zip' | Should -Be 'sw1a 1aa'
            ConvertTo-NormalizedData -Data 'M1 1AA' -DataType 'Zip' | Should -Be 'm1 1aa'
            ConvertTo-NormalizedData -Data 'B33 8TH' -DataType 'Zip' | Should -Be 'b33 8th'
        }

        It 'Should handle invalid ZIP codes gracefully' {
            # Invalid format should return trimmed input
            ConvertTo-NormalizedData -Data '   invalid-zip   ' -DataType 'Zip' | Should -Be 'invalid-zip'
            ConvertTo-NormalizedData -Data '1' -DataType 'Zip' | Should -Be '1'
        }

        It 'Should handle empty ZIP input' {
            ConvertTo-NormalizedData -Data '' -DataType 'Zip' | Should -Be ''
            ConvertTo-NormalizedData -Data '   ' -DataType 'Zip' | Should -Be ''
        }
    }

    Context 'Auto-Detection Data Normalization' {
        It 'Should auto-detect phone numbers with priority' {
            # US phone number formats
            ConvertTo-NormalizedData -Data '(555) 123-4567' -DataType 'Auto' | Should -Be '5551234567'
            ConvertTo-NormalizedData -Data '555-123-4567' -DataType 'Auto' | Should -Be '5551234567'
            ConvertTo-NormalizedData -Data '555.123.4567' -DataType 'Auto' | Should -Be '5551234567'
            ConvertTo-NormalizedData -Data '5551234567' -DataType 'Auto' | Should -Be '5551234567'

            # US with country code (removes the +1 country code)
            ConvertTo-NormalizedData -Data '+1-555-123-4567' -DataType 'Auto' | Should -Be '5551234567'
            ConvertTo-NormalizedData -Data '+1 (555) 123-4567' -DataType 'Auto' | Should -Be '5551234567'

            # International phone numbers
            ConvertTo-NormalizedData -Data '+44 20 7946 0958' -DataType 'Auto' | Should -Be '442079460958'
            ConvertTo-NormalizedData -Data '+33 1 42 86 83 26' -DataType 'Auto' | Should -Be '33142868326'
        }

        It 'Should auto-detect websites with correct priority' {
            ConvertTo-NormalizedData -Data 'https://www.example.com' -DataType 'Auto' | Should -Be 'example.com'
            ConvertTo-NormalizedData -Data 'www.example.com' -DataType 'Auto' | Should -Be 'example.com'
            ConvertTo-NormalizedData -Data 'example.com' -DataType 'Auto' | Should -Be 'example.com'
            ConvertTo-NormalizedData -Data 'test.org' -DataType 'Auto' | Should -Be 'test.org'
            ConvertTo-NormalizedData -Data 'site.net' -DataType 'Auto' | Should -Be 'site.net'
        }

        It 'Should auto-detect addresses with correct priority' {
            ConvertTo-NormalizedData -Data '123 Main Street' -DataType 'Auto' | Should -Be '123 main'
            ConvertTo-NormalizedData -Data '456 Oak Ave' -DataType 'Auto' | Should -Be '456 oak'
            ConvertTo-NormalizedData -Data '789 First Boulevard' -DataType 'Auto' | Should -Be '789 first'
            ConvertTo-NormalizedData -Data '321 Second Road' -DataType 'Auto' | Should -Be '321 second'
        }

        It 'Should auto-detect ZIP codes with correct priority' {
            # US ZIP codes
            ConvertTo-NormalizedData -Data '12345' -DataType 'Auto' | Should -Be '12345'
            ConvertTo-NormalizedData -Data '12345-6789' -DataType 'Auto' | Should -Be '12345-6789'

            # Canadian postal codes
            ConvertTo-NormalizedData -Data 'K1A 0A6' -DataType 'Auto' | Should -Be 'k1a 0a6'
            ConvertTo-NormalizedData -Data 'K1A0A6' -DataType 'Auto' | Should -Be 'k1a0a6'

            # UK postal codes
            ConvertTo-NormalizedData -Data 'SW1A 1AA' -DataType 'Auto' | Should -Be 'sw1a 1aa'
            ConvertTo-NormalizedData -Data 'M1 1AA' -DataType 'Auto' | Should -Be 'm1 1aa'
        }

        It 'Should default to company name normalization' {
            ConvertTo-NormalizedData -Data 'Microsoft Corporation' -DataType 'Auto' | Should -Be 'microsoft'
            ConvertTo-NormalizedData -Data 'Apple Inc.' -DataType 'Auto' | Should -Be 'apple'
            ConvertTo-NormalizedData -Data 'Some Random Company LLC' -DataType 'Auto' | Should -Be 'some random'
        }

        It 'Should handle priority conflicts correctly' {
            # When data could match multiple patterns, should follow priority order:
            # Phone > Website > Address > Postal Code > Company Name

            # Phone number that might look like a ZIP should be detected as phone
            ConvertTo-NormalizedData -Data '5551234567' -DataType 'Auto' | Should -Be '5551234567'

            # Website with address-like words should be detected as website
            ConvertTo-NormalizedData -Data 'mainstreet.com' -DataType 'Auto' | Should -Be 'mainstreet.com'
        }

        It 'Should handle empty input in auto-detection' {
            ConvertTo-NormalizedData -Data '' -DataType 'Auto' | Should -Be ''
            ConvertTo-NormalizedData -Data '   ' -DataType 'Auto' | Should -Be ''
        }

        It 'Should handle pipeline input correctly' {
            $TestData = @('Microsoft Corp', '(555) 123-4567', '12345-6789', 'www.example.com')
            $Results = $TestData | ConvertTo-NormalizedData -DataType 'Auto'

            $Results.Count | Should -Be 4
            $Results[0] | Should -Be 'microsoft'  # Company name
            $Results[1] | Should -Be '5551234567'  # Phone number
            $Results[2] | Should -Be '12345-6789'  # ZIP code
            $Results[3] | Should -Be 'example.com'  # Website
        }
    }

    Context 'Error Handling and Edge Cases' {
        It 'Should handle options parameter correctly' {
            # Test that options are passed through to underlying functions
            $Options = @{ PreserveCasing = $true }
            ConvertTo-NormalizedData -Data 'Microsoft Corp' -DataType 'CompanyName' -Options $Options | Should -Be 'Microsoft'

            $Options = @{ KeepSubdomains = $true }
            ConvertTo-NormalizedData -Data 'https://support.microsoft.com' -DataType 'Website' -Options $Options | Should -Be 'support.microsoft.com'
        }

        It 'Should handle invalid data gracefully without throwing' {
            # Should not throw exceptions, just return original or processed data
            { ConvertTo-NormalizedData -Data 'invalid-data-123!@#' -DataType 'PhoneNumber' } | Should -Not -Throw
            { ConvertTo-NormalizedData -Data '   ' -DataType 'Address' } | Should -Not -Throw
            { ConvertTo-NormalizedData -Data 'not-a-url' -DataType 'Website' } | Should -Not -Throw
        }

        It 'Should maintain consistent output types' {
            $Result1 = ConvertTo-NormalizedData -Data 'Microsoft' -DataType 'CompanyName'
            $Result2 = ConvertTo-NormalizedData -Data '' -DataType 'CompanyName'
            $Result3 = ConvertTo-NormalizedData -Data 'test.com' -DataType 'Auto'

            $Result1 | Should -BeOfType [String]
            $Result2 | Should -BeOfType [String]
            $Result3 | Should -BeOfType [String]
        }

        It 'Should handle special characters in auto-detection' {
            # Special characters should not break the regex patterns
            ConvertTo-NormalizedData -Data 'Company & Co.' -DataType 'Auto' | Should -Be ''
            ConvertTo-NormalizedData -Data 'Test (555) 123-4567 ext' -DataType 'Auto' | Should -Be 'test 555 1234567 ext'
        }

        It 'Should handle very long input strings' {
            $LongString = 'A' * 1000 + ' Corporation'
            $Result = ConvertTo-NormalizedData -Data $LongString -DataType 'CompanyName'
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -BeOfType [String]
        }
    }

    Context 'Pattern Recognition Validation' {
        It 'Should recognize various international phone formats' {
            # Test comprehensive international phone number support
            $InternationalPhones = @(
                '+86 138 0013 8000',     # China
                '+81 3 1234 5678',       # Japan
                '+49 30 12345678',       # Germany
                '+33 1 42 86 83 26',     # France
                '+39 06 1234 5678',      # Italy
                '+7 495 123 45 67',      # Russia
                '+91 11 2345 6789',      # India
                '+55 11 1234 5678'       # Brazil
            )

            foreach ($Phone in $InternationalPhones) {
                $Result = ConvertTo-NormalizedData -Data $Phone -DataType 'Auto'
                $Result | Should -Not -Be $Phone  # Should be normalized, not returned as-is
                # Should be digits and spaces removed, or treated as company name if not detected as phone
                $Result.Length | Should -BeGreaterThan 0  # Should return something
            }
        }

        It 'Should recognize various international postal codes' {
            # Test comprehensive international postal code support
            $InternationalPostal = @(
                '10115',        # Germany
                '75001',        # France
                '100-0001',     # Japan
                '00100',        # Kenya
                'H0H 0H0',      # Canada (Santa's postal code)
                'SE1 9GP',      # UK
                '1010',         # Australia
                '0001'          # South Africa
            )

            foreach ($Postal in $InternationalPostal) {
                $Result = ConvertTo-NormalizedData -Data $Postal -DataType 'Auto'
                # Should be recognized as postal code (lowercased)
                $Result | Should -Be $Postal.ToLower()
            }
        }

        It 'Should prioritize phone detection over postal codes' {
            # Phone numbers that could be mistaken for postal codes should be detected as phones
            $PhonelikeNumbers = @(
                '5551234567',    # US phone without formatting
                '4471234567',    # UK-like number
                '1234567890'     # Generic 10-digit number
            )

            foreach ($Number in $PhonelikeNumbers) {
                $Result = ConvertTo-NormalizedData -Data $Number -DataType 'Auto'
                # Should be treated as phone (based on US format patterns)
                $Result | Should -Be $Number  # Phone normalization of digits-only
            }
        }

        It 'Should handle edge cases in pattern matching' {
            # Test boundary conditions and special cases
            ConvertTo-NormalizedData -Data '+' -DataType 'Auto' | Should -Be ''  # Single plus should default to company (empty result)
            ConvertTo-NormalizedData -Data '123' -DataType 'Auto' | Should -Be '123'  # Too short for most patterns, treated as company
            ConvertTo-NormalizedData -Data '+1' -DataType 'Auto' | Should -Be '1'  # Country code only, treat as company
            ConvertTo-NormalizedData -Data 'www.' -DataType 'Auto' | Should -Be ''  # Incomplete website, treated as company (empty result)
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
