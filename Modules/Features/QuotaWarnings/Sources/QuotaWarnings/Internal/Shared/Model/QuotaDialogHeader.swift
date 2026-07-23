import MEGAUIComponent
import SwiftUI

struct QuotaDialogHeader {
    let image: Image
    let title: String
    let subtitle: QuotaDialogSubtitle
}

/// A dialog subtitle: either plain text, or text with inline tappable link substrings (e.g. the "Learn more" or "mega.io")
enum QuotaDialogSubtitle {
    case plain(String)
    case attributed(text: String, links: [SubstringAttribute])

    /// The subtitle's display text, regardless of case.
    var text: String {
        switch self {
        case .plain(let text): text
        case .attributed(let text, _): text
        }
    }

    /// The inline link substrings; empty for `.plain`.
    var links: [SubstringAttribute] {
        switch self {
        case .plain: []
        case .attributed(_, let links): links
        }
    }
}
