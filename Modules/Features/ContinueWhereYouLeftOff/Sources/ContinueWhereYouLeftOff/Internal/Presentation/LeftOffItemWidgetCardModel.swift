import Foundation
import MEGADomain
import MEGAFoundation

struct LeftOffItemWidgetCardModel: Equatable, Identifiable {
    let name: String
    let isSensitive: Bool
    let node: NodeEntity

    var id: HandleEntity { node.handle }

    var durationText: String? {
        guard node.mediaType == .video, node.duration > 0 else { return nil }
        return TimeInterval(node.duration).timeString
    }

    init(_ resolved: ResolvedLeftOffItemEntity) {
        name = resolved.item.name
        isSensitive = resolved.isSensitive
        node = resolved.node
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
            && lhs.isSensitive == rhs.isSensitive
            && lhs.node.handle == rhs.node.handle
            && lhs.node.hasThumbnail == rhs.node.hasThumbnail
            && lhs.node.duration == rhs.node.duration
    }
}
