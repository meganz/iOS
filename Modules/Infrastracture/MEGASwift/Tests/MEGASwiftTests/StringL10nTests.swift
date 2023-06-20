import XCTest

final class StringL10nTests: XCTestCase {
    func testPlural_InitWithPositiveCountAndLocalization_LocalizedStringIsCorrect() {
        let plural = String.Plural(count: 5, localize: { "\($0) items" })
        XCTAssertEqual(plural.localizedString, "5 items")
    }
    
    func testPlural_InitWithZeroCountAndLocalization_LocalizedStringIsCorrect() {
        let plural = String.Plural(count: 0, localize: { "\($0) items" })
        XCTAssertEqual(plural.localizedString, "0 items")
    }
    
    func testConcatenate_WithEmptyPlurals_ReturnsEmptyString() {
        let result = String.concatenate(plurals: [])
        XCTAssertEqual(result, "")
    }
    
    func testConcatenate_WithMultiplePlurals_ReturnsCorrectConcatenation() {
        let plurals = [
            String.Plural(count: 3, localize: { "\($0) apples" }),
            String.Plural(count: 2, localize: { "\($0) oranges" })
        ]
        let result = String.concatenate(plurals: plurals)
        XCTAssertEqual(result, "3 apples and 2 oranges")
    }
    
    func testInject_WithPluralsAndStringGenerator_ReturnsCorrectlyInjectedString() {
        let plurals = [
            String.Plural(count: 3, localize: { "\($0) apples" }),
            String.Plural(count: 2, localize: { "\($0) oranges" })
        ]
        let result = String.inject(plurals: plurals) { "You have \($0)" }
        XCTAssertEqual(result, "You have 3 apples and 2 oranges")
    }
    
    func testInject_WithEmptyPluralsAndStringGenerator_ReturnsCorrectlyInjectedString() {
        let plurals: [String.Plural] = []
        let result = String.inject(plurals: plurals) { "You have \($0)" }
        XCTAssertEqual(result, "You have ")
    }
    
    func testConcatenate_WithMultiplePluralsInSpanish_ReturnsCorrectConcatenation() {
        let plurals = [
            String.Plural(count: 3, localize: { "\($0) manzanas" }),
            String.Plural(count: 2, localize: { "\($0) naranjas" }),
            String.Plural(count: 5, localize: { "\($0) peras" })
        ]
        let result = String.concatenate(plurals: plurals, locale: Locale(identifier: "es"))
        XCTAssertEqual(result, "3 manzanas, 2 naranjas y 5 peras")
    }
    
    func testConcatenate_WithMultiplePluralsInFrench_ReturnsCorrectConcatenation() {
        let plurals = [
            String.Plural(count: 3, localize: { "\($0) pommes" }),
            String.Plural(count: 2, localize: { "\($0) oranges" }),
            String.Plural(count: 5, localize: { "\($0) poires" })
        ]
        let result = String.concatenate(plurals: plurals, locale: Locale(identifier: "fr"))
        XCTAssertEqual(result, "3 pommes, 2 oranges et 5 poires")
    }
    
    func testConcatenate_WithMultiplePluralsInJapanese_ReturnsCorrectConcatenation() {
        let plurals = [
            String.Plural(count: 3, localize: { "\($0) りんご" }),
            String.Plural(count: 2, localize: { "\($0) オレンジ" }),
            String.Plural(count: 5, localize: { "\($0) 梨" })
        ]
        let result = String.concatenate(plurals: plurals, locale: Locale(identifier: "ja"))
        XCTAssertEqual(result, "3 りんご、2 オレンジ、5 梨")
    }
    
}
