import Foundation

protocol FileSystemRepositoryProtocol {
    func fileExists(at url: URL) -> Bool
    func systemVolumeAvailability() -> Int64
}
