import SwiftUI

// A Text view wrapper that can style [A]...[/A] tag-surrounded text with the provided linkColor
struct TaggableText: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var text: String
    var underline: Bool
    var tappable: Bool
    var linkColor: UIColor
    
    init(
        _ text: String,
        underline: Bool,
        tappable: Bool = false,
        linkColor: UIColor
    ) {
        self.text = text
        self.underline = underline
        self.linkColor = linkColor
        self.tappable = tappable
    }
    
    var processedText: AttributedString {
        text.createAttributedStringForAccentTags(
            linkColor: linkColor,
            underline: underline,
            tappable: tappable
        )
    }
    
    var body: some View {
        Text(processedText)
    }
}

#Preview {
    VStack {
        TaggableText(
            "Some interesting long copy with a [A]LINK[/A]",
            underline: false,
            linkColor: .red
        )
        .foregroundColor(.blue)
        .colorScheme(.light)
        
        TaggableText(
            "Some interesting long copy with a [A]LINK[/A]",
            underline: true,
            linkColor: .blue
        )
        .foregroundColor(.black)
        .colorScheme(.light)
    }
}
