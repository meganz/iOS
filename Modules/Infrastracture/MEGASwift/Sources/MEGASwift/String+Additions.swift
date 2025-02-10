import Foundation
import UIKit

public extension String {
    
    enum Constants {
        /// Inform the user about invalid characters used in file or folder names in the UI.
        public static let invalidFileFolderNameCharactersToDisplay = "” * / : < > ? \\ |"

        /// Pattern for checking the validity of entered file or folder names.
        public static let invalidFileFolderNameCharactersToMatch = "|*/:<>?\"\\"
    }
    
    var base64Encoded: String? {
        data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
    
    var base64DecodedData: Data? {
        Data(base64Encoded: addPaddingIfNecessaryForBase64String())
    }
    
    var base64Decoded: String? {
        guard let data = base64DecodedData else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var base64URLDecoded: String? {
        base64URLToBase64.base64Decoded
    }

    // Conversion of base64-URL to base64 https://stackoverflow.com/questions/43499651/decode-base64url-to-base64-swift
    var base64URLToBase64: String {
        replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .addPaddingIfNecessaryForBase64String()
    }

    var trim: String? {
        let trimmedString = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedString.isNotEmpty ? trimmedString : nil
    }

    var mnz_isDecimalNumber: Bool {
        CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }

    var containsInvalidFileFolderNameCharacters: Bool {
        rangeOfCharacter(from: CharacterSet(charactersIn: String.Constants.invalidFileFolderNameCharactersToMatch)) != nil
    }

    func append(pathComponent: String) -> String {
        URL(fileURLWithPath: self).appendingPathComponent(pathComponent).path
    }
  
    func initialForAvatar() -> String {
        guard let trimmedString = trim,
                trimmedString.isNotEmpty,
                let initialString = trimmedString.first else { return "" }
        return initialString.uppercased()
    }
    
    func addPaddingIfNecessaryForBase64String() -> String {
        var finalString = self
        
        if (finalString.count % 4) != 0 {
            finalString.append(String(repeating: "=", count: 4 - (finalString.count % 4)))
        }
        
        return finalString
    }
    
    var pathExtension: String {
        NSString(string: self).pathExtension.lowercased()
    }
    
    var lastPathComponent: String {
        NSString(string: self).lastPathComponent
    }
    
    func subString(from start: String, to end: String) -> String? {
        guard let startIndex = (range(of: start)?.upperBound).flatMap({$0}),
              let endIndex = (range(of: end, range: startIndex..<endIndex)?.lowerBound).map({$0}) else { return nil }
        return String(self[startIndex..<endIndex])
    }

    /// Checks if the given search text is contained within the current string,
    /// ignoring case and diacritic differences.
    ///
    /// This method performs a case-insensitive and diacritic-insensitive search,
    /// meaning it treats letters with accents (e.g., `é`) the same as their base form (e.g., `e`).
    ///
    /// - Parameter searchText: The text to search for in the current string.
    /// - Returns: A Boolean value indicating whether the `searchText` is contained within the string.
    ///
    /// ## Example
    /// ```swift
    /// let text = "Café au Lait"
    /// let result1 = text.containsIgnoringCaseAndDiacritics(searchText: "cafe") // true
    /// let result2 = text.containsIgnoringCaseAndDiacritics(searchText: "Au")   // true
    /// let result3 = text.containsIgnoringCaseAndDiacritics(searchText: "Latte") // false
    /// ```
    func containsIgnoringCaseAndDiacritics(searchText: String) -> Bool {
        return range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    /// Compute the attributed string for the the part matched with a keyword being highlighted
    /// - Parameters:
    ///   - keyword: The search keyword
    ///   - primaryTextColor: The color of the parts that are not matched
    ///   - highlightedTextColor: The color of the matched text
    ///   - normalBackgroundColor: The background color of the parts that are not matched
    ///   - normalFont: The font of the parts that are not matched
    ///   - highlightedFont: The font of the matched text
    /// - Returns: The attributed string with proper format
    func highlightedStringWithKeyword(
        _ keyword: String?,
        primaryTextColor: UIColor,
        highlightedTextColor: UIColor,
        normalBackgroundColor: UIColor? = nil,
        normalFont: UIFont? = nil,
        highlightedFont: UIFont? = nil
    ) -> NSAttributedString {
        let primaryTextColorAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: primaryTextColor,
            .backgroundColor: normalBackgroundColor,
            .font: normalFont
        ].compactMapValues { $0 }

        guard let keyword else {
            return .init(string: self, attributes: primaryTextColorAttr)
        }

        let highlightedColorAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: primaryTextColor,
            .backgroundColor: highlightedTextColor,
            .font: highlightedFont
        ].compactMapValues { $0 }

        let result = NSMutableAttributedString()
        var tmpSelf = self
        while let range = tmpSelf.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) {
            let beforeString = String(tmpSelf[tmpSelf.startIndex..<range.lowerBound])
            let attributedBefore = NSAttributedString(string: beforeString, attributes: primaryTextColorAttr)
            result.append(attributedBefore)

            let targetString = String(tmpSelf[range])
            let attributedRange = NSAttributedString(string: targetString, attributes: highlightedColorAttr)

            result.append(attributedRange)
            tmpSelf = String(tmpSelf[range.upperBound..<tmpSelf.endIndex])
        }
        let remainder = NSAttributedString(string: tmpSelf, attributes: primaryTextColorAttr)
        result.append(remainder)
        return result
    }
}

