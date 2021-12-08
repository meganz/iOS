import Foundation

enum ThumbnailErrorEntity: Error, CaseIterable {
    case generic
    case noThumbnail
    case noPreview
    case nodeNotFound
}
