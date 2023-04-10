import Foundation
import MEGADomain

extension SaveMediaToPhotosErrorEntity: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .fileDownloadInProgress:
            return Strings.Localizable.General.fileIsBeingDownloaded
        default:
            return Strings.Localizable.somethingWentWrong
        }
    }
}
