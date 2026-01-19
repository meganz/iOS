import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import MEGAUIKit
import SwiftUI
import UIKit

final class AlbumContentViewController: UIViewController, ViewType {

    let viewModel: AlbumContentViewModel

    lazy var photoLibraryContentViewModel: PhotoLibraryContentViewModel = {
        let configuration = PhotoLibraryContentConfiguration(
            globalHeaderLeftViewProvider: { [weak viewModel] in
                guard let viewModel else { return AnyView(EmptyView()) }
                return AnyView(
                    SortHeaderView(
                        viewModel: viewModel.sortHeaderViewModel,
                        horizontalPadding: 0
                    )
                    .frame(height: 36)
                )
            }
        )
        return PhotoLibraryContentViewModel(
            library: PhotoLibrary(),
            contentMode: PhotoLibraryContentMode.album,
            configuration: configuration
        )
    }()
    lazy var photoLibraryPublisher = PhotoLibraryPublisher(viewModel: photoLibraryContentViewModel)
    lazy var selection = PhotoSelectionAdapter(sdk: .shared)
    lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    lazy var rightBarButtonItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.selectAllItems,
        style: .plain,
        target: self,
        action: #selector(editButtonPressed(_:))
    )
    lazy var addToAlbumBarButtonItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.navigationbarAdd,
        style: .plain,
        target: self,
        action: #selector(addToAlbumButtonPressed(_:))
    )
    
    lazy var leftBarButtonItem: UIBarButtonItem = {
        if viewModel.isMediaRevampEnabled {
            return UIBarButtonItem(image: MEGAAssets.UIImage.backArrow,
                                   style: .plain,
                                   target: self,
                                   action: #selector(exitButtonTapped(_:))
            )
        } else {
            return UIBarButtonItem(title: Strings.Localizable.close,
                                   style: .plain,
                                   target: self,
                                   action: #selector(exitButtonTapped(_:))
            )
        }
    }()
    
    lazy var toolbar = UIToolbar()
    var albumToolbarConfigurator: AlbumToolbarConfigurator?
    
    private lazy var emptyView = EmptyStateView.create(for: viewModel.isFavouriteAlbum ? .favourites: .album)
    private lazy var emptyAlbumHostingController: UIHostingController<RevampedContentUnavailableView> = {
        let view = RevampedContentUnavailableView(
            viewModel: .emptyAlbum { [weak viewModel] in
                viewModel?.dispatch(.addToAlbumTap)
            }
        )

        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        return controller
    }()
    private var floatingActionButtonController: UIHostingController<RoundedPrimaryImageButton>?
    
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
        setupLiquidGlassNavigationBar()

        configPhotoLibraryView(
            in: view,
            router: PhotoLibraryContentViewRouter(contentMode: photoLibraryContentViewModel.contentMode),
            onFilterUpdate: nil)

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setupLiquidGlassNavigationBar()
        }
    }

    // MARK: - Internal
    
    func selectedNodes() -> [MEGANode]? {
        selection.nodes
    }
    
    func endEditingMode() {
        setEditing(false, animated: true)
        viewModel.dispatch(.onEditModeChange(false))
        
        enablePhotoLibraryEditMode(isEditing)
        configureBarButtons()
        hideNavigationEditBarButton(photoLibraryContentViewModel.library.isEmpty)

        if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            navigationItem.titleView = NavigationTitleView(title: viewModel.albumName).toWrappedUIView(shouldEnableGlassEffect: true)
        } else {
            navigationItem.title = viewModel.albumName
        }

        hideToolbar()
    }
    
    func configureToolbarButtonsWithAlbumType() {
        configureToolbarButtons(albumType: viewModel.albumType)
    }
    
    func startEditingMode() {
        setEditing(true, animated: true)
        viewModel.dispatch(.onEditModeChange(true))
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
        case .updateAddToAlbumButton(let isVisible):
            isVisible ? addFloatingAddButton() : removeAddToAlbumFloatingActionButton()
        case .showEmptyView(let isEmpty, let isRevampEnabled):
            isEmpty ? showEmptyView(isRevampEnabled: isRevampEnabled) : removeEmptyView(isRevampEnabled: isRevampEnabled)
        }
    }
    
    // MARK: - Private

    private func buildNavigationBar() {
        if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            navigationItem.titleView = NavigationTitleView(title: viewModel.albumName).toWrappedUIView(shouldEnableGlassEffect: true)
        } else {
            self.title = viewModel.albumName
        }
        configureBarButtons()
    }
    
    private func configureBarButtons() {
        configureLeftBarButton()
        viewModel.dispatch(.configureContextMenu(isSelectHidden: viewModel.isPhotoSelectionHidden))
    }
    
    private func configureLeftBarButton() {
        if isEditing {
            let selectAllItemsBarButtonItem = UIBarButtonItem(
                image: MEGAAssets.UIImage.selectAllItems,
                style: .plain,
                target: self,
                action: #selector(selectAllButtonPressed(_:))
            )
            selectAllItemsBarButtonItem.tintColor = TokenColors.Text.primary
            navigationItem.leftBarButtonItem = selectAllItemsBarButtonItem
        } else {
            if !viewModel.isMediaRevampEnabled {
                leftBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: getBarButtonNormalForegroundColor()], for: .normal)
            }
            navigationItem.leftBarButtonItem = leftBarButtonItem
        }
    }
    
    private func showEmptyView(isRevampEnabled: Bool) {
        guard !isRevampEnabled else {
            showRevampEmptyView()
            return
        }
        view.addSubview(emptyView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        emptyView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
    }
    
    private func showRevampEmptyView() {
        guard let emptyView = emptyAlbumHostingController.view else { return }
        
        addChild(emptyAlbumHostingController)
        view.addSubview(emptyView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        emptyAlbumHostingController.didMove(toParent: self)
    }
    
    private func removeEmptyView(isRevampEnabled: Bool) {
        guard !isRevampEnabled else {
            removeRevampEmptyView()
            return
        }
        emptyView.removeFromSuperview()
    }
    
    private func removeRevampEmptyView() {
        emptyAlbumHostingController.willMove(toParent: nil)
        emptyAlbumHostingController.view.removeFromSuperview()
        emptyAlbumHostingController.removeFromParent()
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
        
        let transfers = selectedNodes.map { CancellableTransfer(handle: $0.handle, name: $0.name, priority: false, isFile: $0.isFile(), type: .download) }
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
    
    private func addFloatingAddButton() {
        guard floatingActionButtonController == nil else { return }
        
        let button = RoundedPrimaryImageButton(
            image: MEGAAssets.Image.plus) { [weak viewModel] in
                viewModel?.dispatch(.addToAlbumTap)
            }
        
        let hostingController = UIHostingController(rootView: button)
        hostingController.view.backgroundColor = .clear
        floatingActionButtonController = hostingController
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.widthAnchor.constraint(equalToConstant: 54),
            hostingController.view.heightAnchor.constraint(equalToConstant: 54),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])
    }
    
    private func removeAddToAlbumFloatingActionButton() {
        guard let controller = floatingActionButtonController else { return }
        
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        floatingActionButtonController = nil
    }
}

private extension ContentUnavailableViewModel {
    static func emptyAlbum(addItemsAction: @escaping () -> Void) -> Self {
        .init(
            image: MEGAAssets.Image.glassAlbum,
            title: Strings.Localizable.CameraUploads.Albums.Empty.title,
            font: .callout,
            titleTextColor: TokenColors.Text.secondary.swiftUI,
            actions: [
                ContentUnavailableViewModel.ButtonAction(
                    title: Strings.Localizable.General.addItems,
                    image: MEGAAssets.Image.plus,
                    handler: addItemsAction
                )
            ]
        )
    }
}
