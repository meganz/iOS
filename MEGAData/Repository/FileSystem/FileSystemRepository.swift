import Foundation

extension FileSystemRepository {
    static let `default` = FileSystemRepository(fileManager: .default)
}

struct FileSystemRepository: FileSystemRepositoryProtocol {
    private let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
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
}
