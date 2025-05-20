import Foundation

public protocol FileSystemRepositoryProtocol: SharedRepositoryProtocol {
    /// Retrieves the URL of the documents directory in the user's domain.
    /// - Returns: A `URL` pointing to the documents directory.
    func documentsDirectory() -> URL
    /// Checks whether a file exists at the specified URL.
    /// - Parameter url: The URL of the file to check.
    /// - Returns: A boolean indicating whether the file exists.
    func fileExists(at url: URL) -> Bool
    /// Moves a file from the source URL to the destination URL.
    /// - Parameters:
    ///   - sourceURL: The source URL of the file to move.
    ///   - destinationURL: The destination URL to move the file to.
    /// - Returns: A boolean indicating whether the file was successfully moved.
    ///   If the file already exists at the destination, the function returns `true` without performing the move.
    func moveFile(at sourceURL: URL, to destinationURL: URL) -> Bool
    /// Copies a file from the source URL to the destination URL.
    /// - Parameters:
    ///   - sourceURL: The source URL of the file to copy.
    ///   - destinationURL: The destination URL to copy the file to.
    /// - Returns: A boolean indicating whether the file was successfully copied.
    func copyFile(at sourceURL: URL, to destinationURL: URL) -> Bool
    /// Removes an item at the specified URL.
    /// - Parameter url: The URL of the item to remove.
    /// - Throws: An error if the removal fails.
    func removeItem(at url: URL) throws
    /// Removes an item at the specified URL asynchronously.
    /// - Parameter url: The URL of the item to remove.
    /// - Throws: An error if the removal fails.
    func removeItem(at url: URL) async throws
    /// Removes all contents of a folder at the specified url asynchronously.
    /// - Parameter url: The url of the folder whose contents will be removed.
    /// - Throws: An error if the removal of any item fails.
    func removeFolderContents(atURL url: URL) async throws
    /// Retrieves the size of a file at the specified URL.
    /// - Parameter url: The URL of the file.
    /// - Returns: The size of the file in bytes, or `nil` if the size could not be retrieved.
    func fileSize(at url: URL) -> UInt64?
    /// Retrieves the creation date of a file at the specified URL.
    /// - Parameter url: The URL of the file.
    /// - Returns: The creation date of the file, or `nil` if the date could not be retrieved.
    func fileCreationDate(at url: URL) -> Date?
    /// Returns the relative path of a file or folder with respect to the documents directory.
    /// - Parameter url: The absolute URL of the file or folder.
    /// - Returns: A string representing the relative path, or an empty string if the documents directory could not be determined.
    func relativePathToDocumentsDirectory(for url: URL) -> String
    /// Retrieves the URL of the offline directory where offline files are stored.
    /// - Returns: A `URL` representing the absolute path of the offline directory,
    ///   or `nil` if the directory cannot be determined.
    func offlineDirectoryURL() -> URL?
}
