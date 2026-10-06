import MEGADesignToken
import SwiftUI

/// Text styles from the design. `package`, so other targets of this package use the same styles.
package enum MarkdownStyleSpec {
    /// Figma: H1 Title 2 bold, H2 Title 3 semibold, H3 Headline. H4 to H6 are not designed, so they stay below H3.
    package static func heading(_ level: Int) -> (style: Font.TextStyle, weight: Font.Weight) {
        switch level {
        case 1: (.title2, .bold)
        case 2: (.title3, .semibold)
        case 3: (.headline, .semibold)
        case 4: (.subheadline, .semibold)
        case 5: (.footnote, .semibold)
        default: (.caption, .semibold)
        }
    }

    package static func headingFont(_ level: Int) -> Font {
        let spec = heading(level)
        return .system(spec.style, weight: spec.weight)
    }

    package static let quoteBarWidth = TokenSpacing._2
    package static let quoteBarRadius = TokenRadius.extraSmall
}
