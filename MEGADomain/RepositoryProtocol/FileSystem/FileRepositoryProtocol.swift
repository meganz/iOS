import Foundation

protocol FileRepositoryProtocol {
    func fileExists(at url: URL) -> Bool
    func fileTypeName(forFileExtension fileExtension: String) -> String?
    func cachedThumbnailURL(forHandle base64Handle: MEGABase64Handle) -> URL
    func cachedPreviewURL(forHandle base64Handle: MEGABase64Handle) -> URL
}
