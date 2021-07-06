import Foundation

enum SMSStateEntity: Int, CaseIterable {
    case notAllowed = 0
    case onlyUnblock
    case optInAndUnblock
}
