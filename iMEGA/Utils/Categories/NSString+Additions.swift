
@objc extension NSString {
    static var byteCountFormatter = ByteCountFormatter()

    @objc static func memoryStyleString(fromByteCount byteCount: Int64) -> String {
        byteCountFormatter.countStyle = .memory
        
        return byteCountFormatter.string(fromByteCount: byteCount)
    }
}
