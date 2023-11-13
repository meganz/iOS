import SwiftUI

public struct TextWithLinkDetails {
    public var fullText: String
    public var tappableText: String
    public var linkString: String
    public var textColor: Color
    public var linkColor: Color
    
    public init(fullText: String, tappableText: String, linkString: String, textColor: Color, linkColor: Color) {
        self.fullText = fullText
        self.tappableText = tappableText
        self.linkString = linkString
        self.textColor = textColor
        self.linkColor = linkColor
    }
}

public struct TextWithLinkView: View {
    private let details: TextWithLinkDetails
    
    public init(details: TextWithLinkDetails) {
        self.details = details
    }
    
    private var linkAttributedText: AttributedString {
        var attributedString = AttributedString(details.fullText)
        attributedString.foregroundColor = details.textColor
        
        guard let rangeOfLinkText = attributedString.range(of: details.tappableText),
              let urlLink = URL(string: details.linkString) else {
            return attributedString
        }
    
        let linkAttr = AttributeContainer.foregroundColor(details.linkColor)
        attributedString[rangeOfLinkText].link = urlLink
        attributedString[rangeOfLinkText].mergeAttributes(linkAttr)
        
        return attributedString
    }
    
    public var body: some View {
        Text(linkAttributedText)
    }
}
