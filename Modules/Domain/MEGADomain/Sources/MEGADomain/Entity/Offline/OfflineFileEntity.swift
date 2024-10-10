import Foundation

public struct OfflineFileEntity: Equatable, Sendable {
    public let base64Handle: String
    public let localPath: String
    let parentBase64Handle: String?
    let fingerprint: String?
    let timestamp: Date?
    
    public init(
        base64Handle: String,
        localPath: String,
        parentBase64Handle: String?,
        fingerprint: String?,
        timestamp: Date?
    ) {
        self.base64Handle = base64Handle
        self.localPath = localPath
        self.parentBase64Handle = parentBase64Handle
        self.fingerprint = fingerprint
        self.timestamp = timestamp
    }
}
