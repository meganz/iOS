import SwiftUI

/// Texts the preview shows. The host app passes its localized strings with `markdownPreviewStrings(_:)`.
public struct MarkdownPreviewStrings: Equatable, Sendable {
    /// Shown instead of the content when the text is too big to preview.
    public var tooLarge: String
    /// Shown above a part of the file that is too big to format. That part follows as plain text.
    public var shownAsPlainText: String

    public init(tooLarge: String, shownAsPlainText: String) {
        self.tooLarge = tooLarge
        self.shownAsPlainText = shownAsPlainText
    }

    /// English texts. The environment uses them when the host passes no strings.
    public static let english = MarkdownPreviewStrings(
        tooLarge: "This file is too large to preview.",
        shownAsPlainText: "This part is too large to format. It is shown as plain text."
    )
}

extension EnvironmentValues {
    @Entry var markdownPreviewStrings = MarkdownPreviewStrings.english
}

extension View {
    /// Sets the texts for all Markdown previews below this view.
    public func markdownPreviewStrings(_ strings: MarkdownPreviewStrings) -> some View {
        environment(\.markdownPreviewStrings, strings)
    }
}
