import Foundation

public extension CGSize {
    var positiveWidth: CGSize {
        CGSize(width: max(0, width), height: height)
    }
}
