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

    @Test("Removing first leading hash, with empty string – should return empty string")
    func testRemovingFirstLeadingHash_withEmptyString_shouldReturnEmptyString() {
        #expect("".removingFirstLeadingHash() == "")
    }

    @Test("Removing first leading hash, with string starting with multiple hashes – should remove the first hash")
    func testRemovingFirstLeadingHash_withMultipleLeadingHashes_shouldReturnCorrectString() {
        #expect("###Swift".removingFirstLeadingHash() == "##Swift")
    }

    @Test("Removing first leading hash, with string starting with a single hash – should remove that hash")
    func testRemovingFirstLeadingHash_withSingleLeadingHash_shouldReturnCorrectString() {
        #expect("#Start".removingFirstLeadingHash() == "Start")
    }

    @Test("Removing first leading hash, with string that has no leading hash – should return the same string")
    func testRemovingFirstLeadingHash_withNoLeadingHash_shouldReturnSameString() {
        #expect("NoHash".removingFirstLeadingHash() == "NoHash")
    }

    @Test("Removing first leading hash, with string containing only hash – should return an empty string")
    func testRemovingFirstLeadingHash_withOnlyHash_shouldReturnEmptyString() {
        #expect("#".removingFirstLeadingHash() == "")
    }
}
