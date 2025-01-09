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
    
    /// Removes all offline files stored in the offline directory.
    ///
    /// This method deletes all files and folders within the offline directory, ensuring no offline data remains.
    func removeAllOfflineFiles() async throws
}

public struct OfflineUseCase: OfflineUseCaseProtocol {
    private let fileSystemRepository: any FileSystemRepositoryProtocol
    private let offlineFilesRepository: any OfflineFilesRepositoryProtocol
    
    public init(
        fileSystemRepository: some FileSystemRepositoryProtocol,
        offlineFilesRepository: some OfflineFilesRepositoryProtocol
    ) {
        self.fileSystemRepository = fileSystemRepository
        self.offlineFilesRepository = offlineFilesRepository
    }
    
    public func relativePathToDocumentsDirectory(for url: URL) -> String {
        fileSystemRepository.relativePathToDocumentsDirectory(for: url)
    }
    
    public func removeItem(at url: URL) async throws {
        try await fileSystemRepository.removeItem(at: url)
    }
    
    public func removeAllOfflineFiles() async throws {
        try await fileSystemRepository.removeFolderContents(atURL: fileSystemRepository.documentsDirectory())
        
        offlineFilesRepository.removeAllStoredOfflineNodes()
    }
}
