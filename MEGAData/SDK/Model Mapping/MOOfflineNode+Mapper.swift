
extension OfflineFileEntity {
    init(with offlineNode: MOOfflineNode) {
        self.base64Handle = offlineNode.base64Handle
        self.localPath = offlineNode.localPath
        self.parentBase64Handle = offlineNode.parentBase64Handle
        self.fingerprint = offlineNode.fingerprint
        self.timestamp = offlineNode.downloadedDate
    }
}
