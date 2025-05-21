import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAUI
import MEGAUIKit

class FilesExplorerContainerViewController: UIViewController, TextFileEditable {
    // MARK: - Private variables
    
    enum ViewPreference {
        case list
        case grid
        case both
    }

    private let viewModel: FilesExplorerViewModel
    private var uploadViewModel: HomeUploadingViewModel?
    private let viewPreference: ViewPreference
    
    private var contextBarButtonItem = UIBarButtonItem()
    private var uploadAddBarButonItem = UIBarButtonItem()
    
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.hidesNavigationBarDuringPresentation = false
        return sc
    }()
    
    // MARK: - States

    lazy var currentState = states[FilesExplorerContainerListViewState.identifier]!
    lazy var states = [
        FilesExplorerContainerListViewState.identifier:
            FilesExplorerContainerListViewState(containerViewController: self,
                                                viewModel: viewModel),
        FilesExplorerContainerGridViewState.identifier:
            FilesExplorerContainerGridViewState(containerViewController: self,
                                                viewModel: viewModel)
    ]
    
    // MARK: -
    
    init(viewModel: FilesExplorerViewModel, viewPreference: ViewPreference) {
        self.viewModel = viewModel
        self.viewPreference = viewPreference
        super.init(nibName: nil, bundle: nil)
        if self.viewModel.getExplorerType() == .allDocs, UserDefaults.standard.integer(forKey: MEGAExplorerViewModePreference) == ViewModePreferenceEntity.thumbnail.rawValue, viewPreference != .list {
            currentState = states[FilesExplorerContainerGridViewState.identifier]!
        } else {
            currentState = states[FilesExplorerContainerListViewState.identifier]!
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentState.showContent()
        configureNavigationBarButtons()
        configureSearchBar()
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    // MARK: - Bar Buttons    
    func updateTitle(_ title: String?) {
        self.title = title
    }
    
    func showCancelRightBarButton() {
        navigationItem.rightBarButtonItems = [UIBarButtonItem(
            title: Strings.Localizable.cancel,
            style: .plain,
            target: self,
            action: #selector(cancelButtonPressed(_:)))]
    }
    
    func showSelectAllBarButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: MEGAAssets.UIImage.selectAllItems,
            style: .plain,
            target: self,
            action: #selector(selectAllButtonPressed(_:))
        )
    }
    
    func hideKeyboardIfRequired() {
        if searchController.isActive {
            searchController.searchBar.resignFirstResponder()
        }
    }
    
    func updateSearchResults() {
        updateSearchResults(for: searchController)
    }
    
    func configureNavigationBarToDefault() {
        configureNavigationBarButtons()
        navigationItem.leftBarButtonItem = nil
        updateTitle(currentState.title)
        navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: currentState.title ?? "")
    }
    
    func setViewModePreference(_ preference: ViewModePreferenceEntity) {
        assert(preference != .perFolder, "Preference cannot be per folder")
        UserDefaults.standard.setValue(preference.rawValue, forKey: MEGAExplorerViewModePreference)
        viewModel.dispatch(.didChangeViewMode(preference.rawValue))
    }
    
    func showMoreButton(_ show: Bool) {
        contextBarButtonItem.isEnabled = show
        if viewModel.getExplorerType() == .allDocs {
            uploadAddBarButonItem.isEnabled = show
        }
    }
    
    func showSelectButton(_ show: Bool) {
        if show {
            showSelectAllBarButton()
            showCancelRightBarButton()
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    private func configureNavigationBarButtons() {
        contextBarButtonItem.image = MEGAAssets.UIImage.moreList
        
        if viewModel.getExplorerType() == .allDocs {
            uploadAddBarButonItem.image = MEGAAssets.UIImage.navigationbarAdd

            navigationItem.rightBarButtonItems = [contextBarButtonItem, uploadAddBarButonItem]
        } else {
            navigationItem.rightBarButtonItem = contextBarButtonItem
        }
    }
    
    func audioPlayer(hidden: Bool) {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.playerHidden(hidden, presenter: self)
        }
    }
    
    func updateContextMenu(menu: UIMenu) {
        contextBarButtonItem.menu = menu
    }
    
    func updateUploadAddMenu(menu: UIMenu) {
        uploadAddBarButonItem.menu = menu
    }
    
    func updateCurrentState() {
        currentState.toggleState()
    }
    
    func didSelect(action: UploadAddActionEntity) {
        if uploadViewModel == nil, let navigationController {
            let uploadViewModel = HomeUploadingViewModel(
                uploadFilesUseCase: UploadPhotoAssetsUseCase(
                    uploadPhotoAssetsRepository: UploadPhotoAssetsRepository(store: MEGAStore.shareInstance())
                ),
                permissionHandler: DevicePermissionsHandler.makeHandler(),
                networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
                createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo),
                tracker: DIContainer.tracker,
                router: FileUploadingRouter(navigationController: navigationController, baseViewController: self, photoPicker: MEGAPhotoPicker(presenter: navigationController), remoteFeatureFlagUseCase: RemoteFeatureFlagUseCase(repository: RemoteFeatureFlagRepository.newRepo))
            )
            self.uploadViewModel = uploadViewModel
        }
        
        switch action {
        case .newTextFile:
            uploadViewModel?.didTapUploadFromNewTextFile()
        case .scanDocument:
            uploadViewModel?.didTapUploadFromDocumentScan()
        case .importFrom:
            uploadViewModel?.didTapUploadFromImports()
        default: break
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonPressed(_ button: UIBarButtonItem) {
        currentState.endEditingMode()
    }
    
    @objc private func selectAllButtonPressed(_ button: UIBarButtonItem) {
        currentState.toggleSelectAllNodes()
    }
    
    func configureSearchBar() {
        if navigationItem.searchController == nil {
            navigationItem.searchController = searchController
        }
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar, 
                                               backgroundColorWhenDesignTokenEnable: UIColor.surface1Background())
    }
}

// MARK: - UISearchResultsUpdating
extension FilesExplorerContainerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, searchText.isNotEmpty else {
            currentState.updateSearchResults(for: nil)
            return
        }
        
        currentState.updateSearchResults(for: searchText)
    }
}

extension FilesExplorerContainerViewController: TraitEnvironmentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar,
                                               backgroundColorWhenDesignTokenEnable: UIColor.surface1Background())
    }
}

// MARK: - AudioPlayer
extension FilesExplorerContainerViewController: AudioPlayerPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}
