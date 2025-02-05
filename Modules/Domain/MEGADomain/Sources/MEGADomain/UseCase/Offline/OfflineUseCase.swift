import Foundation

public protocol OfflineUseCaseProtocol: Sendable {
    /// Returns the relative path to the documents directory for the given URL.
    /// - Parameter url: The URL for which to get the relative path.
    /// - Returns: The relative path to the documents directory.
    ///
    /// - Note: for example, if the url is file:///var/mobile/Containers/Data/Application/33596B80-2A8D-4296-8361-46C6AF0A246C/Documents/A/file.txt
    /// this method returns A/file.txt
    func relativePathToDocumentsDirectory(for url: URL) -> String
    
    /// Removes the item at the specified URL (async version)
    /// - Parameter url: The URL of the item to remove.
    func removeItem(at url: URL) async throws
    
    /// Removes all offline files stored in the offline directory.
    ///
    /// This method deletes all files and folders within the offline directory, ensuring no offline data remains.
    func removeAllOfflineFiles() async throws
    
    /// Removes all stored offline nodes from the local database.
    ///
    /// This method clears all records of offline nodes stored in the local database using `MEGAStore`,
    /// but it does not delete the actual files from disk.
    func removeAllStoredFiles()
    
    /// Computes the total size of all offline files.
    ///
    /// This method calculates the cumulative size (in bytes) of all files stored in the offline directory.
    ///
    /// - Returns: The total size of offline files in bytes.
    func offlineSize() -> UInt64
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
        guard let offlineDirectoryURL = fileSystemRepository.offlineDirectoryURL() else { return }
        try await fileSystemRepository.removeFolderContents(atURL: offlineDirectoryURL)
    }
    
    public func removeAllStoredFiles() {
        offlineFilesRepository.removeAllStoredOfflineNodes()
    }
    
    public func offlineSize() -> UInt64 {
        offlineFilesRepository.offlineSize()
    }
}
