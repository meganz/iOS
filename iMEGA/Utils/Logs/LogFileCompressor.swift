import Foundation

@objc final class LogFileCompressor: NSObject {
    
    /// Get data compressing source URL
    /// - Note: Compress sourceURL into a zip file in sandbox's temp directory and the get the data of zipped file. Ex: tmp/NSIRD\_MEGA\_UjbW10/MEGAiOSLogs.zip
    /// - Parameters:
    ///   - sourceURL: The source URL  you want to compress.
    /// - Returns: The data of the compressed file
    @objc func zippedData(from sourceURL: URL) -> NSData? {
        var archiveUrl: URL?
        var error: NSError?
        
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: sourceURL, options: [.forUploading], error: &error) { (zipUrl) in
            guard let tmpUrl = try? FileManager.default.url(
                for: .itemReplacementDirectory,
                   in: .userDomainMask,
                   appropriateFor: zipUrl,
                   create: true
            ).appendingPathComponent("MEGAiOSLogs.zip") else { return }
            try? FileManager.default.moveItem(at: zipUrl, to: tmpUrl)
            archiveUrl = tmpUrl
        }
        
        if let archiveUrl = archiveUrl {
            return NSData(contentsOfFile: archiveUrl.path)
        } else {
            MEGALogError(error?.localizedDescription ?? "")
            return nil
        }
    }
}
