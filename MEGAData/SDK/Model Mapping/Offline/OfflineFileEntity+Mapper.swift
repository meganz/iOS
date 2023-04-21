import MEGADomain

extension MOOfflineNode {
    func toOfflineFileEntity() -> OfflineFileEntity {
        OfflineFileEntity(base64Handle: self.base64Handle,
                          localPath: self.localPath,
                          parentBase64Handle: self.parentBase64Handle,
                          fingerprint: self.fingerprint,
                          timestamp: self.downloadedDate)
    }
}
