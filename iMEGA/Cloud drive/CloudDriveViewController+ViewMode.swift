import Foundation

extension CloudDriveViewController {
    
    @objc func clearViewModeChildren() {
        [cdCollectionView, cdTableView, mdHostedController]
            .compactMap { $0 }
            .forEach { controller in
                controller.willMove(toParent: nil)
                controller.view.removeFromSuperview()
                controller.removeFromParent()
            }
        
        cdCollectionView = nil
        cdTableView = nil
        mdHostedController = nil

        viewModel.isSelectionHidden = false
    }
    
    var currentViewModePreference: ViewModePreference {
        if isListViewModeSelected() {
            return .list
        } else if isThumbnailViewModeSelected() {
            return .thumbnail
        } else if isMediaDiscoveryViewModeSelected() {
            return .mediaDiscovery
        } else {
            return .perFolder
        }
    }
    
    @objc func updateSearchAppearance(for viewState: ViewModePreference) {
        switch viewState {
        case .perFolder, .list, .thumbnail:
            navigationItem.searchController = searchController
        case .mediaDiscovery:
            navigationItem.searchController = nil
        }
    }
}
