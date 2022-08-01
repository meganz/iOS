import Foundation
import MEGADomain

protocol FileSystemRepositoryProtocol: RepositoryProtocol {
    func documentsDirectory() -> URL
    func fileExists(at url: URL) -> Bool
    func systemVolumeAvailability() -> Int64
    func moveFile(at sourceURL: URL, to destinationURL: URL, name: String) -> Bool
    func copyFile(at sourceURL: URL, to destinationURL: URL, name: String) -> Bool
    func removeFile(at url: URL)
    func fileSize(at url: URL) -> UInt64?
    func fileCreationDate(at url: URL) -> Date?
}
