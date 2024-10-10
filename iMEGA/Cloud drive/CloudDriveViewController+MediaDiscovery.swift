import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

// this logic is moved to free floating function to be able to reuse the same exact logic and guarantee
// identical behaviour in the new cloud drive (NodeBrowserView)
func sharedShouldShowMediaDiscoveryContextMenuOption(
    mediaDiscoveryDetectionEnabled: Bool, // can't inject node here as we need to handle nil case (happens during offline starts)
    hasMediaFiles: Bool?,
    isFromSharedItem: Bool,
    viewModePreference: ViewModePreferenceEntity
) -> Bool {
    let shouldAutomaticallyShowMediaView = mediaDiscoveryDetectionEnabled &&
    hasMediaFiles == true && !isFromSharedItem
    return shouldAutomaticallyShowMediaView || viewModePreference == .mediaDiscovery
}
 
extension CloudDriveViewController: MediaDiscoveryContentDelegate {
        
    var mdViewController: MediaDiscoveryContentViewController? {
        get { mdHostedController as? MediaDiscoveryContentViewController }
        set { mdHostedController = newValue }
    }
    
    @objc func shouldShowMediaDiscoveryContextMenuOption() -> Bool {
        sharedShouldShowMediaDiscoveryContextMenuOption(
            mediaDiscoveryDetectionEnabled: parentNode?.toNodeEntity().nodeType != .root,
            hasMediaFiles: hasMediaFiles,
            isFromSharedItem: isFromSharedItem,
            viewModePreference: currentViewModePreference
        )
    }
    
    @objc func configureMediaDiscoveryViewMode(isShowingAutomatically: Bool) {
        clearViewModeChildren()
        updateSearchAppearance(for: ViewModePreferenceEntity.mediaDiscovery.rawValue)
        self.viewModePreference = .mediaDiscovery
        
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
            parentNodeProvider: { parentNodeEntity },
            sortOrder: viewModel.sortOrder(for: .mediaDiscovery),
            isAutomaticallyShown: isShowingAutomatically,
            delegate: self,
            analyticsUseCase: analyticsUseCase,
            mediaDiscoveryUseCase: mediaDiscoveryUseCase,
            sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo),
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
                hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) })
            )
        
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
