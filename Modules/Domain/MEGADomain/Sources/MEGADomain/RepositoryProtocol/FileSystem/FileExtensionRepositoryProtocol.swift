import Foundation

public protocol FileExtensionRepositoryProtocol: Sendable {
    func isImage(url: URL) -> Bool
    func isVideo(url: URL) -> Bool
}
