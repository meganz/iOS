import UIKit

public extension String {
    func replace(tag: String, withFont: UIFont, originalFont: UIFont) -> NSAttributedString {
        let openTag = "<\(tag)>"
        let closeTag = "</\(tag)>"
        let attributedString = NSMutableAttributedString(string: self, attributes: [NSAttributedString.Key.font: originalFont])
        while true {
            let plainString = attributedString.string as NSString
            let openTagRange = plainString.range(of: openTag)
            if openTagRange.length == 0 {
                break
            }
            
            let affectedLocation = openTagRange.location + openTagRange.length
            let searchRange = NSMakeRange(affectedLocation, plainString.length - affectedLocation)
            let closeTagRange = plainString.range(of: closeTag, options: NSString.CompareOptions(), range: searchRange)
            
            attributedString.setAttributes([NSAttributedString.Key.font: withFont], range: NSMakeRange(affectedLocation, closeTagRange.location - affectedLocation))
            attributedString.deleteCharacters(in: closeTagRange)
            attributedString.deleteCharacters(in: openTagRange)
        }
        return attributedString as NSAttributedString
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
}
