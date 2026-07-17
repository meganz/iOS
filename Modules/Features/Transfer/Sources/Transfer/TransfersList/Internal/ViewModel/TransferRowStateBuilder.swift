import Foundation
import MEGADomain

/// Builds `TransferRowState` values for one tab's rows.
///
/// Active and Failed rows are pure transforms of the entity. Completed rows also
/// carry the finish date and the file system path, which needs an SDK lookup for
/// uploads; those lookups are cached per destination folder.
@MainActor
final class TransferRowStateBuilder {
    private let tab: TransfersTab
    private let locationResolver: any TransferLocationResolving
    private let finishDateProvider: any TransferFinishDateProviding
    private let sourceExists: (String) -> Bool
    /// Values are `String?` on purpose: a destination that resolves to `nil` is
    /// cached as a negative result and not looked up again for every row.
    private var uploadLocationsByParentHandle: [HandleEntity: String?] = [:]

    init(
        tab: TransfersTab,
        locationResolver: some TransferLocationResolving,
        finishDateProvider: some TransferFinishDateProviding,
        sourceExists: @escaping (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) {
        self.tab = tab
        self.locationResolver = locationResolver
        self.finishDateProvider = finishDateProvider
        self.sourceExists = sourceExists
    }

    /// Row states for the tab's snapshot. The Completed tab reads the finish date
    /// captured when the transfer finished, looked up by tag.
    func snapshotStates(for entities: [TransferEntity]) async -> [TransferRowState] {
        switch tab {
        case .active, .failed:
            return entities.map { TransferEntityMapper.rowState(for: $0, isRetryable: isRetryable(for: $0)) }
        case .completed:
            var states: [TransferRowState] = []
            states.reserveCapacity(entities.count)
            for entity in entities {
                states.append(await completedState(
                    for: entity,
                    finishDate: finishDateProvider.finishDate(forTag: entity.tag)
                ))
            }
            return states
        }
    }

    /// Row state for a finish event landing on this tab.
    func finishState(for entity: TransferEntity) async -> TransferRowState {
        switch tab {
        case .active, .failed:
            return TransferEntityMapper.rowState(for: entity, isRetryable: isRetryable(for: entity))
        case .completed:
            // `recordIfAbsent`, not a plain read: the finish is happening now,
            // so stamping the current instant is correct, and set-if-absent
            // dedupes against the app-lifetime recorder's own copy of this event.
            return await completedState(
                for: entity,
                finishDate: finishDateProvider.recordIfAbsent(tag: entity.tag, date: Date())
            )
        }
    }

    private func completedState(for entity: TransferEntity, finishDate: Date?) async -> TransferRowState {
        TransferEntityMapper.rowState(
            for: entity,
            location: await location(for: entity),
            finishDate: finishDate,
            canViewInFolder: !entity.isSavedToPhotos,
            isRetryable: isRetryable(for: entity)
        )
    }

    private func isRetryable(for entity: TransferEntity) -> Bool {
        TransferRetryPolicy.isRetryable(entity, sourceExists: sourceExists)
    }

    private func location(for entity: TransferEntity) async -> String? {
        guard entity.type == .upload else {
            return await locationResolver.location(for: entity)
        }
        if let cached = uploadLocationsByParentHandle[entity.parentHandle] {
            return cached
        }
        let location = await locationResolver.location(for: entity)
        uploadLocationsByParentHandle[entity.parentHandle] = location
        return location
    }
}
