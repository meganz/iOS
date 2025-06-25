public struct LogMetadataEntity: Sendable, Equatable {
    public let suiteName: String
    public let key: String
    public let version: String
    public let systemVersion: String
    public let language: String
    public let deviceName: String
    public let timezoneName: String
    public let extensionLogsFolder: String
    
    public init(
        suiteName: String,
        key: String,
        version: String,
        systemVersion: String,
        language: String,
        deviceName: String,
        timezoneName: String,
        extensionLogsFolder: String
    ) {
        self.suiteName = suiteName
        self.key = key
        self.version = version
        self.systemVersion = systemVersion
        self.language = language
        self.deviceName = deviceName
        self.timezoneName = timezoneName
        self.extensionLogsFolder = extensionLogsFolder
    }
}
