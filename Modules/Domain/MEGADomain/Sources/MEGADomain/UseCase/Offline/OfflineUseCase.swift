import Foundation

public protocol OfflineUseCaseProtocol: Sendable {
    /// Returns the relative path to the documents directory for the given URL.
    /// - Parameter url: The URL for which to get the relative path.
    /// - Returns: The relative path to the documents directory.
    ///
    /// - Note: for example, if the url is file:///var/mobile/Containers/Data/Application/33596B80-2A8D-4296-8361-46C6AF0A246C/Documents/A/file.txt
    /// this method returns A/file.txt
    ///
    func relativePathToDocumentsDirectory(for url: URL) -> String
    
    /// Removes the item at the specified URL (async version)
    /// - Parameter url: The URL of the item to remove.
    func removeItem(at url: URL) async throws
}

public struct OfflineUseCase<T: FileSystemRepositoryProtocol>: OfflineUseCaseProtocol {
    
    private let fileSystemRepository: T
    
    public init(fileSystemRepository: T) {
        self.fileSystemRepository = fileSystemRepository
    }
    
    public func relativePathToDocumentsDirectory(for url: URL) -> String {
        fileSystemRepository.relativePathToDocumentsDirectory(for: url)
    }
    
    public func removeItem(at url: URL) async throws {
        try await fileSystemRepository.removeItem(at: url)
    }
}
