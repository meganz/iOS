@testable import MEGAMarkdownEditor
import SwiftUI
import Testing

@Suite("MarkdownEditorStrings")
struct MarkdownEditorStringsTests {
    @Test func englishHasNoEmptyString() {
        let fields = Mirror(reflecting: MarkdownEditorStrings.english).children
        // The count pins the string list: a new string must be added to this check on purpose.
        #expect(fields.count == 33)
        for field in fields {
            let value = field.value as? String
            #expect(value?.isEmpty == false, "\(field.label ?? "?") is empty")
        }
    }

    @Test func styleNameCoversEveryHeadingLevel() {
        let strings = MarkdownEditorStrings.english
        let names = [nil, 1, 2, 3, 4, 5, 6].map { strings.styleName(forHeading: $0) }
        #expect(names == ["Body", "Heading 1", "Heading 2", "Heading 3", "Heading 4", "Heading 5", "Heading 6"])
    }

    @Test func environmentDefaultIsEnglish() {
        #expect(EnvironmentValues().markdownEditorStrings == .english)
    }

    @Test func environmentKeepsOverride() {
        var strings = MarkdownEditorStrings.english
        strings.bold = "Gras"
        var environment = EnvironmentValues()
        environment.markdownEditorStrings = strings
        #expect(environment.markdownEditorStrings.bold == "Gras")
    }
}
