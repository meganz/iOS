import ContentLibraries
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGAUIKit
import SwiftUI
import UIKit

final class AlbumContentViewController: UIViewController, ViewType {
    
    let viewModel: AlbumContentViewModel
    
    lazy var photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: PhotoLibraryContentMode.album)
    lazy var photoLibraryPublisher = PhotoLibraryPublisher(viewModel: photoLibraryContentViewModel)
    lazy var selection = PhotoSelectionAdapter(sdk: .shared)
    lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    lazy var rightBarButtonItem = UIBarButtonItem(
        image: UIImage.selectAllItems,
        style: .plain,
        target: self,
        action: #selector(editButtonPressed(_:))
    )
    lazy var addToAlbumBarButtonItem = UIBarButtonItem(
        image: UIImage.navigationbarAdd,
        style: .plain,
        target: self,
        action: #selector(addToAlbumButtonPressed(_:))
    )
    
    lazy var leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close,
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(exitButtonTapped(_:))
    )
    
    lazy var toolbar = UIToolbar()
    var albumToolbarConfigurator: AlbumToolbarConfigurator?
    
    private lazy var emptyView = EmptyStateView.create(for: viewModel.isFavouriteAlbum ? .favourites: .album)
    
    var contextMenuManager: ContextMenuManager?
    
    // MARK: - Init
    
    init(viewModel: AlbumContentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildNavigationBar()
        
        configPhotoLibraryView(
            in: view,
            router: PhotoLibraryContentViewRouter(contentMode: photoLibraryContentViewModel.contentMode))
        
        setupPhotoLibrarySubscriptions()
        contextMenuManager = contextMenuManagerConfiguration()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        viewModel.dispatch(.onViewReady)
        
        view.backgroundColor = TokenColors.Background.page
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.dispatch(.onViewWillAppear)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isToolbarShown {
            endEditingMode()
        }
        
        viewModel.dispatch(.onViewWillDisappear)
    }
    
    // MARK: - Internal
    
    func selectedNodes() -> [MEGANode]? {
        selection.nodes
    }
    
    func endEditingMode() {
        setEditing(false, animated: true)
        
        enablePhotoLibraryEditMode(isEditing)
        configureBarButtons()
        hideNavigationEditBarButton(photoLibraryContentViewModel.library.isEmpty)
        
        navigationItem.title = viewModel.albumName
        
        hideToolbar()
    }
    
    func configureToolbarButtonsWithAlbumType() {
        configureToolbarButtons(albumType: viewModel.albumType)
    }
    
    func startEditingMode() {
        setEditing(true, animated: true)
        enablePhotoLibraryEditMode(isEditing)
        updateNavigationTitle(withSelectedPhotoCount: 0)
        
        configureBarButtons()
        configureToolbarButtonsWithAlbumType()
        
        showToolbar()
    }
    
    // MARK: - ViewType protocol
    
    func executeCommand(_ command: AlbumContentViewModel.Command) {
        switch command {
        case .startLoading:
            SVProgressHUD.show()
        case .finishLoading:
            SVProgressHUD.dismiss()
        case .showAlbumPhotos(let nodes, let sortOrder):
            updatePhotoLibrary(by: nodes, withSortType: sortOrder.toSortOrderEntity())
            
            if nodes.isEmpty {
                showEmptyView()
            } else {
                removeEmptyView()
            }
        case .dismissAlbum:
            presentedViewController?.dismiss(animated: false)
            dismiss(animated: true)
        case .deletePhotos:
            deleteAlbumPhotos()
        case .downloadSelectedItems:
            downloadSelectedNodes()
        case .endEditingMode:
            endEditingMode()
        case .exportFiles(let sender):
            exportFiles(sender: sender)
        case .showResultMessage(let messageType):
            SVProgressHUD.dismiss(withDelay: 3)
            switch messageType {
            case .success(let message):
                SVProgressHUD.showSuccess(withStatus: message)
            case .custom(let image, let message):
                SVProgressHUD.show(image, status: message)
            }
        case .updateNavigationTitle:
            buildNavigationBar()
        case .showDeleteAlbumAlert:
            showAlbumDeleteConfirmation()
        case .configureRightBarButtons(let config, let canAddPhotos):
            configureRightBarButtons(contextMenuConfiguration: config, canAddPhotosToAlbum: canAddPhotos)
        case .showRenameAlbumAlert(viewModel: let viewModel):
            present(UIAlertController(alert: viewModel), animated: true)
        case .showRemoveLinkAlert:
            showRemoveLinkConfirmation()
        case .showSharePhotoLinks:
            showSharePhotoLinks()
        }
    }
    
    // MARK: - Private
    
    private func buildNavigationBar() {
        self.title = viewModel.albumName
        configureBarButtons()
    }
    
    private func configureBarButtons() {
        configureLeftBarButton()
        viewModel.dispatch(.configureContextMenu(isSelectHidden: viewModel.isPhotoSelectionHidden))
    }
    
    private func configureLeftBarButton() {
        if isEditing {
            let selectAllItemsBarButtonItem = UIBarButtonItem(
                image: UIImage.selectAllItems,
                style: .plain,
                target: self,
                action: #selector(selectAllButtonPressed(_:))
            )
            selectAllItemsBarButtonItem.tintColor = TokenColors.Text.primary
            navigationItem.leftBarButtonItem = selectAllItemsBarButtonItem
        } else {
            leftBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: getBarButtonNormalForegroundColor()], for: .normal)
            navigationItem.leftBarButtonItem = leftBarButtonItem
        }
    }
    
    private func showEmptyView() {
        view.addSubview(emptyView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        emptyView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
    }
    
    private func removeEmptyView() {
        emptyView.removeFromSuperview()
    }
    
    private func showAlbumDeleteConfirmation() {
        let alert = UIAlertController(title: Strings.Localizable.CameraUploads.Albums.deleteAlbumTitle(1),
                                      message: Strings.Localizable.CameraUploads.Albums.deleteAlbumMessage(1),
                                      preferredStyle: .alert)
        alert.addAction(.init(title: Strings.Localizable.cancel, style: .cancel) { _ in })
        alert.addAction(.init(title: Strings.Localizable.delete, style: .default) { [weak self] _ in
            self?.viewModel.dispatch(.deleteAlbumActionTap)
        })
        
        present(alert, animated: true)
    }
    
    private func showRemoveLinkConfirmation() {
        let alert = UIAlertController(title: Strings.Localizable.CameraUploads.Albums.removeShareLinkAlertTitle(1),
                                      message: Strings.Localizable.CameraUploads.Albums.removeShareLinkAlertMessage(1),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: Strings.Localizable.CameraUploads.Albums.removeShareLinkAlertConfirmButtonTitle(1),
                                      style: .default, handler: { [weak self] _ in
            guard let self else { return }
            viewModel.dispatch(.removeLinkActionTap)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Action
    
    @objc private func exitButtonTapped(_ barButtonItem: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc func cancelButtonPressed(_ barButtonItem: UIBarButtonItem) {
        endEditingMode()
    }
    
    @objc private func editButtonPressed(_ barButtonItem: UIBarButtonItem) {
        startEditingMode()
    }
    
    @objc private func selectAllButtonPressed(_ barButtonItem: UIBarButtonItem) {
        configPhotoLibrarySelectAll()
        configureToolbarButtonsWithAlbumType()
    }
    
    @objc private func addToAlbumButtonPressed(_ barButtonItem: UIBarButtonItem) {
        viewModel.dispatch(.addToAlbumTap)
    }
    
    private func downloadSelectedNodes() {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        endEditingMode()
        
        let transfers = selectedNodes.map { CancellableTransfer(handle: $0.handle, name: nil, priority: false, isFile: $0.isFile(), type: .download) }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
    }
    
    private func showSharePhotoLinks() {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            GetLinkRouter(presenter: UIApplication.mnz_presentingViewController(),
                          nodes: selectedNodes).start()
            endEditingMode()
        }
    }
    
    private func deleteAlbumPhotos() {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        disablePhotoSelection(true)
        let alertController = UIAlertController(title: Strings.Localizable.CameraUploads.Albums.RemovePhotos.Alert.title,
                                                message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel) { [weak self] _ in
            guard let self else { return }
            disablePhotoSelection(false)
        })
        alertController.addAction(UIAlertAction(title: Strings.Localizable.remove, style: .destructive) { [weak self] _ in
            guard let self else { return }
            disablePhotoSelection(false)
            viewModel.dispatch(.deletePhotos(selectedNodes.toNodeEntities()))
            endEditingMode()
        })
        let isHiddenNodesEnabled = albumToolbarConfigurator?.isHiddenNodesEnabled ?? false
        alertController.popoverPresentationController?.barButtonItem = isHiddenNodesEnabled ? albumToolbarConfigurator?.moreItem : albumToolbarConfigurator?.removeToRubbishBinItem
        present(alertController, animated: true)
    }
    
    private func exportFiles(sender: Any) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        ExportFileRouter(presenter: self, sender: sender)
            .export(nodes: selectedNodes.toNodeEntities())
        endEditingMode()
    }
}
