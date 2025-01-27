@testable import MEGASwiftUI
import SwiftUI
import Testing

@Suite("Markdown file support view model suite")
struct MarkdownSupportTextViewModelTests {
    
    @Suite("Load text for Markdown file support")
    struct MarkdownSupportLoadText {
        @MainActor
        private func makeSUT(withString string: String) -> MarkdownSupportTextViewModel {
            let viewModel = MarkdownSupportTextViewModel(string: string)
            viewModel.loadText()
            return viewModel
        }
        
        @MainActor
        @Test func loadTextSplitsStringIntoChunks() {
            let sut = makeSUT(withString: "Line 1\nLine 2\nLine 3")
            
            #expect(sut.textChunks.count == 3, "TextChunks should have 3 elements.")
            #expect(sut.textChunks[0] == LocalizedStringKey("Line 1"), "First line should be 'Line 1'.")
            #expect(sut.textChunks[1] == LocalizedStringKey("Line 2"), "Second line should be 'Line 2'.")
            #expect(sut.textChunks[2] == LocalizedStringKey("Line 3"), "Third line should be 'Line 3'.")
        }
        
        @MainActor
        @Test func loadTextWithEmptyString() {
            let sut = makeSUT(withString: "")

            #expect(sut.textChunks.count == 0, "TextChunks should be empty for an empty string.")
        }
        
        @MainActor
        @Test func loadTextHandlesSingleLine() {
            let sut = makeSUT(withString: "Single Line")
            
            #expect(sut.textChunks.count == 1, "TextChunks should contain one element for a single-line string.")
            #expect(sut.textChunks[0] == LocalizedStringKey("Single Line"), "The single line should be correctly stored.")
        }
        
        @MainActor
        @Test func loadTextHandlesEmptyLines() {
            let sut = makeSUT(withString: "Line 1\n\nLine 3")
            
            #expect(sut.textChunks.count == 3, "TextChunks should include empty lines as separate elements.")
            #expect(sut.textChunks[1] == LocalizedStringKey(""), "Empty line should be represented as an empty LocalizedStringKey.")
        }
    }
}
