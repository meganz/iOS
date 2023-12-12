import Foundation
import MEGADomain
import MEGARepo

extension CloudDriveViewController {
    
    @objc func makeDefaultViewModeStoreCreator() {
        viewModeStoreCreator = { [weak self] in
            self?.viewModeStore = ViewModeStore(
                preferenceRepo: PreferenceRepository(userDefaults: .standard),
                megaStore: .shareInstance(),
                sdk: .shared,
                notificationCenter: .default
            )
        }
    }
    
    @objc func assignViewModeStore() {
        viewModeStoreCreator()
    }
    
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
    
    var currentViewModePreference: ViewModePreferenceEntity {
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
    
    @objc func updateSearchAppearance(for viewState: Int) {
        if let _viewState = ViewModePreferenceEntity(rawValue: viewState) {
            switch _viewState {
            case .perFolder, .list, .thumbnail:
                navigationItem.searchController = searchController
            case .mediaDiscovery:
                navigationItem.searchController = nil
            }
        }
    }
    
    var viewModePreference: ViewModePreferenceEntity {
        get {
            ViewModePreferenceEntity(rawValue: viewModePreference_ObjC)!
        }
        set {
            viewModePreference_ObjC = newValue.rawValue
        }
    }
    
    /// With the passed in viewMode, this function will attempt to update and change the viewMode for the screen.
    /// If the viewMode is the same as it was previously, no change will be made, and exit early
    /// - If the passed in viewMode change is of type ViewModePreferenceEntityMediaDiscovery, 
    ///   this function will not save this preference to the device to be used with parent nodes and future sub folder viewModes
    ///   therefore current parent nodes in the view stack will not receive a change notification.
    ///   - other cases are recorder in the ViewModeStore
    
    @objc func change(_ viewModePreference: ViewModePreferenceEntity) {
        
        if self.viewModePreference == viewModePreference {
            return
        }
        
        if viewModePreference == .mediaDiscovery {
            configureMediaDiscoveryViewMode(isShowingAutomatically: false)
            shouldDetermineViewMode = false
        }
        if
            let node = parentNode,
            let viewMode = ViewModePreferenceEntity(rawValue: viewModePreference.rawValue)
        {
            viewModeStore?.save(
                viewMode: viewMode,
                for: ViewModeLocation_ObjWrapper(node: node)
            )
        }
    }
    
    @objc func observeViewModeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(determineViewMode), name: .MEGAViewModePreferenceDidChange, object: nil)
    }
}
