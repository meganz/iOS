import MEGADomain
import MEGAL10n
import UIKit

@MainActor
final class CameraUploadProgressDiffableDatasource: UITableViewDiffableDataSource<CameraUploadProgressSections, CameraUploadProgressSectionRow> {
    private typealias Snapshot = NSDiffableDataSourceSnapshot<CameraUploadProgressSections, CameraUploadProgressSectionRow>
    
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
    
    private func updateDataSourceForInitialLoad(viewModels: [CameraUploadInProgressRowViewModel]) {
        guard !viewModels.isEmpty else {
            apply(Snapshot(), animatingDifferences: false)
            return
        }

        var snapshot = Snapshot()
        snapshot.appendSections([.inProgress])
        let rowItems = viewModels.map { CameraUploadProgressSectionRow.inProgress($0) }
        snapshot.appendItems(rowItems, toSection: .inProgress)

        apply(snapshot, animatingDifferences: false)
    }
    
    private func addItemToDataSource(viewModel: CameraUploadInProgressRowViewModel) {
        var snapshot = snapshot()
        
        if !snapshot.sectionIdentifiers.contains(.inProgress) {
            snapshot.appendSections([.inProgress])
        }
        
        let newItem = CameraUploadProgressSectionRow.inProgress(viewModel)
        snapshot.appendItems([newItem], toSection: .inProgress)
        apply(snapshot, animatingDifferences: true)
    }
    
    private func removeItemFromDataSource(assetIdentifier: CameraUploadLocalIdentifierEntity) {
        var snapshot = snapshot()
        
        let itemsToRemove = snapshot.itemIdentifiers.filter { item in
            switch item {
            case .inProgress(let viewModel):
                return viewModel.id == assetIdentifier
            }
        }
        
        snapshot.deleteItems(itemsToRemove)
        
        if snapshot.itemIdentifiers(inSection: .inProgress).isEmpty {
            snapshot.deleteSections([.inProgress])
        }
        
        apply(snapshot, animatingDifferences: true)
    }
}
