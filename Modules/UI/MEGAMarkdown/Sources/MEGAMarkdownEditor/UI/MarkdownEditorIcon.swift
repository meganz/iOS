import SwiftUI
import UIKit

/// Toolbar and menu icons from Figma, in `Resources/MarkdownEditorIcons.xcassets`.
/// The raw value is the image set name.
enum MarkdownEditorIcon: String, CaseIterable {
    case bold = "text-bold"
    case italic = "text-italic"
    case underline = "text-underline"
    case strikethrough = "text-strikethrough"
    case checklist = "checklist"
    case bulletList = "list-small"
    case numberedList = "list-numbers"
    case quote = "text-quote"
    case code = "code"
    case link = "url"
    case chevronDown = "chevron-down"
    case checkMenu = "check-menu"

    var image: Image {
        Image(rawValue, bundle: .module)
    }

    var uiImage: UIImage? {
        UIImage(named: rawValue, in: .module, with: nil)
    }
}
