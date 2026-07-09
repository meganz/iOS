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
    ///   - date: The UTC-canonical bucket date this slot belongs to. Used as
    ///     `modificationTime`, which drives `categoryDate` grouping and section headers.
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
