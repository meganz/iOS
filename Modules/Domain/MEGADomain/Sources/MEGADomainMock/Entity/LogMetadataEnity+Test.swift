import MEGADomain

public extension LogMetadataEntity {
    init(
        suiteName: String = "",
        key: String = "",
        version: String = "",
        systemVersion: String = "",
        language: String = "",
        deviceName: String = "",
        timezoneName: String = "",
        extensionLogsFolder: String = "",
        isTesting: Bool = true,
    ) {
        self.init(
            suiteName: suiteName,
            key: key,
            version: version,
            systemVersion: systemVersion,
            language: language,
            deviceName: deviceName,
            timezoneName: timezoneName,
            extensionLogsFolder: extensionLogsFolder)
    }
}
