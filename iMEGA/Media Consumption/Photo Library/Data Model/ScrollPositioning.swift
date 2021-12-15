import Foundation

typealias PhotoScrollPosition = Date?

protocol ScrollPositioning {
    var position: PhotoScrollPosition { get }
}
