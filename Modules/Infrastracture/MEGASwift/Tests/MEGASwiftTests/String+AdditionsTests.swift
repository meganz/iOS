@testable import MEGASwift
import Testing

@Suite("String+Additions Tests")
struct StringAdditionsTests {

    @Test("Contains substring ignoring case and diacritics, with different case – should return true")
    func testContainsIgnoringCaseAndDiacritics_withMatchingSubstringDifferentCase_shouldReturnTrue() {
        #expect("Café au Lait".containsIgnoringCaseAndDiacritics(searchText: "AU"))
    }

    @Test("Contains substring ignoring case and diacritics, with different diacritic – should return true")
    func testContainsIgnoringCaseAndDiacritics_withMatchingSubstringDifferentDiacritic_shouldReturnTrue() {
        #expect("Café au Lait".containsIgnoringCaseAndDiacritics(searchText: "cafê"))
    }

    @Test("Contains substring ignoring case and diacritics, with non-matching substring – should return false")
    func testContainsIgnoringCaseAndDiacritics_withNonMatchingSubstring_shouldReturnFalse() {
        #expect("Café au Lait".containsIgnoringCaseAndDiacritics(searchText: "Latte") == false)
    }

    @Test("Contains substring ignoring case and diacritics, with empty search text – should return false")
    func testContainsIgnoringCaseAndDiacritics_withEmptySearchText_shouldReturnFalse() {
        #expect("Café au Lait".containsIgnoringCaseAndDiacritics(searchText: "") == false)
    }

    @Test("Contains substring ignoring case and diacritics, with whitespace-only search text – should return false")
    func testContainsIgnoringCaseAndDiacritics_withWhitespaceOnlySearchText_shouldReturnFalse() {
        #expect("Café au Lait".containsIgnoringCaseAndDiacritics(searchText: "   ") == false)
    }
}
