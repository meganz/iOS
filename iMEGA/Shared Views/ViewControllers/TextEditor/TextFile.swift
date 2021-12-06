@objc final class TextFile: NSObject {
    static let maxEditableFileSize: UInt64 = 300 * 1024 * 1024
    
    var fileName: String
    var content: String
    var size: UInt64
    var encode: String.Encoding.RawValue
    
    @objc init(fileName: String, content: String, size: UInt64, encode: String.Encoding.RawValue) {
        self.fileName = fileName
        self.content = content
        self.size = size
        self.encode = encode
    }
    
    @objc convenience init(fileName: String, size: UInt64) {
        self.init(fileName: fileName, content: "", size: 0, encode: String.Encoding.utf8.rawValue)
    }
    
    convenience init(fileName: String) {
        self.init(fileName: fileName, content: "", size: 0, encode: String.Encoding.utf8.rawValue)
    }
}
