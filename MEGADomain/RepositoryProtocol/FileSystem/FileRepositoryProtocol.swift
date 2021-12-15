import Foundation

protocol FileRepositoryProtocol {
    func fileExists(at url: URL) -> Bool
    func cachedThumbnailURL(forHandle base64Handle: MEGABase64Handle) -> URL
    func cachedPreviewURL(forHandle base64Handle: MEGABase64Handle) -> URL
}
