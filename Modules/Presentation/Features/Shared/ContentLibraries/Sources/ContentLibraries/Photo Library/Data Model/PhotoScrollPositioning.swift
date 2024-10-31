import Foundation
import MEGADomain

public struct PhotoScrollPosition: Hashable, Sendable {
    let handle: HandleEntity
    let date: Date
}

extension PhotoScrollPosition {
    public static let top = PhotoScrollPosition(handle: .invalid, date: Date(timeIntervalSince1970: 1))
}
