
struct OfflineFileEntity: Equatable {
    let base64Handle: String
    let localPath: String
    let parentBase64Handle: String?
    let fingerprint: String?
    let timestamp: Date?
}
