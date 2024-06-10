import SwiftUI

enum StepType {
    case text(String)
    case linkText(String)
}

struct Step {
    let text: String
    
    var attributedText: AttributedString {
        var attributedString = AttributedString(text)
        
        // Apply link formatting
        attributedString = Step.applyLinks(from: attributedString)
        
        // Apply bold formatting
        attributedString = Step.applyBoldFormatting(to: attributedString)
        
        return attributedString
    }
    
    init(content: String) {
        self.text = content
    }
    
    private static func applyLinks(from attributedString: AttributedString) -> AttributedString {
        var attributedString = attributedString
        let string = String(attributedString.description)
        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) ?? []
        
        for match in matches {
            if let range = Range(match.range, in: string), let url = match.url {
                if let attributedRange = Range(range, in: attributedString) {
                    attributedString[attributedRange].link = url
                }
            }
        }
        
        return attributedString
    }
    
    private static func applyBoldFormatting(to attributedString: AttributedString) -> AttributedString {
        var attributedString = attributedString
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
}
