extension OfflineViewController {
    @objc func removeLogFromSharedSandboxIfNeeded(path: String) {
        removeLogFromSharedSandbox(path: path, extensionLogName: documentProviderLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: fileProviderLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: shareExtensionLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: notificationServiceExtensionLog)
    }
    
    private func removeLogFromSharedSandbox(path: String, extensionLogName: String) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/")
        let extensionLogFile = documentsPath?.append(pathComponent: extensionLogName)
        if extensionLogFile == path {
            do {
                try FileManager.default.removeItem(atPath: logsPath.append(pathComponent: extensionLogName))
            } catch {
                MEGALogError("[File manager] remove item at path failed with error \(error)")
            }
        }
    }
}
