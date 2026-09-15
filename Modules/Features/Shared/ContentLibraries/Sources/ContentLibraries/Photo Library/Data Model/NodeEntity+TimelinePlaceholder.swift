import Foundation
import MEGADomain

/// Support for lightweight "skeleton" timeline items.
///
/// The paginated timeline first renders a grid sized purely from
/// `MediaDateSectionEntity` counts, before any real node has been fetched. Each empty
/// slot is represented by a placeholder `NodeEntity` that carries only a synthetic
/// handle and its bucket date, so it flows through the existing `PhotoLibrary` tree and
/// the UIKit collection-view coordinator unchanged. Placeholder cells render the
/// file-type placeholder icon and never trigger thumbnail / sensitivity fetches
extension NodeEntity {
    /// Handles at or above this value identify a timeline placeholder rather than a real
    /// node. Genuine MEGA handles occupy the low 48 bits, so this reserved high band
    /// never collides with a real node. `HandleEntity.invalid` (all ones) also falls in
    /// the band but is explicitly excluded below, so an invalid-handle node is never
    /// mistaken for a skeleton slot.
    static let timelinePlaceholderHandleBase: HandleEntity = 0xF000_0000_0000_0000

    /// True when this is a synthetic skeleton slot, not a real node.
    public var isTimelinePlaceholder: Bool {
        handle >= Self.timelinePlaceholderHandleBase && handle != .invalid
    }

    /// Builds a lightweight placeholder node for one skeleton slot.
    /// - Parameters:
    ///   - offset: Zero-based index within the current skeleton build. Added to
    ///     `timelinePlaceholderHandleBase` to give every placeholder a unique handle,
    ///     which `PhotoDateSection.indexPath(of:)` and `PhotoScrollPosition` require.
    ///   - date: The local day of the bucket this slot belongs to (derived from the SDK
    ///     `groupId`, not from the bucket's start timestamp). Used as `modificationTime`,
    ///     which drives `categoryDate` grouping and section headers.
    static func timelinePlaceholder(offset: UInt64, date: Date) -> NodeEntity {
        NodeEntity(
            changeTypes: [],
            nodeType: .file,
            name: "",
            fingerprint: nil,
            handle: timelinePlaceholderHandleBase + offset,
            base64Handle: "",
            restoreParentHandle: .invalid,
            ownerHandle: .invalid,
            parentHandle: .invalid,
            isFile: true,
            isFolder: false,
            isRemoved: false,
            hasThumbnail: false,
            hasPreview: false,
            isPublic: false,
            isShare: false,
            isOutShare: false,
            isInShare: false,
            isExported: false,
            isExpired: false,
            isTakenDown: false,
            isFavourite: false,
            isMarkedSensitive: false,
            description: nil,
            label: .unknown,
            tags: [],
            publicHandle: .invalid,
            expirationTime: nil,
            publicLinkCreationTime: nil,
            size: .zero,
            creationTime: date,
            modificationTime: date,
            width: .zero,
            height: .zero,
            shortFormat: .zero,
            codecId: .zero,
            duration: .zero,
            mediaType: nil,
            latitude: nil,
            longitude: nil,
            deviceId: nil
        )
    }
}

extension Array where Element == NodeEntity {
    /// The run of real nodes around `index`, clamped to `radius` items on either side.
    ///
    /// The photo browser grows a handed-over run from its two ends only, so a gap inside one could
    /// never be filled: the run stops at the first placeholder on each side. It is clamped as well
    /// as cut, because a user who has scrolled for a while leaves a long hydrated stretch behind,
    /// and handing all of it over would differ little from handing over the whole projection —
    /// the paging paths would then hardly ever be reached.
    ///
    /// - Returns: the nodes and the position of the first of them, or `nil` when `index` is out of
    ///   range or is a placeholder itself.
    func contiguousRealRun(around index: Int, radius: Int) -> (nodes: [NodeEntity], startIndex: Int)? {
        guard indices.contains(index), !self[index].isTimelinePlaceholder else { return nil }

        var start = index
        let lowerLimit = Swift.max(0, index - radius)
        while start > lowerLimit, !self[start - 1].isTimelinePlaceholder { start -= 1 }

        var end = index
        let upperLimit = Swift.min(count - 1, index + radius)
        while end < upperLimit, !self[end + 1].isTimelinePlaceholder { end += 1 }

        return (Array(self[start...end]), start)
    }
}
