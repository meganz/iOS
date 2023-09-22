import XCTest
@testable import TokenCodegenGenerator

final class TokenCodegenGeneratorTests: XCTestCase {
    func testParseRGBA_whenGivenValidRGBAInput_correctlyParses() throws {
        let rgbaString = "rgba(255, 255, 255, 0.8000)"
        let parsed = parseRGBA(rgbaString)

        guard let parsed else {
            XCTFail("Parsed RGBA should not be nil for valid input")
            return
        }

        XCTAssertEqual(parsed.red, CGFloat(1.0), accuracy: 0.001, "Red component should be 1.0")
        XCTAssertEqual(parsed.green, CGFloat(1.0), accuracy: 0.001, "Green component should be 1.0")
        XCTAssertEqual(parsed.blue, CGFloat(1.0), accuracy: 0.001, "Blue component should be 1.0")
        XCTAssertEqual(parsed.alpha, CGFloat(0.8), accuracy: 0.001, "Alpha component should be 0.8")
    }

    func testParseRGBA_whenGivenInvalidRGBAInput_returnsNil() throws {
        let rgbaString = "not_rgba(255, 255, 255, 0.8)"
        let parsed = parseRGBA(rgbaString)

        XCTAssertNil(parsed, "Parsed RGBA should be nil for invalid input")
    }

    func testParseRGBA_whenGivenIncompleteRGBAInput_returnsNil() throws {
        let rgbaString = "rgba(255, 255)"
        let parsed = parseRGBA(rgbaString)

        XCTAssertNil(parsed, "Parsed RGBA should be nil for incomplete input")
    }

    func testParseRGBA_whenGivenExtraComponentsInRGBAInput_returnsNil() throws {
        let rgbaString = "rgba(255, 255, 255, 0.8, 0.9)"
        let parsed = parseRGBA(rgbaString)

        XCTAssertNil(parsed, "Parsed RGBA should be nil for input with extra components")
    }

    func testParseHex_whenGivenValid6DigitHex_correctlyParses() {
        let hexString = "#fffaf5"
        let parsed = parseHex(hexString)

        guard let parsed = parsed else {
            XCTFail("Parsed RGBA should not be nil for valid input")
            return
        }

        XCTAssertEqual(parsed.red, CGFloat(1.0), accuracy: 0.001, "Red component should be 1.0")
        XCTAssertEqual(parsed.green, CGFloat(0.9804), accuracy: 0.001, "Green component should be approximately 0.9804")
        XCTAssertEqual(parsed.blue, CGFloat(0.9608), accuracy: 0.001, "Blue component should be approximately 0.9608")
        XCTAssertEqual(parsed.alpha, CGFloat(1.0), accuracy: 0.001, "Alpha component should be 1.0")
    }

    func testParseHex_whenGivenInvalidHex_returnsNil() {
        let hexString = "#zzzzzz"
        let parsed = parseHex(hexString)
        XCTAssertNil(parsed, "Parsed RGBA should be nil for invalid input")
    }

    func testParseHex_whenGivenIncompleteHex_returnsNil() {
        let hexString = "#fff"
        let parsed = parseHex(hexString)
        XCTAssertNil(parsed, "Parsed RGBA should be nil for incomplete input")
    }

    func testExtractColorData_whenLeafNodes_parsesCorrectly() throws {
        let json: [String: Any] = [
            "Black opacity": [
                "090": [
                    "$type": "color",
                    "$value": "rgba(0, 0, 0, 0.9000)"
                ]
            ]
        ]
        let colorData = extractColorData(from: json)
        XCTAssertEqual(colorData.keys.count, 1)

        guard case let .leaf(colorInfoDict)? = colorData["Black opacity"] else {
            XCTFail("Failed to extract leaf nodes correctly")
            return
        }

        XCTAssertEqual(colorInfoDict.keys.count, 1)
        XCTAssertEqual(colorInfoDict["090"]?.type, "color")
        XCTAssertEqual(colorInfoDict["090"]?.value, "rgba(0, 0, 0, 0.9000)")
    }

    func testExtractColorData_whenNestedNodes_parsesCorrectly() throws {
        let json: [String: Any] = [
            "Secondary": [
                "Orange": [
                    "100": [
                        "$type": "color",
                        "$value": "#ffead5"
                    ]
                ]
            ]
        ]
        let colorData = extractColorData(from: json)
        XCTAssertEqual(colorData.keys.count, 1)

        guard case let .node(category)? = colorData["Secondary"] else {
            XCTFail("Failed to extract nested nodes correctly")
            return
        }

        guard case let .leaf(colorInfoDict)? = category["Orange"] else {
            XCTFail("Failed to extract nested nodes correctly")
            return
        }

        XCTAssertEqual(colorInfoDict["100"]?.type, "color")
        XCTAssertEqual(colorInfoDict["100"]?.value, "#ffead5")
    }

    func testExtractColorData_whenInvalidJSON_doesNotParse() throws {
        let json: [String: Any] = [
            "Black opacity": "This should be a dictionary, not a string."
        ]
        let colorData = extractColorData(from: json)
        XCTAssertEqual(colorData.keys.count, 0)
    }
}

