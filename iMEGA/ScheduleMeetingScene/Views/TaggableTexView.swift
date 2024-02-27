import SwiftUI

// A Text view wrapper that can style [A]...[/A] tag-surrounded text with the provided linkColor
struct TaggableText: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var text: String
    var linkColor: (ColorScheme) -> UIColor
    
    init(_ text: String, linkColor: @escaping (ColorScheme) -> UIColor) {
        self.text = text
        self.linkColor = linkColor
    }
    
    var body: some View {
        Text(text.createAttributedStringForAccentTags(linkColor: { linkColor(colorScheme) }))
    }
}
