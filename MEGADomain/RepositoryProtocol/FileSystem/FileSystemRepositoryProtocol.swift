import Foundation

protocol FileSystemRepositoryProtocol {
    func fileExists(at url: URL) -> Bool
    func systemVolumeAvailability() -> Int64
    func moveFile(at sourceURL: URL, to destinationURL: URL, name: String) -> Bool
    func copyFile(at sourceURL: URL, to destinationURL: URL, name: String) -> Bool
    func removeFile(at url: URL)
}
