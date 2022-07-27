import Foundation

struct FileSystemRepository: FileSystemRepositoryProtocol {
    static var newRepo: FileSystemRepository {
        FileSystemRepository(fileManager: .default)
    }
    
    private let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    func documentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = URL(string: paths[0].lastPathComponent) else { return paths[0] }
        return documentsDirectory
    }
    
    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    func systemVolumeAvailability() -> Int64 {
        let homeUrl = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try homeUrl.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return capacity
            }
        } catch {
            MEGALogError("Error retrieving volume availability: \(error.localizedDescription)")
        }
        
        return 0
    }
    
    func moveFile(at sourceURL: URL, to destinationURL: URL, name: String) -> Bool {
        do {
            if fileExists(at: destinationURL) {
                return true
            }
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return true
        } catch let error as NSError {
            MEGALogError("Failed to move upload temp file to uploads folder with error: \(error)")
            return false
        }
    }
    
    func copyFile(at sourceURL: URL, to destinationURL: URL, name: String) -> Bool {
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return true
        } catch let error as NSError {
            MEGALogError("Failed to copy temp file to documents folder with error: \(error)")
            return false
        }
    }
        
    func removeFile(at url: URL) {
        do {
            try fileManager.removeItem(at: url)
        } catch let error as NSError {
            MEGALogError("Failed to remove upload temp file in uploads folder with error: \(error)")
        }
    }
    
    //MARK: - File attributes
    func fileSize(at url: URL) -> UInt64? {
        url.attributes?[.size] as? UInt64
    }
    
    func fileCreationDate(at url: URL) -> Date? {
        url.attributes?[.creationDate] as? Date
    }
}
