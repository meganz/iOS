@testable import MEGAPDFViewer
import Testing

@MainActor
struct PDFViewSearchPreferencesTests {
    @Test(arguments: [(true, String.CompareOptions()), (false, String.CompareOptions.caseInsensitive)])
    func compareOptions_followMatchCase(matchesCase: Bool, expected: String.CompareOptions) {
        let sut = PDFViewSearchPreferences()
        sut.matchesCase = matchesCase

        #expect(sut.compareOptions == expected)
    }
}
