public protocol LogSettingRepositoryProtocol: RepositoryProtocol, Sendable {
    func toggleLogs(enable: Bool, with logMetadata: LogMetadataEntity)
}
