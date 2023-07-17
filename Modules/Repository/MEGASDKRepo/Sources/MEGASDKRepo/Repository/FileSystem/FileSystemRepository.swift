import Foundation
import MEGADomain
import MEGASwift

public struct FileSystemRepository: FileSystemRepositoryProtocol {
    public static var newRepo: FileSystemRepository {
        FileSystemRepository(fileManager: .default)
    }
    
    private let fileManager: FileManager
    
    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    public func documentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = URL(string: paths[0].lastPathComponent) else { return paths[0] }
        return documentsDirectory
    }
    
    public func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    public func systemVolumeAvailability() -> Int64 {
        let homeUrl = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try homeUrl.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return capacity
            }
        } catch {
            return 0
        }
        
        return 0
    }
    
    public func moveFile(at sourceURL: URL, to destinationURL: URL) -> Bool {
        do {
            if fileExists(at: destinationURL) {
                return true
            }
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            return false
        }
    }
    
    public func copyFile(at sourceURL: URL, to destinationURL: URL) -> Bool {
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            return false
        }
    }
        
    public func removeFile(at url: URL) {
        try? fileManager.removeItem(at: url)
    }
    
    // MARK: - File attributes
    public func fileSize(at url: URL) -> UInt64? {
        url.attributes?[.size] as? UInt64
    }
    
    public func fileCreationDate(at url: URL) -> Date? {
        url.attributes?[.creationDate] as? Date
    }
}
