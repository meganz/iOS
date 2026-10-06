import MEGADesignToken
import SwiftUI

/// The box of a code block: background, corners, language label and top and bottom padding.
/// The content draws the code and sets its own side padding.
/// A big code block is drawn as several pieces. Only the first and last piece get the outer padding and corners.
package struct CodeBlockFrame<Content: View>: View {
    let language: String?
    let isFirst: Bool
    let isLast: Bool
    let content: Content

    @Environment(\.markdownTheme) private var theme

    package init(language: String?, isFirst: Bool, isLast: Bool, @ViewBuilder content: () -> Content) {
        self.language = language
        self.isFirst = isFirst
        self.isLast = isLast
        self.content = content()
    }

    package var body: some View {
        let radius = theme.codeBlockCornerRadius
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? radius : 0,
            bottomLeadingRadius: isLast ? radius : 0,
            bottomTrailingRadius: isLast ? radius : 0,
            topTrailingRadius: isFirst ? radius : 0
        )
        VStack(alignment: .leading, spacing: TokenSpacing._2) {
            if let language {
                Text(language)
                    .font(.caption)
                    .foregroundStyle(theme.codeLanguageColor)
                    .padding(.horizontal, TokenSpacing._4)
            }
            content
        }
        .padding(.top, isFirst ? TokenSpacing._4 : 0)
        .padding(.bottom, isLast ? TokenSpacing._4 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Code is written left to right, also in a right-to-left layout. See DECISIONS.md.
        .environment(\.layoutDirection, .leftToRight)
        .background(theme.codeBlockBackground, in: shape)
    }
}
