import Foundation
import MEGADomain

struct PhotoScrollPosition: Hashable {
    let handle: HandleEntity
    let date: Date
}

extension PhotoScrollPosition {
    static let top = PhotoScrollPosition(handle: .invalid, date: Date(timeIntervalSince1970: 1))
}
