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
    
    @available(iOS 15, *)
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
        if #available(iOS 15, *) {
            Text(linkAttributedText)
        } else {
            LabelTextWithLinkString(details: details)
                .foregroundColor(Color.red)
        }
    }
}

// MARK: - Attributed String for iOS 14 and below
struct LabelTextWithLinkString: UIViewRepresentable {
    var details: TextWithLinkDetails

    private var linkAttributedText: NSAttributedString {
        let attributedString = NSMutableAttributedString(
            string: details.fullText,
            attributes: [.foregroundColor: UIColor(details.textColor)]
        )

        guard let urlLink = URL(string: details.linkString) else { return attributedString }
        let range = NSString(string: details.fullText).range(of: details.tappableText)
        attributedString.addAttributes(
            [.foregroundColor: UIColor(details.linkColor), .link: urlLink],
            range: range
        )
        return attributedString
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.attributedText = linkAttributedText
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {}
}
