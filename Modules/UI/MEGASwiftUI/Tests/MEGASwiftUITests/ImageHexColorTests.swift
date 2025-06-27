@testable import MEGASwiftUI
import SwiftUI
import Testing

struct ImageHexColorTests {

    // MARK: - Common Colors Tests

    @Test("Test common colors - Red")
    func testCommonColorRed() throws {
        let hexColor = Color(hex: "FF0000")
        let expectedColor = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test common colors - Green")
    func testCommonColorGreen() throws {
        let hexColor = Color(hex: "00FF00")
        let expectedColor = Color(red: 0.0, green: 1.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test common colors - Blue")
    func testCommonColorBlue() throws {
        let hexColor = Color(hex: "0000FF")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test common colors - White")
    func testCommonColorWhite() throws {
        let hexColor = Color(hex: "FFFFFF")
        let expectedColor = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test common colors - Black")
    func testCommonColorBlack() throws {
        let hexColor = Color(hex: "000000")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test common colors - Gray")
    func testCommonColorGray() throws {
        let hexColor = Color(hex: "808080")
        let expectedColor = Color(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test common colors - Purple")
    func testCommonColorPurple() throws {
        let hexColor = Color(hex: "800080")
        let expectedColor = Color(red: 128.0/255.0, green: 0.0, blue: 128.0/255.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    // MARK: - 3-digit Hex Tests

    @Test("Test 3-digit hex - Red")
    func testThreeDigitHexRed() throws {
        let hexColor = Color(hex: "F00")
        let expectedColor = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test 3-digit hex - Mixed")
    func testThreeDigitHexMixed() throws {
        let hexColor = Color(hex: "A5C")
        // A = 10 * 17 = 170, 5 = 5 * 17 = 85, C = 12 * 17 = 204
        let expectedColor = Color(red: 170.0/255.0, green: 85.0/255.0, blue: 204.0/255.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test 3-digit hex - White")
    func testThreeDigitHexWhite() throws {
        let hexColor = Color(hex: "FFF")
        let expectedColor = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test 3-digit hex - Black")
    func testThreeDigitHexBlack() throws {
        let hexColor = Color(hex: "000")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    // MARK: - Colors with Transparency Tests

    @Test("Test 8-digit hex with transparency - Semi-transparent red")
    func testTransparentRed() throws {
        let hexColor = Color(hex: "80FF0000") // 50% transparent red
        let expectedColor = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 128.0/255.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test 8-digit hex with transparency - Fully transparent")
    func testFullyTransparent() throws {
        let hexColor = Color(hex: "00FFFFFF")
        let expectedColor = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test 8-digit hex with transparency - Quarter transparent blue")
    func testQuarterTransparentBlue() throws {
        let hexColor = Color(hex: "400000FF") // 25% transparent blue
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 1.0, opacity: 64.0/255.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test 8-digit hex with transparency - Complex color")
    func testComplexTransparentColor() throws {
        let hexColor = Color(hex: "AA123456")
        let expectedColor = Color(red: 18.0/255.0, green: 52.0/255.0, blue: 86.0/255.0, opacity: 170.0/255.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test 8-digit hex with transparency - Fully opaque")
    func testFullyOpaque() throws {
        let hexColor = Color(hex: "FFFF0000") // Fully opaque red
        let expectedColor = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    // MARK: - Case Sensitivity Tests

    @Test("Test lowercase hex")
    func testLowercaseHex() throws {
        let hexColor = Color(hex: "ff0000")
        let expectedColor = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test mixed case hex")
    func testMixedCaseHex() throws {
        let hexColor = Color(hex: "AbCdEf")
        let expectedColor = Color(red: 171.0/255.0, green: 205.0/255.0, blue: 239.0/255.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test lowercase 3-digit hex")
    func testLowercaseThreeDigitHex() throws {
        let hexColor = Color(hex: "abc")
        // a = 10 * 17 = 170, b = 11 * 17 = 187, c = 12 * 17 = 204
        let expectedColor = Color(red: 170.0/255.0, green: 187.0/255.0, blue: 204.0/255.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test lowercase 8-digit hex")
    func testLowercaseEightDigitHex() throws {
        let hexColor = Color(hex: "80abcdef")
        let expectedColor = Color(red: 171.0/255.0, green: 205.0/255.0, blue: 239.0/255.0, opacity: 128.0/255.0)
        #expect(hexColor == expectedColor)
    }

    // MARK: - Hash Symbol Tests

    @Test("Test hex with hash symbol")
    func testHexWithHashSymbol() throws {
        let hexColor = Color(hex: "#FF0000")
        let expectedColor = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test 3-digit hex with hash")
    func testThreeDigitHexWithHash() throws {
        let hexColor = Color(hex: "#F00")
        let expectedColor = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test 8-digit hex with hash")
    func testEightDigitHexWithHash() throws {
        let hexColor = Color(hex: "#80FF0000")
        let expectedColor = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 128.0/255.0)
        #expect(hexColor == expectedColor)
    }

    // MARK: - Invalid Scenarios Tests

    @Test("Test empty string")
    func testEmptyString() throws {
        let hexColor = Color(hex: "")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test invalid length - 1 character")
    func testInvalidLengthOneCharacter() throws {
        let hexColor = Color(hex: "F")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test invalid length - 2 characters")
    func testInvalidLengthTwoCharacters() throws {
        let hexColor = Color(hex: "FF")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test invalid length - 4 characters")
    func testInvalidLengthFourCharacters() throws {
        let hexColor = Color(hex: "FFFF")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test invalid length - 5 characters")
    func testInvalidLengthFiveCharacters() throws {
        let hexColor = Color(hex: "FFFFF")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test invalid length - 7 characters")
    func testInvalidLengthSevenCharacters() throws {
        let hexColor = Color(hex: "FFFFFFF")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test invalid length - 9 characters")
    func testInvalidLengthNineCharacters() throws {
        let hexColor = Color(hex: "FFFFFFFFF")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test non-hex characters")
    func testNonHexCharacters() throws {
        let hexColor = Color(hex: "GGHHII")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test only symbols")
    func testOnlySymbols() throws {
        let hexColor = Color(hex: "######")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test only spaces")
    func testOnlySpaces() throws {
        let hexColor = Color(hex: "      ")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test mixed invalid characters")
    func testMixedInvalidCharacters() throws {
        let hexColor = Color(hex: "FF@#$%")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.0)
        #expect(hexColor == expectedColor)
    }

    // MARK: - Edge Cases

    @Test("Test maximum values - 6 digit")
    func testMaximumValuesSixDigit() throws {
        let hexColor = Color(hex: "FFFFFF")
        let expectedColor = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test maximum values - 8 digit")
    func testMaximumValuesEightDigit() throws {
        let hexColor = Color(hex: "FFFFFFFF")
        let expectedColor = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test minimum values - 3 digit")
    func testMinimumValuesThreeDigit() throws {
        let hexColor = Color(hex: "000")
        let expectedColor = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test boundary values")
    func testBoundaryValues() throws {
        let hexColor = Color(hex: "017F80FE")
        let expectedColor = Color(red: 127.0/255.0, green: 128.0/255.0, blue: 254.0/255.0, opacity: 1.0/255.0)
        #expect(hexColor == expectedColor)
    }

    @Test("Test mid-range values")
    func testMidRangeValues() throws {
        let hexColor = Color(hex: "7F7F7F")
        let expectedColor = Color(red: 127.0/255.0, green: 127.0/255.0, blue: 127.0/255.0, opacity: 1.0)
        #expect(hexColor == expectedColor)
    }
}
