import MEGADesignToken
import SwiftUI

/// The thematic break line. Inside a list item or a quote it gets less space around it.
package struct MarkdownDivider: View {
    let nested: Bool

    @Environment(\.markdownTheme) private var theme

    package init(nested: Bool) {
        self.nested = nested
    }

    package var body: some View {
        Rectangle()
            .fill(theme.dividerColor)
            .frame(height: MarkdownBlockView.dividerHeight)
            .padding(.vertical, nested ? TokenSpacing._2 : TokenSpacing._3)
    }
}
