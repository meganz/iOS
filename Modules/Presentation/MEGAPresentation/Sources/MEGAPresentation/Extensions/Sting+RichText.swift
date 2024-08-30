import UIKit

extension String {
    public func createAttributedStringForAccentTags(
        linkColor: () -> UIColor,
        underline: Bool,
        tappable: Bool = false
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
        let searchedString = attributedString[substringRange]
        let _searchedString = String(searchedString.characters[...])
        attributedString[substringRange].foregroundColor = linkColor()
        
        if underline {
            attributedString[substringRange].underlineStyle = .single
        }
    
        attributedString.removeSubrange(rangeEnd)
        attributedString.removeSubrange(rangeStart)
        
        if tappable {
            if let appendingInsertion = attributedString.range(of: _searchedString) {
                // this can be any link as it's intented to be intercepted and handled via OpenURLAction 
                // in the SwiftUI environment modifier
                attributedString[appendingInsertion].link = URL(string: "mega://link-tap")
            }
        }
        
        return attributedString
    }
}
