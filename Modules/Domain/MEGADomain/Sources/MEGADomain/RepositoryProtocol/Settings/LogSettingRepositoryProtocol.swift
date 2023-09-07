public protocol LogSettingRepositoryProtocol: RepositoryProtocol {
    func toggleLogs(enable: Bool, with logMetadata: LogMetadataEntity)
}
