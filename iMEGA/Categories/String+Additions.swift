import MEGASwift

extension String {
    
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var base64URLDecoded: String? {
        return base64URLToBase64.base64Decoded
    }

    // Conversion of base64-URL to base64 https://stackoverflow.com/questions/43499651/decode-base64url-to-base64-swift
    var base64URLToBase64: String {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }

    var trim: String? {
        let trimmedString = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedString.isNotEmpty ? trimmedString : nil
    }

    var mnz_isDecimalNumber: Bool {
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    func append(pathComponent: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(pathComponent).path
    }
    
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
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    
        return ceil(boundingBox.height)
    }
}
