import Foundation

extension CloudDriveViewController {
    
    @objc func clearViewModeChildren() {
        [cdCollectionView, cdTableView]
            .compactMap { $0 }
            .forEach { controller in
                controller.willMove(toParent: nil)
                controller.view.removeFromSuperview()
                controller.removeFromParent()
            }
        
        cdCollectionView = nil
        cdTableView = nil
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
}
