import MEGADomain
import MEGAL10n
import UIKit

@MainActor
final class CameraUploadProgressDiffableDatasource: UITableViewDiffableDataSource<CameraUploadProgressSections, CameraUploadProgressSectionRow> {
    private typealias Snapshot = NSDiffableDataSourceSnapshot<CameraUploadProgressSections, CameraUploadProgressSectionRow>

    private weak var tableView: UITableView?

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<CameraUploadProgressSections, CameraUploadProgressSectionRow>.CellProvider) {
        self.tableView = tableView
        super.init(tableView: tableView, cellProvider: cellProvider)
    }

    func handleInProgressSnapshotUpdate(_ update: CameraUploadProgressTableViewModel.InProgressSnapshotUpdate) {
        switch update {
        case .initialLoad(let viewModels):
            updateDataSourceForInitialLoad(viewModels: viewModels)
        case .itemAdded(let viewModel):
            addItemToDataSource(viewModel: viewModel)
        case .itemRemoved(let assetIdentifier):
            removeItemFromDataSource(assetIdentifier: assetIdentifier)
        }
    }
    
    func handleInQueueSnapshotUpdate(_ update: CameraUploadProgressTableViewModel.InQueueSnapshotUpdate) {
        switch update {
        case .initial(let viewModels):
            updateDataSourceForInitialQueueLoad(viewModels: viewModels)
        case .updated(let viewModels):
            updateDataSourceForQueueUpdate(viewModels: viewModels)
        case .itemRemoved(let assetIdentifier):
            removeItemFromQueue(assetIdentifier: assetIdentifier)
        }
    }
    
    private func updateDataSourceForInitialLoad(viewModels: [CameraUploadInProgressRowViewModel]) {
        let currentSnapshot = snapshot()
        var snapshot = rebuildSnapshotWithSections(currentSnapshot: currentSnapshot)

        if snapshot.itemIdentifiers(inSection: .inProgress).contains(.emptyInProgress) {
            snapshot.deleteItems([.emptyInProgress])
        }
        
        if viewModels.isEmpty {
            snapshot.appendItems([.emptyInProgress], toSection: .inProgress)
        } else {
            let rowItems = viewModels.map { CameraUploadProgressSectionRow.inProgress($0) }
            snapshot.appendItems(rowItems, toSection: .inProgress)
        }
        apply(snapshot, animatingDifferences: false)
    }
    
    private func addItemToDataSource(viewModel: CameraUploadInProgressRowViewModel) {
        var snapshot = snapshot()

        let existingItems = snapshot.itemIdentifiers(inSection: .inProgress)
        if existingItems.contains(.emptyInProgress) {
            snapshot.deleteItems([.emptyInProgress])
        }

        let newItem = CameraUploadProgressSectionRow.inProgress(viewModel)
        snapshot.appendItems([newItem], toSection: .inProgress)
        apply(snapshot, animatingDifferences: true)
    }
    
    private func removeItemFromDataSource(assetIdentifier: CameraUploadLocalIdentifierEntity) {
        var snapshot = snapshot()
        
        let itemsToRemove = snapshot.itemIdentifiers
            .filter { item in
                switch item {
                case .inProgress(let viewModel):
                    viewModel.id == assetIdentifier
                case .inQueue(let viewModel):
                    viewModel.id == assetIdentifier
                case .emptyInProgress, .emptyInQueue:
                    false
                }
            }
        
        snapshot.deleteItems(itemsToRemove)
        
        let inProgressItems = snapshot.itemIdentifiers(inSection: .inProgress).filter {
            if case .inProgress = $0 { return true }
            return false
        }
        if inProgressItems.isEmpty && !snapshot.itemIdentifiers(inSection: .inProgress).contains(.emptyInProgress) {
            snapshot.appendItems([.emptyInProgress], toSection: .inProgress)
        }
        
        let inQueueItems = snapshot.itemIdentifiers(inSection: .inQueue).filter {
            if case .inQueue = $0 { return true }
            return false
        }
        if inQueueItems.isEmpty && !snapshot.itemIdentifiers(inSection: .inQueue).contains(.emptyInQueue) {
            snapshot.appendItems([.emptyInQueue], toSection: .inQueue)
        }
        
        apply(snapshot, animatingDifferences: true)
    }
    
    private func updateDataSourceForInitialQueueLoad(viewModels: [CameraUploadInQueueRowViewModel]) {
        let currentSnapshot = snapshot()
        var snapshot = rebuildSnapshotWithSections(currentSnapshot: currentSnapshot)

        let existingItems = snapshot.itemIdentifiers(inSection: .inQueue)
        if existingItems.contains(.emptyInQueue) {
            snapshot.deleteItems([.emptyInQueue])
        }
        if viewModels.isEmpty {
            snapshot.appendItems([.emptyInQueue], toSection: .inQueue)
        } else {
            let rowItems = viewModels.map { CameraUploadProgressSectionRow.inQueue($0) }
            snapshot.appendItems(rowItems, toSection: .inQueue)
        }
        apply(snapshot, animatingDifferences: false)
    }
    
    private func updateDataSourceForQueueUpdate(viewModels: [CameraUploadInQueueRowViewModel]) {
        var snapshot = snapshot()

        var anchorItemId: String?
        var anchorOffset: CGFloat = 0

        if let tableView = self.tableView,
           let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            let queueIndexPaths = visibleIndexPaths.filter { $0.section == CameraUploadProgressSections.inQueue.rawValue }
            if let firstVisibleQueueIndexPath = queueIndexPaths.first,
               let item = itemIdentifier(for: firstVisibleQueueIndexPath),
               case .inQueue = item,
               let cell = tableView.cellForRow(at: firstVisibleQueueIndexPath) {
                anchorItemId = item.identifier
                let cellFrameInTableView = tableView.convert(cell.frame, to: tableView)
                anchorOffset = tableView.contentOffset.y - cellFrameInTableView.minY
            }
        }

        let existingQueueItems = snapshot.itemIdentifiers(inSection: .inQueue)
        let existingItemsById = Dictionary(uniqueKeysWithValues: existingQueueItems.compactMap { item -> (String, CameraUploadProgressSectionRow)? in
            guard case .inQueue(let vm) = item else { return nil }
            return (vm.id, item)
        })

        if existingQueueItems.contains(.emptyInQueue) {
            snapshot.deleteItems([.emptyInQueue])
        }

        let realQueueItems = existingQueueItems.filter {
            if case .inQueue = $0 { return true }
            return false
        }
        snapshot.deleteItems(realQueueItems)

        if viewModels.isEmpty {
            snapshot.appendItems([.emptyInQueue], toSection: .inQueue)
        } else {
            let queueItems = viewModels.map { viewModel in
                existingItemsById[viewModel.id] ?? CameraUploadProgressSectionRow.inQueue(viewModel)
            }
            snapshot.appendItems(queueItems, toSection: .inQueue)
        }

        apply(snapshot, animatingDifferences: false) { [weak self] in
            guard let self = self,
                  let tableView = self.tableView,
                  let anchorId = anchorItemId,
                  !viewModels.isEmpty else {
                return
            }

            let newSnapshot = self.snapshot()
            guard let anchorItem = newSnapshot.itemIdentifiers.first(where: { $0.identifier == anchorId }),
                  let anchorIndex = newSnapshot.indexOfItem(anchorItem) else {
                return
            }

            var sectionOffset = 0
            for section in newSnapshot.sectionIdentifiers {
                if section == .inQueue {
                    break
                }
                sectionOffset += newSnapshot.itemIdentifiers(inSection: section).count
            }

            let newIndexPath = IndexPath(row: anchorIndex - sectionOffset, section: CameraUploadProgressSections.inQueue.rawValue)

            guard let cell = tableView.cellForRow(at: newIndexPath) else { return }
            let cellFrameInTableView = tableView.convert(cell.frame, to: tableView)
            let targetOffset = cellFrameInTableView.minY + anchorOffset
            tableView.setContentOffset(CGPoint(x: 0, y: targetOffset), animated: false)
        }
    }
    
    private func removeItemFromQueue(assetIdentifier: CameraUploadLocalIdentifierEntity) {
        var snapshot = snapshot()

        guard snapshot.sectionIdentifiers.contains(.inQueue) else { return }

        let queueItems = snapshot.itemIdentifiers(inSection: .inQueue)
        let itemsToRemove = queueItems.filter {
            if case .inQueue(let vm) = $0 {
                return vm.id == assetIdentifier
            }
            return false
        }

        guard !itemsToRemove.isEmpty else {
            return
        }

        snapshot.deleteItems(itemsToRemove)
        
        let remainingQueueItems = snapshot.itemIdentifiers(inSection: .inQueue).filter {
            if case .inQueue = $0 { return true }
            return false
        }
        if remainingQueueItems.isEmpty && !snapshot.itemIdentifiers(inSection: .inQueue).contains(.emptyInQueue) {
            snapshot.appendItems([.emptyInQueue], toSection: .inQueue)
        }
        
        apply(snapshot, animatingDifferences: true)
    }

    private func rebuildSnapshotWithSections(currentSnapshot: Snapshot) -> Snapshot {
        var snapshot = NSDiffableDataSourceSnapshot<CameraUploadProgressSections, CameraUploadProgressSectionRow>()
        snapshot.appendSections([.inProgress, .inQueue])

        if currentSnapshot.sectionIdentifiers.contains(.inProgress) {
            let realInProgressItems = currentSnapshot.itemIdentifiers(inSection: .inProgress).filter {
                if case .inProgress = $0 { return true }
                return false
            }
            if !realInProgressItems.isEmpty {
                snapshot.appendItems(realInProgressItems, toSection: .inProgress)
            } else {
                snapshot.appendItems([.emptyInProgress], toSection: .inProgress)
            }
        } else {
            snapshot.appendItems([.emptyInProgress], toSection: .inProgress)
        }

        if currentSnapshot.sectionIdentifiers.contains(.inQueue) {
            let realInQueueItems = currentSnapshot.itemIdentifiers(inSection: .inQueue).filter {
                if case .inQueue = $0 { return true }
                return false
            }
            if !realInQueueItems.isEmpty {
                snapshot.appendItems(realInQueueItems, toSection: .inQueue)
            } else {
                snapshot.appendItems([.emptyInQueue], toSection: .inQueue)
            }
        } else {
            snapshot.appendItems([.emptyInQueue], toSection: .inQueue)
        }

        return snapshot
    }
}

extension CameraUploadProgressSectionRow {
    var identifier: String {
        switch self {
        case .inProgress(let viewModel): viewModel.id
        case .inQueue(let viewModel): viewModel.id
        case .emptyInProgress: "empty-in-progress"
        case .emptyInQueue: "empty-in-queue"
        }
    }
}
