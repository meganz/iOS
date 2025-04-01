import Foundation
import MEGAAppPresentation

public enum GetLinkCellType: Sendable {
    case info
    case decryptKeySeparate
    case link
    case key
    case linkAccess
}

protocol GetLinkCellViewModelType {
    var type: GetLinkCellType { get }
}
