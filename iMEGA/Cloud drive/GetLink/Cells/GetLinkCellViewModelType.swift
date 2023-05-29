import Foundation
import MEGAPresentation

public enum GetLinkCellType: Sendable {
    case info
    case decryptKeySeparate
    case link
    case key
}

protocol GetLinkCellViewModelType {
    var type: GetLinkCellType { get }
}
