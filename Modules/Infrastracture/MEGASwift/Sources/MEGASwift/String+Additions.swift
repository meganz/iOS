import Foundation

public extension String {
    
    enum Constants {
       public static let invalidFileFolderNameCharacters = "” * / : < > ? \\ |"
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
        return base64URLToBase64.base64Decoded
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
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    func append(pathComponent: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(pathComponent).path
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
}

public extension String {
    func matches(regex: String) -> Bool {
        return (self.range(of: regex, options: .regularExpression) ?? nil) != nil
    }
}

public extension String {
    static var byteCountFormatter = ByteCountFormatter()

    static func memoryStyleString(fromByteCount byteCount: Int64) -> String {
        byteCountFormatter.countStyle = .memory
        
        return byteCountFormatter.string(fromByteCount: byteCount)
    }
}
