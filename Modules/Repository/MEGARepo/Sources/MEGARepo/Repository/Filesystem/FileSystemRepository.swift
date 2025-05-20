import Foundation
import MEGADomain
import MEGASwift

public struct FileSystemRepository: FileSystemRepositoryProtocol {
    public static let sharedRepo = FileSystemRepository(fileManager: .default)
    
    private let fileManager: FileManager
    private let documentsDirectoryURL: URL
    private let queue = DispatchQueue(label: "nz.mega.MEGARepo.FileSystemRepository")
    
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
