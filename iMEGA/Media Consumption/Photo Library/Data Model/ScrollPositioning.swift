import Foundation

struct PhotoScrollPosition: Hashable {
    let handle: MEGAHandle
    let date: Date
}

extension PhotoScrollPosition {
    static let top = PhotoScrollPosition(handle: .invalid, date: Date(timeIntervalSince1970: 0.1))
}

protocol ScrollPositioning {
    var position: PhotoScrollPosition? { get }
}
