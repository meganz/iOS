import Foundation

protocol FileRepositoryProtocol {
    func fileExists(at url: URL) -> Bool
    func systemVolumeAvailability() -> Int64
    func cachedThumbnailURL(for base64Handle: MEGABase64Handle) -> URL
    func cachedPreviewURL(for base64Handle: MEGABase64Handle) -> URL
    func cachedOriginalURL(for base64Handle: MEGABase64Handle, name: String) -> URL
    func cachedFileURL(for base64Handle: MEGABase64Handle, name: String) -> URL
}
