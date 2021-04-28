@objc final class TextFile: NSObject {
    var fileName: String
    var content: String
    
    @objc init(fileName: String, content: String) {
        self.fileName = fileName
        self.content = content
    }
    
    @objc convenience init(fileName: String) {
        self.init(fileName: fileName, content: "")
    }
}
