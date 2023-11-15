import MEGADomain
import MEGAL10n
import MEGASDKRepo
import MEGASwift
import SwiftUI
import UIKit

extension PhotosViewController {
    private func contextMenuConfiguration() -> CMConfigEntity? {
        return CMConfigEntity(
            menuType: .menu(type: .timeline),
            sortType: viewModel.cameraUploadExplorerSortOrderType.megaSortOrderType.toSortOrderEntity(),
            isCameraUploadExplorer: true,
            isFilterEnabled: true,
            isSelectHidden: viewModel.isSelectHidden,
            isEmptyState: viewModel.mediaNodes.isEmpty,
            isFilterActive: viewModel.timelineCameraUploadStatusFeatureEnabled ? viewModel.isFilterActive : false
        )
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(
            displayMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
    }
    
    @objc func makeFilterActiveBarButton() -> UIBarButtonItem {
        UIBarButtonItem(image: UIImage(resource: .filterActive).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(onFilter))
    }
    
    @objc func makeContextMenuBarButton() -> UIBarButtonItem? {
        guard let config = contextMenuConfiguration(), let menu = contextMenuManager?.contextMenu(with: config) else { return nil }
        if viewModel.timelineCameraUploadStatusFeatureEnabled {
            return UIBarButtonItem(image: UIImage(resource: viewModel.isFilterActive ? .moreActionActiveNavigationBar : .moreNavigationBar),
                                   menu: makeTestingMenuItems(from: menu))
        }
        return UIBarButtonItem(image: UIImage(resource: .moreNavigationBar), menu: menu)
    }
    
    @objc func setupNavigationBarButtons() {
        setupLeftNavigationBarButtons()
        setupRightNavigationBarButtons()
    }
    
    func setupLeftNavigationBarButtons() {
        if isEditing {
            self.objcWrapper_parent.navigationItem.setLeftBarButton(selectAllBarButtonItem, animated: false)
        } else {
            self.objcWrapper_parent.navigationItem.setLeftBarButton(self.myAvatarManager?.myAvatarBarButton, animated: false)
        }
    }
    
    @objc func setupRightNavigationBarButtons() {
        if isEditing {
            self.objcWrapper_parent.navigationItem.setRightBarButtonItems([cancelBarButtonItem], animated: true)
        } else {
            var rightButtons = [UIBarButtonItem]()
            if photoLibraryContentViewModel.selectedMode == .all || viewModel.mediaNodes.isEmpty, let barButton = makeContextMenuBarButton() {
                rightButtons.append(barButton)
            }
            if viewModel.isFilterActive && !viewModel.timelineCameraUploadStatusFeatureEnabled {
                rightButtons.append(filterBarButtonItem)
            }
            if let cameraUploadStatusBarButtonItem {
                rightButtons.append(cameraUploadStatusBarButtonItem)
            }
            if objcWrapper_parent.navigationItem.rightBarButtonItems !~ rightButtons {
                objcWrapper_parent.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
            }
        }
    }
    
    @objc func makeCancelBarButton() -> UIBarButtonItem {
        UIBarButtonItem(title: Strings.Localizable.cancel, style: .done, target: self, action: #selector(toggleEditing))
    }
    
    @objc func makeEditBarButton() -> UIBarButtonItem {
        UIBarButtonItem(image: UIImage(resource: .selectAll), style: .plain, target: self, action: #selector(toggleEditing))
    }
    
    @objc func makeCameraUploadStatusBarButton() -> UIBarButtonItem {
        let statusButtonView = CameraUploadStatusButtonView(viewModel: viewModel.cameraUploadStatusButtonViewModel)
        let cameraStatusViewController = UIHostingController(rootView: statusButtonView)
        cameraStatusViewController.view.backgroundColor = .clear
        return UIBarButtonItem(customView: cameraStatusViewController.view)
    }
    
    @objc func toggleEditing() {
        setEditing(!isEditing, animated: true)
        setupNavigationBarButtons()
    }
    
    @objc private func onFilter() {
        photoLibraryContentViewModel.showFilter.toggle()
    }
    
    // MARK: - Camera Upload QA Testing options
    
    // Add Camera Status testing option to UIMenu
    private func makeTestingMenuItems(from original: UIMenu) -> UIMenu {
        var children = original.children
        let testingOptionsAction = UIAction(title: "CU Status Testing") { _ in
            self.showCameraUploadStatusTestingOptions()
        }
        children.append(testingOptionsAction)
        let menuItem = UIMenu(title: original.title,
                              subtitle: original.subtitle,
                              image: original.image,
                              options: original.options,
                              children: children)
        return menuItem
    }
    
    // Action sheet to show testing options for camera uploads.
    private func showCameraUploadStatusTestingOptions() {
        let alertController = UIAlertController(title: "CU Testing", message: "Select Testing Option", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Upload Photos", style: .default, handler: { [weak self] _ in
            self?.reloadCUBarButtonWithUseCase(FakeCameraUploadSuccessfulUseCase())
        }))
        alertController.addAction(UIAlertAction(title: "Upload already completed", style: .default, handler: { [weak self] _ in
            self?.reloadCUBarButtonWithUseCase(FakeNoItemsToUploadUseCase())
        }))
        alertController.addAction(UIAlertAction(title: "Upload Warning / Error", style: .default, handler: { [weak self] _ in
            self?.reloadCUBarButtonWithUseCase(FakeCameraUploadFailedUseCase())
        }))
        
        alertController.modalPresentationStyle = .popover
        if let view = cameraUploadStatusBarButtonItem?.customView {
            alertController.popoverPresentationController?.sourceRect = view.frame
            alertController.popoverPresentationController?.sourceView = view
        }
        present(alertController, animated: true)
    }
    
    // Reload CU button with new use case to view different testing options
    private func reloadCUBarButtonWithUseCase(_ useCase: some MonitorCameraUploadUseCaseProtocol) {
        viewModel.cameraUploadStatusButtonViewModel = CameraUploadStatusButtonViewModel(
            monitorCameraUploadUseCase: useCase)
        cameraUploadStatusBarButtonItem = makeCameraUploadStatusBarButton()
        setupRightNavigationBarButtons()
    }
}

// MARK: - DisplayMenuDelegate
extension PhotosViewController: DisplayMenuDelegate {
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        if action == .select {
            toggleEditing()
        } else if action == .filter || action == .filterActive {
            onFilter()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        viewModel.update(sortOrderType: sortType)
        setupNavigationBarButtons()
    }
}
