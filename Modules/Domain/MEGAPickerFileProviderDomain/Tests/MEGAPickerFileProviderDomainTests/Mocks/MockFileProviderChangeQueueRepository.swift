import Foundation
import MEGAPickerFileProviderDomain

/// An in-memory queue whose anchors are positions in `changes`.
actor MockFileProviderChangeQueueRepository: FileProviderChangeQueueRepositoryProtocol {
    static var newRepo: MockFileProviderChangeQueueRepository { MockFileProviderChangeQueueRepository() }

    static let storeID = UUID()

    private(set) var changes: [FileProviderChangeEntity]
    private let isExpired: Bool

    init(changes: [FileProviderChangeEntity] = [], isExpired: Bool = false) {
        self.changes = changes
        self.isExpired = isExpired
    }

    static func anchor(at offset: Int) -> FileProviderChangeAnchorEntity {
        FileProviderChangeAnchorEntity(storeID: storeID, generation: 0, offset: offset)
    }

    func append(_ changes: [FileProviderChangeEntity]) {
        self.changes += changes
    }

    func currentAnchor() -> FileProviderChangeAnchorEntity {
        Self.anchor(at: changes.count)
    }

    func changes(since anchor: FileProviderChangeAnchorEntity, limit: Int) throws -> FileProviderChangeBatchEntity {
        guard !isExpired else {
            throw FileProviderChangeQueueErrorEntity.anchorExpired
        }
        let end = min(anchor.offset + limit, changes.count)
        return FileProviderChangeBatchEntity(
            changes: Array(changes[anchor.offset..<end]),
            nextAnchor: Self.anchor(at: end),
            hasMore: end < changes.count
        )
    }
}
