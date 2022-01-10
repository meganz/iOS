import Foundation

struct PhotoScrollPosition: Hashable {
    let handle: MEGAHandle
    let date: Date
}

extension PhotoScrollPosition {
    static let top = PhotoScrollPosition(handle: .invalid, date: Date(timeIntervalSince1970: 1))
}

protocol PhotoScrollPositioning {
    var position: PhotoScrollPosition? { get }
}
