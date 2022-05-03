import UIKit

@available(iOS 14.0, *)
final class MediaDiscoveryViewController: ExplorerBaseViewController {
    private var nodes: [MEGANode] = []
    private let folderName: String
    
    lazy var rightBarButtonItem = UIBarButtonItem(
        image: Asset.Images.NavigationBar.selectAll.image,
        style: .plain,
        target: self,
        action: #selector(editButtonPressed(_:))
    )
    
    lazy var leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.CloudDrive.MediaDiscovery.exit,
                                                 style:.plain,
                                                 target: self,
                                                 action: #selector(exitButtonTapped(_:))
    )
    
    lazy var photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
    lazy var photoLibraryPublisher = PhotoLibraryPublisher(viewModel: photoLibraryContentViewModel)
    lazy var selection = PhotoSelectionAdapter(sdk: MEGASdkManager.sharedMEGASdk())
    
    private let viewModel: MediaDiscoveryViewModel
    
    // MARK: - Init
    
    @objc init(viewModel: MediaDiscoveryViewModel, folderName: String) {
        self.viewModel = viewModel
        self.folderName = folderName
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildNavigationBar()
        
        configPhotoLibraryView(in: view)
        setupPhotoLibrarySubscriptions()
        
        MEGASdkManager.sharedMEGASdk().add(self)
        
        viewModel.invokeCommand = { [weak self] command in
            self?.excuteCommand(command)
        }
        
        viewModel.dispatch(.onViewReady)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
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
                image: Asset.Images.NavigationBar.selectAll.image,
                style: .plain,
                target: self,
                action: #selector(selectAllButtonPressed(_:))
            )
        } else {
            leftBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.MediaDiscovery.exitButtonTint.color], for: .normal)
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
            navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.MediaDiscovery.exitButtonTint.color], for: .normal)
        } else {
            rightBarButtonItem.isEnabled = !photoLibraryContentViewModel.library.isEmpty
            navigationItem.rightBarButtonItem = rightBarButtonItem
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
            }
        }
    }
    
    private func showEmptyView() {
        let emptyView = EmptyStateView.create(for: .photos)
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
        toolbar.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
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
}

@available(iOS 14.0, *)
extension MediaDiscoveryViewController: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let list = nodeList else { return }
        
        viewModel.dispatch(.onNodesUpdate(nodeList: list))
    }
}
