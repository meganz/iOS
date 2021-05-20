@objc final class TextFile: NSObject {
    var fileName: String
    var content: String
    var encode: String.Encoding.RawValue
    
    @objc init(fileName: String, content: String, encode: String.Encoding.RawValue) {
        self.fileName = fileName
        self.content = content
        self.encode = encode
    }
    
    @objc convenience init(fileName: String) {
        self.init(fileName: fileName, content: "", encode: String.Encoding.utf8.rawValue)
    }
}
