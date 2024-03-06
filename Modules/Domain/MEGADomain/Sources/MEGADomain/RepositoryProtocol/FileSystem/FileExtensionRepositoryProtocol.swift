import Foundation

public protocol FileExtensionRepositoryProtocol {
    func isImage(url: URL) -> Bool
    func isVideo(url: URL) -> Bool
}
