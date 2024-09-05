import Foundation

public protocol FileSystemRepositoryProtocol: RepositoryProtocol, Sendable {
    func documentsDirectory() -> URL
    func fileExists(at url: URL) -> Bool
    func moveFile(at sourceURL: URL, to destinationURL: URL) -> Bool
    func copyFile(at sourceURL: URL, to destinationURL: URL) -> Bool
    func removeItem(at url: URL) throws
    func removeItem(at url: URL) async throws
    func fileSize(at url: URL) -> UInt64?
    func fileCreationDate(at url: URL) -> Date?
    func relativePathToDocumentsDirectory(for url: URL) -> String
}
