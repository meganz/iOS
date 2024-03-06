import SwiftUI

// A Text view wrapper that can style [A]...[/A] tag-surrounded text with the provided linkColor
struct TaggableText: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var text: String
    var underline: Bool
    var linkColor: (ColorScheme) -> UIColor
    
    init(_ text: String, underline: Bool, linkColor: @escaping (ColorScheme) -> UIColor) {
        self.text = text
        self.underline = underline
        self.linkColor = linkColor
    }
    
    var processedText: AttributedString {
        text.createAttributedStringForAccentTags(
            linkColor: { linkColor(colorScheme) },
            underline: underline
        )
    }
    
    var body: some View {
        Text(processedText)
    }
}

struct TaggableText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TaggableText(
                "Some interesting long copy with a [A]LINK[/A]",
                underline: false,
                linkColor: { _ in .red }
            )
            .foregroundColor(.blue)
            .colorScheme(.light)
            
            TaggableText(
                "Some interesting long copy with a [A]LINK[/A]",
                underline: true,
                linkColor: { _ in .blue }
            )
            .foregroundColor(.black)
            .colorScheme(.light)
        }
        .previewLayout(.sizeThatFits)
    }
}
