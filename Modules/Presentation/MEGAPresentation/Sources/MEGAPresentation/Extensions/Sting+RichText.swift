import UIKit

extension String {
    public func createAttributedStringForAccentTags(
        linkColor: () -> UIColor
    ) -> AttributedString {
        var attributedString = AttributedString(self)
        
        guard let rangeStart = attributedString.range(of: "[A]"),
              let rangeEnd = attributedString.range(of: "[/A]", options: .backwards),
              rangeEnd.lowerBound > rangeStart.upperBound else {
            return attributedString
        }
        let startIndex = attributedString.index(rangeStart.upperBound, offsetByCharacters: 0)
        let endIndex = attributedString.index(rangeEnd.lowerBound, offsetByCharacters: 0)
        let substringRange = startIndex..<endIndex
        attributedString[substringRange].foregroundColor = linkColor()
        
        attributedString.removeSubrange(rangeEnd)
        attributedString.removeSubrange(rangeStart)
        
        return attributedString
    }
}
