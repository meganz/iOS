import MEGAChatSdk
import MEGADomain

struct AppLogger {
    private let logMetadata: LogMetadataEntity
    
    init(logMetadata: LogMetadataEntity) {
        self.logMetadata = logMetadata
    }
    
    func prepare() {
        MEGASdk.setLogLevel(.max)
        MEGAChatSdk.setLogLevel(.max)
        
        UserDefaults.standard.set(true, forKey: logMetadata.key)
        UserDefaults(suiteName: logMetadata.suiteName)?.set(true, forKey: logMetadata.key)

        MEGASdk.log(
            with: .info,
            message: "[iOS] Device information:\nVersion: \(logMetadata.version)\nDevice: \(logMetadata.deviceName)\niOS Version: \(logMetadata.systemVersion)\nLanguage: \(logMetadata.language)\nTimezone: \(logMetadata.timezoneName)"
        )
    }
    
    func stop() {
        if let documentDirectoryPath = documentDirectoryPath() {
            paths(for: logFolderAndFiles(), folder: documentDirectoryPath).forEach(remove(path:))
        }
        
        if let logsPath = logsPath(withExtensionLogsFolder: logMetadata.extensionLogsFolder, suiteName: logMetadata.suiteName) {
            paths(for: Array(logFolderAndFiles().dropFirst()), folder: logsPath).forEach(remove(path:))
        }
        
#if !DEBUG
        MEGASdk.setLogLevel(.fatal)
        MEGAChatSdk.setLogLevel(.fatal)
#endif
        
        UserDefaults.standard.set(false, forKey: logMetadata.key)
        UserDefaults(suiteName: logMetadata.suiteName)?.set(false, forKey: logMetadata.key)
    }
    
    // MARK: - Private methods.
    
    private func paths(for logs: [String], folder: String) -> [String] {
        logs.map { folder.append(pathComponent: $0) }
    }
    
    private func logsPath(withExtensionLogsFolder extensionLogsFolder: String, suiteName: String) -> String? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)?.appendingPathComponent(extensionLogsFolder).path()
    }
    
    private func documentDirectoryPath() -> String? {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
    
    private func remove(path: String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            MEGASdk.log(with: .error, message: "Remove item failed:\n- At path: \(path)\n- With error: \(error)")
        }
    }
    
    private func logFolderAndFiles() -> [String] {
        [
            "MEGAiOS",
            "MEGAiOS.docExt.log",
            "MEGAiOS.fileExt.log",
            "MEGAiOS.shareExt.log",
            "MEGAiOS.NSE.log"
        ]
    }
}
