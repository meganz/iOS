import Foundation

struct PhotoScrollPosition: Hashable {
    let handle: MEGAHandle
    let date: Date
}

protocol ScrollPositioning {
    var position: PhotoScrollPosition? { get }
}
