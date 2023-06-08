extension CompressingLogFileManager {
    @objc func deleteOldestFilesIfNeeded() {
        do {
            let logDirectoryUrl = URL(fileURLWithPath: logsDirectory)
            let files = try FileManager.default.contentsOfDirectory(at: logDirectoryUrl,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                .filter { $0.lastPathComponent.hasSuffix(".gz") }
                .sorted(by: {
                    guard let date0 = try $0.promisedItemResourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                          let date1 = try $1.promisedItemResourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                        return false
                    }
                    return date0.compare(date1) == .orderedAscending
                })

            if files.count > maximumNumberOfLogFiles {
                let filesToRemoveCount = files.count - Int(maximumNumberOfLogFiles)
                let filesToBeRemoved = Array(files.prefix(filesToRemoveCount))
                for fileUrl in filesToBeRemoved {
                    do {
                        try FileManager.default.removeItem(at: fileUrl)
                    } catch {
                        MEGALogError("Remove item \(fileUrl) failed with \(error)")
                    }
                }
            }
        } catch {
            MEGALogError("Getting content of \(logsDirectory) failed with \(error)")
        }
    }
}
