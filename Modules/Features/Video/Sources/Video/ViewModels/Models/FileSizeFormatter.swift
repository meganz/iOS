import Foundation

enum FileSizeFormatter {
    
    static func memoryStyleString(fromByteCount byteCount: Int64) -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .memory
        return byteCountFormatter.string(fromByteCount: byteCount)
    }
}
