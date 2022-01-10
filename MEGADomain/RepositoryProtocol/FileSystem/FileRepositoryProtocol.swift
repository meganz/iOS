import Foundation

protocol FileRepositoryProtocol {
    func fileExists(at url: URL) -> Bool
    func cachedThumbnailURL(for base64Handle: MEGABase64Handle) -> URL
    func cachedPreviewURL(for base64Handle: MEGABase64Handle) -> URL
}
