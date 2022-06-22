import Foundation

protocol FileRepositoryProtocol {
    func fileExists(at url: URL) -> Bool
    func systemVolumeAvailability() -> Int64
    func cachedThumbnailURL(for base64Handle: MEGABase64Handle) -> URL
    func cachedPreviewURL(for base64Handle: MEGABase64Handle) -> URL
    func cachedOriginalURL(for base64Handle: MEGABase64Handle, name: String) -> URL
    func cachedFileURL(for base64Handle: MEGABase64Handle, name: String) -> URL
    func containsOriginalCacheDirectory(path: String) -> Bool
    func offlineFileURL(name: String) -> URL
    func copyFileToOfflineDocuments(at sourcePath: URL, name: String) -> Bool
    func moveFileToUploadsPath(at sourcePath: URL, name: String) -> Bool
    func tempUploadURL(for name: String) -> URL
    func removeFile(at url: URL)
    func fileSize(at url: URL) -> UInt64?
    func fileCreationDate(at url: URL) -> Date?
}
