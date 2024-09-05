import Foundation
import MEGADomain
import MEGASwift

public struct FileSystemRepository: FileSystemRepositoryProtocol {
    public static var newRepo: FileSystemRepository {
        FileSystemRepository(fileManager: .default)
    }
    
    private let fileManager: FileManager
    private static var cachedDocumentDirectoryURL: URL?
    private let queue = DispatchQueue(label: "nz.mega.MEGARepo.FileSystemRepository")
    
    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    public func documentsDirectory() -> URL {
        if let cachedURL = FileSystemRepository.cachedDocumentDirectoryURL {
            return cachedURL
        } else {
            let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            
            guard let documentsDirectory = URL(string: paths[0].lastPathComponent) else {
                FileSystemRepository.cachedDocumentDirectoryURL = paths[0]
                return paths[0]
            }

            FileSystemRepository.cachedDocumentDirectoryURL = documentsDirectory
            return documentsDirectory
        }
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
    
    // MARK: - Private
    
    private func removeItemAsync(at url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
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
