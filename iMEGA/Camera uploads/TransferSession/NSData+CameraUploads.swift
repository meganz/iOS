import Foundation

extension NSData {
    @objc func isChunkUploadToken() -> Bool {
        guard length != 0 else {
            return true
        }
        
        guard let stringValue = String(data: self as Data, encoding: .utf8) else {
            return false
        }
        
        return Int(stringValue) == 0
    }
}
