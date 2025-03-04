import Foundation
import MEGADomain

public final class MockFileExtensionRepository: FileExtensionRepositoryProtocol, @unchecked Sendable {
    public enum FileType {
        case unknown
        case image
        case video
    }

    public enum Action: Equatable {
        case isImage(URL)
        case isVideo(URL)
    }

    private let fileType: FileType
    public var actions = [Action]()

    public init(fileType: FileType = .unknown) {
        self.fileType = fileType
    }

    public func isImage(url: URL) -> Bool {
        actions.append(.isImage(url))
        return fileType == .image
    }

    public func isVideo(url: URL) -> Bool {
        actions.append(.isVideo(url))
        return fileType == .video
    }
}
