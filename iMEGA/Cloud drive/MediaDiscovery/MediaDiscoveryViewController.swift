import ContentLibraries
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import UIKit

final class MediaDiscoveryViewController: ExplorerBaseViewController {
    private let viewModel: MediaDiscoveryViewModel
    private let folderName: String
    private let contentMode: PhotoLibraryContentMode
    
    override var displayMode: DisplayMode { contentMode.displayMode }
    
    lazy var rightBarButtonItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.selectAllItems,
        style: .plain,
        target: self,
        action: #selector(editButtonPressed(_:))
    )
    
    lazy var leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.CloudDrive.MediaDiscovery.exit,
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(exitButtonTapped(_:))
    )
    
    lazy var photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: contentMode)
    lazy var photoLibraryPublisher = PhotoLibraryPublisher(viewModel: photoLibraryContentViewModel)
    lazy var selection = PhotoSelectionAdapter(sdk: contentMode == .mediaDiscoveryFolderLink ? MEGASdk.sharedFolderLink : MEGASdk.shared)
    
    private lazy var emptyView = EmptyStateView.create(for: .photos)
    private var mediaDiscoveryFolderLinkToolbarConfigurator: MediaDiscoveryFolderLinkToolbarConfigurator?
    
    // MARK: - Init
    
    init(
        viewModel: MediaDiscoveryViewModel,
        folderName: String,
        contentMode: PhotoLibraryContentMode = .mediaDiscovery
    ) {
        self.viewModel = viewModel
        self.folderName = folderName
        self.contentMode = contentMode
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildNavigationBar()
        
        configPhotoLibraryView(
            in: view,
            router: PhotoLibraryContentViewRouter(
                contentMode: photoLibraryContentViewModel.contentMode))
        setupPhotoLibrarySubscriptions()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.excuteCommand(command)
        }
        
        viewModel.dispatch(.onViewReady)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.dispatch(.onViewDidAppear)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.dispatch(.onViewWillDisAppear)
    }

    // MARK: - Private
    
    private func buildNavigationBar() {
        self.title = folderName
        
        configureBarButtons()
    }
    
    private func configureBarButtons() {
        configureLeftBarButton()
        configureRightBarButton()
    }
    
    private func configureLeftBarButton() {
        if isEditing {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: MEGAAssets.UIImage.selectAllItems,
                style: .plain,
                target: self,
                action: #selector(selectAllButtonPressed(_:))
            )
        } else {
            leftBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: TokenColors.Text.primary], for: .normal)
            navigationItem.leftBarButtonItem = leftBarButtonItem
        }
    }
    
    private func configureRightBarButton() {
        if isEditing {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelButtonPressed(_:))
            )
            
            navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: TokenColors.Text.primary], for: .normal)
        } else {
            rightBarButtonItem.isEnabled = true
            navigationItem.rightBarButtonItem = photoLibraryContentViewModel.library.isEmpty ? nil : rightBarButtonItem
        }
    }
    
    private func startEditingMode() {
        setEditing(true, animated: true)
        enablePhotoLibraryEditMode(isEditing)
        updateNavigationTitle(withSelectedPhotoCount: 0)
        
        configureBarButtons()
        configureToolbarButtons()
        
        showToolbar()
    }
    
    private func excuteCommand(_ command: MediaDiscoveryViewModel.Command) {
        switch command {
        case .loadMedia(let nodes):
            updatePhotoLibrary(by: nodes)
            
            if nodes.isEmpty {
                rightBarButtonItem.isEnabled = false
                showEmptyView()
            } else if emptyView.superview != nil {
                rightBarButtonItem.isEnabled = true
                emptyView.removeFromSuperview()
            }
        case .showSaveToPhotosError(let error):
            SVProgressHUD.show(MEGAAssets.UIImage.saveToPhotos,
                               status: error)
        case .endEditingMode:
            endEditingMode()
        }
    }
    
    private func showEmptyView() {
        view.addSubview(emptyView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        emptyView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
    }
    
    // MARK: Overrides
    
    override func selectedNodes() -> [MEGANode]? {
        selection.nodes
    }
    
    override func endEditingMode() {
        setEditing(false, animated: true)
        
        enablePhotoLibraryEditMode(isEditing)
        configureBarButtons()
        
        navigationItem.title = folderName
        
        hideToolbar()
    }
    
    override func showToolbar() {
        toolbar.alpha = 0.0
        view.addSubview(toolbar)
        
        let bottomAnchor: NSLayoutYAxisAnchor = view.safeAreaLayoutGuide.bottomAnchor
        let leadingAnchor: NSLayoutXAxisAnchor = view.safeAreaLayoutGuide.leadingAnchor
        let trailingAnchor: NSLayoutXAxisAnchor = view.safeAreaLayoutGuide.trailingAnchor
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = UIColor.surface1Background()
        toolbar.heightAnchor.constraint(equalToConstant: 64.0).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        toolbar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 1.0
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonPressed(_ barButtonItem: UIBarButtonItem) {
        endEditingMode()
    }
    
    @objc private func editButtonPressed(_ barButtonItem: UIBarButtonItem) {
        startEditingMode()
    }
    
    @objc private func exitButtonTapped(_ barButtonItem: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func selectAllButtonPressed(_ barButtonItem: UIBarButtonItem) {
        configPhotoLibrarySelectAll()
        configureToolbarButtons()
    }
    
    override func configureToolbarButtons() {
        if contentMode == .mediaDiscoveryFolderLink {
            if mediaDiscoveryFolderLinkToolbarConfigurator == nil {
                mediaDiscoveryFolderLinkToolbarConfigurator = MediaDiscoveryFolderLinkToolbarConfigurator(
                    importAction: importBarButtonPressed,
                    downloadAction: downloadBarButtonPressed,
                    saveToPhotosAction: saveToPhotosBarButtonPressed,
                    shareLinkAction: shareLinkBarButtonPressed
                )
            }
            toolbar.items = mediaDiscoveryFolderLinkToolbarConfigurator?.toolbarItems(forNodes: selectedNodes())
        } else {
            super.configureToolbarButtons()
        }
    }
    
    private func importBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.importPhotos(selection.nodes.toNodeEntities()))
    }
    
    private func downloadBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.downloadSelectedPhotos(selection.nodes.toNodeEntities()))
    }
    
    private var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    private var permissionRouter: some PermissionAlertRouting {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
    }
    
    private func saveToPhotosBarButtonPressed(_ button: UIBarButtonItem) {
        permissionHandler.photosPermissionWithCompletionHandler { [weak self] granted in
            guard let self else { return }
            if granted {
                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                
                viewModel.dispatch(.saveToPhotos(selection.nodes.toNodeEntities()))
            } else {
                permissionRouter.alertPhotosPermission()
            }
        }
    }
    
    private func shareLinkBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.shareLink(button))
    }
}
