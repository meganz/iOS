import MEGADomain
import MEGAL10n
import UIKit

@MainActor
final class CameraUploadProgressDiffableDatasource: UITableViewDiffableDataSource<CameraUploadProgressSections, CameraUploadProgressSectionRow> {
    private typealias Snapshot = NSDiffableDataSourceSnapshot<CameraUploadProgressSections, CameraUploadProgressSectionRow>
    
    private weak var tableView: UITableView?
    private var pendingQueueUpdate: Task<Void, any Error>?
    private var lastQueueUpdateTime: Date = .distantPast
    private let minUpdateInterval: TimeInterval = 0.1 // 100ms minimum between queue updates
    
    var onInitialSnapShotApplied: (() -> Void)?
    
    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<CameraUploadProgressSections, CameraUploadProgressSectionRow>.CellProvider) {
        self.tableView = tableView
        super.init(tableView: tableView, cellProvider: cellProvider)
    }
    
    func handleSnapshotUpdate(_ update: CameraUploadProgressTableViewModel.SnapshotUpdate) {
        switch update {
        case .loading(let numberOfRowsPerSection):
            setupLoading(numberOfRowsPerSection: numberOfRowsPerSection)
        case .initialLoad(let inProgressViewModels, let inQueueViewModels):
            updateDataSourceForInitialLoad(inProgressViewModels: inProgressViewModels, inQueueViewModels: inQueueViewModels)
        case .inProgressItemAdded(let viewModel):
            addInProgressItemToDataSource(viewModel: viewModel)
        case .inQueueUpdated(let viewModels):
            updateDataSourceForQueueUpdate(viewModels: viewModels)
        case .itemRemoved(let assetIdentifier):
            removeItemFromDataSource(assetIdentifier: assetIdentifier)
        }
    }
    
    private func setupLoading(numberOfRowsPerSection: Int) {
        var snapshot = Snapshot()
        snapshot.appendSections([.loadingInProgress, .loadingInQueue])
        
        let inProgressItems = (0..<numberOfRowsPerSection).map { _ in
            CameraUploadProgressSectionRow.loading(id: UUID())
        }
        let inQueueItems = (0..<numberOfRowsPerSection).map { _ in
            CameraUploadProgressSectionRow.loading(id: UUID())
        }
        
        snapshot.appendItems(inProgressItems, toSection: .loadingInProgress)
        snapshot.appendItems(inQueueItems, toSection: .loadingInQueue)
        
        apply(snapshot, animatingDifferences: false)
    }
    
    private func updateDataSourceForInitialLoad(
        inProgressViewModels: [CameraUploadInProgressRowViewModel],
        inQueueViewModels: [CameraUploadInQueueRowViewModel]
    ) {
        var snapshot = Snapshot()
        snapshot.appendSections([.inProgress, .inQueue])
        
        if inProgressViewModels.isEmpty {
            snapshot.appendItems([.emptyInProgress], toSection: .inProgress)
        } else {
            let inProgressItems = inProgressViewModels.map { CameraUploadProgressSectionRow.inProgress($0) }
            snapshot.appendItems(inProgressItems, toSection: .inProgress)
        }
        if inQueueViewModels.isEmpty {
            snapshot.appendItems([.emptyInQueue], toSection: .inQueue)
        } else {
            let inQueueItems = inQueueViewModels.map { CameraUploadProgressSectionRow.inQueue($0) }
            snapshot.appendItems(inQueueItems, toSection: .inQueue)
        }
        
        apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.onInitialSnapShotApplied?()
        }
    }
    
    private func addInProgressItemToDataSource(viewModel: CameraUploadInProgressRowViewModel) {
        var snapshot = snapshot()
        
        let queueItemsToRemove = snapshot.itemIdentifiers(inSection: .inQueue)
            .filter { item in
                if case .inQueue(let queueViewModel) = item {
                    return queueViewModel.id == viewModel.id
                }
                return false
            }
        
        if !queueItemsToRemove.isEmpty {
            snapshot.deleteItems(queueItemsToRemove)
        
            let remainingQueueItems = snapshot.itemIdentifiers(inSection: .inQueue).filter {
                if case .inQueue = $0 { return true }
                return false
            }
            if remainingQueueItems.isEmpty && !snapshot.itemIdentifiers(inSection: .inQueue).contains(.emptyInQueue) {
                snapshot.appendItems([.emptyInQueue], toSection: .inQueue)
            }
        }
        
        let existingInProgressItems = snapshot.itemIdentifiers(inSection: .inProgress)
        if existingInProgressItems.contains(.emptyInProgress) {
            snapshot.deleteItems([.emptyInProgress])
        }
        
        let newItem = CameraUploadProgressSectionRow.inProgress(viewModel)
        snapshot.appendItems([newItem], toSection: .inProgress)
        apply(snapshot, animatingDifferences: false)
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
                default: false
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
        
        apply(snapshot, animatingDifferences: false)
    }
    
    private func updateDataSourceForQueueUpdate(viewModels: [CameraUploadInQueueRowViewModel]) {
        pendingQueueUpdate?.cancel()
        
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastQueueUpdateTime)
        let shouldDebounce = timeSinceLastUpdate < minUpdateInterval
        
        if shouldDebounce {
            pendingQueueUpdate = Task { @MainActor [weak self] in
                guard let self else { return }
                try await Task.sleep(nanoseconds: UInt64(minUpdateInterval * 1_000_000_000))
                try await performQueueUpdate(viewModels: viewModels)
            }
        } else {
            Task { @MainActor in
                try await performQueueUpdate(viewModels: viewModels)
            }
        }
    }
    
    private func performQueueUpdate(viewModels: [CameraUploadInQueueRowViewModel]) async throws {
        lastQueueUpdateTime = Date()
        
        var snapshot = snapshot()
        
        try Task.checkCancellation()
        
        let existingQueueItems = snapshot.itemIdentifiers(inSection: .inQueue)
        
        try Task.checkCancellation()
        
        let existingItemsById = Dictionary(uniqueKeysWithValues: existingQueueItems.compactMap { item -> (String, CameraUploadProgressSectionRow)? in
            guard case .inQueue(let vm) = item else { return nil }
            return (vm.id, item)
        })
        
        try Task.checkCancellation()
        
        if existingQueueItems.contains(.emptyInQueue) {
            snapshot.deleteItems([.emptyInQueue])
        }
        
        try Task.checkCancellation()
        
        let realQueueItems = existingQueueItems.filter {
            if case .inQueue = $0 { return true }
            return false
        }
        
        snapshot.deleteItems(realQueueItems)
        
        try Task.checkCancellation()
        
        if viewModels.isEmpty {
            snapshot.appendItems([.emptyInQueue], toSection: .inQueue)
        } else {
            let queueItems = viewModels.map { viewModel in
                existingItemsById[viewModel.id] ?? CameraUploadProgressSectionRow.inQueue(viewModel)
            }
            
            try Task.checkCancellation()
            
            snapshot.appendItems(queueItems, toSection: .inQueue)
        }
        
        try Task.checkCancellation()
        
        applySnapshotWithScrollPreservation(snapshot, animatingDifferences: false, targetSection: .inQueue)
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
    
    // MARK: - Scroll Preservation Helper
    
    private func applySnapshotWithScrollPreservation(
        _ snapshot: Snapshot,
        animatingDifferences: Bool,
        targetSection: CameraUploadProgressSections? = nil
    ) {
        var anchorItem: CameraUploadProgressSectionRow?
        var anchorOffset: CGFloat = 0
        
        if let tableView,
           let visible = tableView.indexPathsForVisibleRows?.sorted() {
            
            let targetSectionIndex = targetSection?.rawValue
            let filtered = targetSectionIndex != nil
            ? visible.filter { $0.section == targetSectionIndex }
            : visible
            
            let usedIndexPaths = filtered.isEmpty ? visible : filtered
            
            if let middle = usedIndexPaths[safe: usedIndexPaths.count / 2],
               let item = itemIdentifier(for: middle) {
                anchorItem = item
                let frame = tableView.rectForRow(at: middle)
                anchorOffset = frame.minY - tableView.contentOffset.y
            }
        }
        
        apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            guard let self,
                  let tableView = tableView,
                  let anchorItem else { return }
            
            guard let newIndexPath = indexPath(for: anchorItem) else { return }
            
            let newFrame = tableView.rectForRow(at: newIndexPath)
            let newOffset = CGPoint(x: 0, y: newFrame.minY - anchorOffset)
            
            tableView.setContentOffset(newOffset, animated: false)
        }
    }
}

extension CameraUploadProgressSectionRow {
    var identifier: String {
        switch self {
        case .loading(let id): id.uuidString
        case .inProgress(let viewModel): viewModel.id
        case .inQueue(let viewModel): viewModel.id
        case .emptyInProgress: "empty-in-progress"
        case .emptyInQueue: "empty-in-queue"
        }
    }
}
