import Foundation

enum GetThumbnailErrorEntity: Error, CaseIterable {
    case generic
    case noThumbnail
    case nodeNotFound
}
