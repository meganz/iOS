@objc extension NSString {
    static let byteCountFormatter = ByteCountFormatter()

    static func memoryStyleString(fromByteCount byteCount: Int64) -> String {
        byteCountFormatter.countStyle = .memory
        
        return byteCountFormatter.string(fromByteCount: byteCount)
    }
}
