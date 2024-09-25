import Foundation
import MEGADesignToken

extension AttributedString {
    public func convertURLsToClickableLinks() -> AttributedString {
        var attributedString = self
        let string = String(attributedString.description)
        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) ?? []
        
        for match in matches {
            if let range = Range(match.range, in: string), let url = match.url {
                if let attributedRange = Range(range, in: attributedString) {
                    attributedString[attributedRange].link = url
                    attributedString[attributedRange].foregroundColor = TokenColors.Link.primary
                }
            }
        }
        
        return attributedString
    }
    
    public func applyBoldFormattingFromHTMLTags() -> AttributedString {
        var attributedString = self
        var string = String(attributedString.characters)
        
        while let startRange = string.range(of: "<b>"),
              let endRange = string.range(of: "</b>", range: startRange.upperBound..<string.endIndex) {
            let textRange = startRange.upperBound..<endRange.lowerBound
            var boldText = AttributedString(string[textRange])
            boldText.inlinePresentationIntent = .stronglyEmphasized
            
            let startOffset = string.distance(from: string.startIndex, to: startRange.lowerBound)
            let endOffset = string.distance(from: string.startIndex, to: endRange.upperBound)
            
            let attributedStartIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: startOffset)
            let attributedEndIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: endOffset)
            
            let attributedFullRange = attributedStartIndex..<attributedEndIndex
            attributedString.replaceSubrange(attributedFullRange, with: boldText)
            
            string = String(attributedString.characters)
        }
        
        return attributedString
    }
    
    public func toNSAttributedString() -> NSAttributedString {
        NSAttributedString(self)
    }
}