public extension String {
    func matches(regex: String) -> Bool {
        (self.range(of: regex, options: .regularExpression) ?? nil) != nil
    }
}

public extension String {
    nonisolated(unsafe) static var byteCountFormatter = ByteCountFormatter()
    
    /// Converts a byte count to a formatted string using memory style and ensures proper spacing between the count and unit.
    /// - Parameters:
    ///   - byteCount: The byte count to be formatted.
    ///   - includesUnit: A boolean indicating whether the unit should be included in the formatted string.
    /// - Returns: A combined formatted string representing the byte count with proper spacing.
    static func memoryStyleString(fromByteCount byteCount: Int64, includesUnit: Bool = true) -> String {
        byteCountFormatter.countStyle = .memory
        byteCountFormatter.includesUnit = includesUnit
        return byteCountFormatter.string(fromByteCount: byteCount)
    }

    /// Formats a string that represents a byte count by ensuring the count and unit are properly spaced.
    /// - Returns: A formatted string with properly spaced count and unit.
    func formattedByteCountString() -> String {
        let components = self.split(separator: " ")
        var countString = String.extractCount(fromComponents: components)
        
        if components.count > 1 {
            let unitString = String.extractUnit(fromComponents: components)
            countString = "\(countString) \(unitString)"
        }
        
        return countString
    }

    /// Extracts the count component from a byte count string.
    /// - Parameter components: The components of the byte count string.
    /// - Returns: The count component as a string.
    private static func extractCount(fromComponents components: [Substring]) -> String {
        let countString = String(components.first ?? "")
        if countString == "Zero" || countString.isEmpty {
            return "0"
        }
        return countString
    }

    /// Extracts the unit component from a byte count string.
    /// - Parameter components: The components of the byte count string.
    /// - Returns: The unit component as a string.
    private static func extractUnit(fromComponents components: [Substring]) -> String {
        if components.count > 1 {
            let unitCount = components[0]
            var unitString = components[1]

            if unitCount == "Zero" || unitCount == "0" || unitString == "bytes" || unitString.isEmpty {
                unitString = "B"
            }
            return String(unitString)
        }
        return "B"
    }
}

// MARK: - FileExtensionGroupDataSource
extension String: FileExtensionGroupDataSource {
    private var fileExtensionGroupKeyPath: String {
        guard isNotEmpty, let fileExt = lastPathComponent.split(separator: ".").last else {
            return self
        }
        return String(fileExt)
    }
    
    public static var fileExtensionPath: KeyPath<String, String> { \.fileExtensionGroupKeyPath }
}
