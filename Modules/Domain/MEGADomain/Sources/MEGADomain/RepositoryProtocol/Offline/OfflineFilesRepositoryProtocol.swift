import Foundation

public protocol OfflineFilesRepositoryProtocol: RepositoryProtocol, Sendable {
    /// The URL representing the path where offline files are stored.
    ///
    /// - Returns: A `URL` pointing to the offline files folder if available, or `nil` if the folder path is not set or invalid.
    var offlineURL: URL? { get }
    
    /// Creates an offline file with the specified name for a given node handle.
    ///
    /// This function is used to store metadata for an offline file in the underlying data store.
    /// - Parameters:
    ///   - name: The name of the offline file to be created.
    ///   - handle: The offline node identifier.
    func createOfflineFile(name: String, for handle: HandleEntity)
    
    /// Removes all stored offline nodes from the repository.
    ///
    /// This method clears all metadata for offline nodes stored in the underlying data store.
    /// It does not delete any actual files or folders from the offline directory.
    func removeAllStoredOfflineNodes()
    
    /// Computes the total size of all offline files.
    ///
    /// This method calculates the cumulative size (in bytes) of all files stored in the offline directory.
    ///
    /// - Returns: The total size of offline files in bytes.
    func offlineSize() -> UInt64
}
