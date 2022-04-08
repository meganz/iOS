import Foundation

@objc final class LogFileCompressor: NSObject {
    
    /// Compress sourceURL into a zip file in sandbox's temp directory
    /// - Note:. Ex: tmp/NSIRD\_MEGA\_UjbW10/filename.zip
    /// - Parameters:
    ///   - sourceURL: The source URL  you want to zip.
    ///   - filename: The filename of the compressed file.
    /// - Returns: The URL of the compressed file
    @objc func compressedFileURL(sourceURL: URL, toNewFilename filename: String = "MEGAiOSLogs.zip") -> URL? {
        var archiveUrl: URL?
        var error: NSError?
        
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: sourceURL, options: [.forUploading], error: &error) { (zipUrl) in
            guard let tmpUrl = try? FileManager.default.url(
                for: .itemReplacementDirectory,
                   in: .userDomainMask,
                   appropriateFor: zipUrl,
                   create: true
            ).appendingPathComponent(filename) else { return }
            try? FileManager.default.moveItem(at: zipUrl, to: tmpUrl)
            archiveUrl = tmpUrl
        }
        
        return archiveUrl
    }
    
    /// Get the Data of the compressed file located at the given URL
    /// - Parameters:
    ///   - url: The url of a compressed file
    /// - Returns: The Data of the compressed file located in the URL
    @objc func compressedData(url: URL) -> Data? {
        try? Data(contentsOf: url)
    }
}
