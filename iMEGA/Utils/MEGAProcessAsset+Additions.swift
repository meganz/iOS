import MEGASwift

extension MEGAProcessAsset {
    @objc func generateUniqueFilePath(from originalFilePath: String, allFilePaths: [String]) -> String {
        guard containsFilename(originalFilePath.lastPathComponent, in: allFilePaths) else {
            return originalFilePath
        }

        let originalURL = URL(fileURLWithPath: originalFilePath)
        let directory = originalURL.deletingLastPathComponent()
        let baseName = originalURL.deletingPathExtension().lastPathComponent
        let fileExtension = originalURL.pathExtension

        var candidateFileName = originalURL.lastPathComponent
        var counter = 1

        while containsFilename(candidateFileName, in: allFilePaths) {
            let newFileName = "\(baseName)_\(counter)" + (fileExtension.isEmpty ? "" : ".\(fileExtension)")
            candidateFileName = newFileName
            counter += 1
        }

        let uniqueFileURL = directory.appendingPathComponent(candidateFileName)
        MEGALogDebug("final file: \(uniqueFileURL.path)")
        return uniqueFileURL.path
    }

    private func containsFilename(_ filename: String, in paths: [String]) -> Bool {
        paths.contains { $0.lastPathComponent == filename }
    }
}
