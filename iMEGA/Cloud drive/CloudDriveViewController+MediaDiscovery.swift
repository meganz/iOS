import Foundation
import MEGADomain
import MEGASDKRepo
import SwiftUI
 
extension CloudDriveViewController: MediaDiscoveryContentDelegate {
        
    var mdViewController: MediaDiscoveryContentViewController? {
        get { mdHostedController as? MediaDiscoveryContentViewController }
        set { mdHostedController = newValue }
    }
    
    @objc func shouldShowMediaDiscovery() -> Bool {
        guard let parent = parentNode else { return false }
        
        return parent.type != .root && hasMediaFiles && !isFromSharedItem || currentViewModePreference == .mediaDiscovery
    }
    
    @objc func configureMediaDiscoveryViewMode(isShowingAutomatically: Bool) {
        clearViewModeChildren()
        updateSearchAppearance(for: .mediaDiscovery)
        
        guard let containerStackView, let parentNode else {
            return
        }

        let parentNodeEntity = parentNode.toNodeEntity()
        let sdk = MEGASdk.shared
        let analyticsUseCase = MediaDiscoveryAnalyticsUseCase(repository: AnalyticsRepository.newRepo)
        let mediaDiscoveryUseCase = MediaDiscoveryUseCase(filesSearchRepository: FilesSearchRepository(sdk: sdk),
                                                          nodeUpdateRepository: NodeUpdateRepository(sdk: sdk))
    
        let viewModel = MediaDiscoveryContentViewModel(
            contentMode: .mediaDiscovery,
            parentNode: parentNodeEntity,
            sortOrder: viewModel.sortOrder(for: .mediaDiscovery),
            isAutomaticallyShown: isShowingAutomatically,
            delegate: self,
            analyticsUseCase: analyticsUseCase,
            mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        let viewController = MediaDiscoveryContentViewController(viewModel: viewModel)
        
        addChild(viewController)
        containerStackView.addArrangedSubview(viewController.view)
        viewController.didMove(toParent: self)
        mdViewController = viewController
    }
    
    @objc func setMediaDiscovery(editMode: Bool) {
        mdViewController?.setEditing(editMode, animated: true)
    }
    
    @objc func mediaDiscoveryToggleAllSelected() {
        mdViewController?.toggleAllSelected()
    }
    
    func selectedPhotos(selected: [NodeEntity], allPhotos: [NodeEntity]) {
        
        let selectedMegaNodes = selected.toMEGANodes(in: .sharedSdk)
        selectedNodesArray = NSMutableArray(array: selectedMegaNodes)
        
        // Update View
        updateNavigationBarTitle()
        setToolbarActionsEnabled(selectedMegaNodes.count > 0)
        toolbarActions(nodeArray: selectedMegaNodes)
        
        // Figure out if all selected
        allNodesSelected = selected.count == allPhotos.count
    }
    
    func isMediaDiscoverySelection(isHidden: Bool) {
        viewModel.isSelectionHidden = isHidden
    }
    
    func mediaDiscoverEmptyTapped(menuAction: EmptyMediaDiscoveryContentMenuAction) {
        switch menuAction {
        case .choosePhotoVideo:
            showImagePickerFor(sourceType: .photoLibrary)
        case .capturePhotoVideo:
            showMediaCapture()
        }
    }
}
