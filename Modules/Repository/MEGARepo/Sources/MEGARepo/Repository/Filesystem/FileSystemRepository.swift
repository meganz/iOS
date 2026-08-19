import Foundation
import MEGADomain
import MEGASwift

public struct FileSystemRepository: FileSystemRepositoryProtocol {
    public static let sharedRepo = FileSystemRepository(fileManager: .default)
    
    private let fileManager: FileManager
    private let documentsDirectoryURL: URL
    private let queue = DispatchQueue(label: "nz.mega.MEGARepo.FileSystemRepository")
    /// Kept apart from `queue`, and concurrent: walking a tree only reads, so it has nothing to be
    /// serialised against. Sharing the one queue would let a single large folder hold up every removal
    /// going through this repository, which is shared app wide, and which the exports running alongside
    /// it are waiting on to clear their staging copies before they can start downloading.
    private let readQueue = DispatchQueue(label: "nz.mega.MEGARepo.FileSystemRepository.read", attributes: .concurrent)
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.documentsDirectoryURL = if let url = URL(string: path.lastPathComponent) { url } else { path }
    }

    public func documentsDirectory() -> URL {
        documentsDirectoryURL
    }
    
    public func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
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
        
    public func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
    
    public func removeItem(at url: URL) async throws {
        try await withAsyncThrowingValue { completion in
            removeItemAsync(at: url) { result in
                completion(result)
            }
        }
    }
    
    public func removeFolderContents(atURL url: URL) async throws {
        let directoryContents = try fileManager.contentsOfDirectory(atPath: url.path)
        for item in directoryContents {
            let itemURL = url.appendingPathComponent(item)
            try await removeItem(at: itemURL)
        }
    }
    
    public func fileCount(at url: URL) async -> Int {
        await withAsyncValue { completion in
            // Off the caller's thread: a folder that was downloaded whole can hold thousands of files, and
            // walking them is disk work with no business blocking a cooperative thread.
            readQueue.async {
                completion(.success(self.countFiles(at: url)))
            }
        }
    }
    
    // MARK: - File attributes
    public func fileSize(at url: URL) -> UInt64? {
        url.attributes?[.size] as? UInt64
    }
    
    public func fileCreationDate(at url: URL) -> Date? {
        url.attributes?[.creationDate] as? Date
    }
    
    public func relativePathToDocumentsDirectory(for url: URL) -> String {
        guard let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return "" }
        let relativePath = url.path.replacingOccurrences(of: documentsDirectoryURL.path.appending("/"), with: "")
        return relativePath
    }
    
    public func offlineDirectoryURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    // MARK: - Private
    
    /// Walked with an enumerator rather than by recursing into `contentsOfDirectory`, which builds an array
    /// per directory and would hold a whole level of a large tree in memory at once.
    private func countFiles(at url: URL) -> Int {
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return 0 }
        guard isDirectory.boolValue else { return 1 }
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey]) else { return 0 }

        return enumerator.reduce(into: 0) { count, item in
            guard let itemURL = item as? URL,
                  let resourceValues = try? itemURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true else { return }
            count += 1
        }
    }
    
    private func removeItemAsync(at url: URL, completion: @Sendable @escaping (Result<Void, any Error>) -> Void) {
        queue.async {
            do {
                try FileManager.default.removeItem(at: url)
                completion(.success)
            } catch {
                completion(.failure(error))
            }
        }
    }
}
