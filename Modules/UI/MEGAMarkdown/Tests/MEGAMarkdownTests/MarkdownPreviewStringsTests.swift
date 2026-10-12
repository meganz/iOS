@testable import MEGAMarkdown
import SwiftUI
import Testing

struct MarkdownPreviewStringsTests {
    @Test func englishHasNoEmptyString() {
        let fields = Mirror(reflecting: MarkdownPreviewStrings.english).children
        #expect(fields.count == 2)
        for field in fields {
            let value = field.value as? String
            #expect(value?.isEmpty == false, "\(field.label ?? "?") is empty")
        }
    }

    @Test func environmentDefaultIsEnglish() {
        #expect(EnvironmentValues().markdownPreviewStrings == .english)
    }

    @Test func environmentKeepsOverride() {
        var strings = MarkdownPreviewStrings.english
        strings.tooLarge = "Trop grand"
        var environment = EnvironmentValues()
        environment.markdownPreviewStrings = strings
        #expect(environment.markdownPreviewStrings.tooLarge == "Trop grand")
    }
}
