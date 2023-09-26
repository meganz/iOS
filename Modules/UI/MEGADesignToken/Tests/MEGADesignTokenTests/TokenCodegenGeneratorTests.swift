import XCTest
@testable import TokenCodegenGenerator

final class TokenCodegenGeneratorTests: XCTestCase {
    func testParseInput_whenGivenValidInput_returnsParseInputPayload() throws {
        let input = "[Path/To/Semantic tokens.Light.tokens.json, Path/To/Semantic tokens.Dark.tokens.json, Path/To/core.json]"
        let parsed = try parseInput(input)

        XCTAssertEqual(parsed.core, URL(fileURLWithPath: "Path/To/core.json"))
        XCTAssertEqual(parsed.semanticDark, URL(fileURLWithPath: "Path/To/Semantic tokens.Dark.tokens.json"))
        XCTAssertEqual(parsed.semanticLight, URL(fileURLWithPath: "Path/To/Semantic tokens.Light.tokens.json"))
    }

    func testParseInput_whenGivenInvalidArgumentCount_throwsWrongArgumentsError() throws {
        let input = "[Path/To/core.json, Path/To/Semantic tokens.Dark.tokens.json]"

        XCTAssertThrowsError(try parseInput(input)) { error in
            XCTAssertEqual(error as? ParseInputError, .wrongArguments)
        }
    }

    func testParseInput_whenGivenInvalidCorePath_throwsWrongArgumentsError() throws {
        let input = "[Path/To/Semantic tokens.Light.tokens.json, Path/To/Semantic tokens.Dark.tokens.json, Path/To/somefile.json]"

        XCTAssertThrowsError(try parseInput(input)) { error in
            XCTAssertEqual(error as? ParseInputError, .wrongArguments)
        }
    }

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

    func testExtractFlatColorData_whenLeafNodes_parsesCorrectly() throws {
        let json: [String: Any] = [
            "Black opacity": [
                "090": [
                    "$type": "color",
                    "$value": "rgba(0, 0, 0, 0.9000)"
                ]
            ]
        ]

        let colorData = extractFlatColorData(from: json)

        XCTAssertEqual(colorData.keys.count, 1)
        XCTAssertEqual(colorData["Black opacity.090"]?.properties.type, "color")
        XCTAssertEqual(colorData["Black opacity.090"]?.properties.value, "rgba(0, 0, 0, 0.9000)")
    }

    func testExtractFlatColorData_whenNestedNodes_parsesCorrectly() throws {
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

        let colorData = extractFlatColorData(from: json)

        XCTAssertEqual(colorData.keys.count, 1)
        XCTAssertEqual(colorData["Secondary.Orange.100"]?.properties.type, "color")
        XCTAssertEqual(colorData["Secondary.Orange.100"]?.properties.value, "#ffead5")
    }

    func testExtractFlatColorData_whenInvalidJSON_doesNotParse() throws {
        let json: [String: Any] = [
            "Black opacity": "This should be a dictionary, not a string."
        ]
        let colorData = extractFlatColorData(from: json)
        XCTAssertEqual(colorData.keys.count, 0)
    }

    func testExtractColorData_whenLeafNodes_parsesCorrectly() throws {
        let json: [String: Any] = [
            "Focus": [
                "--color-focus": [
                    "$type": "color",
                    "$value": "{Colors.Secondary.Indigo.700}"
                ]
            ]
        ]
        let flatMap = makeColorsFlatMap()

        let colorData = extractColorData(from: json, using: flatMap)
        XCTAssertEqual(colorData.keys.count, 1)

        guard case let .leaf(colorInfoDict)? = colorData["Focus"] else {
            XCTFail("Failed to extract leaf nodes correctly")
            return
        }

        XCTAssertEqual(colorInfoDict["--color-focus"]?.properties.type, "color")
        XCTAssertEqual(colorInfoDict["--color-focus"]?.properties.value, "#4B0082")
    }

    func testExtractColorData_whenNestedNodes_parsesCorrectly() throws {
        let json: [String: Any] = [
            "Indicator": [
                "NestedCategory": [
                    "--color-indicator-yellow": [
                        "$type": "color",
                        "$value": "{Colors.Warning.400}"
                    ]
                ]
            ]
        ]
        let flatMap = makeColorsFlatMap()

        let colorData = extractColorData(from: json, using: flatMap)
        XCTAssertEqual(colorData.keys.count, 1)

        guard case let .node(category)? = colorData["Indicator"] else {
            XCTFail("Failed to extract nested nodes correctly")
            return
        }

        guard case let .leaf(colorInfoDict)? = category["NestedCategory"] else {
            XCTFail("Failed to extract nested nodes correctly")
            return
        }

        XCTAssertEqual(colorInfoDict["--color-indicator-yellow"]?.properties.type, "color")
        XCTAssertEqual(colorInfoDict["--color-indicator-yellow"]?.properties.value, "#FFD700")
    }

    func testExtractColorData_whenInvalidJSON_doesNotParse() throws {
        let json: [String: Any] = [
            "Focus": "This should be a dictionary, not a string."
        ]
        let flatMap = makeColorsFlatMap()

        let colorData = extractColorData(from: json, using: flatMap)
        XCTAssertEqual(colorData.keys.count, 0)
    }
}

// MARK: - Helpers

private extension TokenCodegenGeneratorTests {
    func makeColorsFlatMap() -> [String: ColorInfo] {
        [
            "Secondary.Indigo.700": ColorInfo(properties: .init(type: "color", value: "#4B0082")),
            "Secondary.Magenta.300": ColorInfo(properties: .init(type: "color", value: "#FF00FF")),
            "Warning.400": ColorInfo(properties: .init(type: "color", value: "#FFD700")),
            "Secondary.Orange.300": ColorInfo(properties: .init(type: "color", value: "#FFA500")),
            "Secondary.Indigo.300": ColorInfo(properties: .init(type: "color", value: "#4B0082")),
            "Secondary.Blue.400": ColorInfo(properties: .init(type: "color", value: "#0000FF")),
            "Success.400": ColorInfo(properties: .init(type: "color", value: "#008000")),
            "Error.400": ColorInfo(properties: .init(type: "color", value: "#FF0000"))
        ]
    }
}
