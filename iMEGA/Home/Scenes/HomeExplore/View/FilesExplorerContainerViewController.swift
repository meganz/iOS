
class FilesExplorerContainerViewController: UIViewController, TextFileEditable {
    //MARK:- Private variables
    
    enum ViewPreference {
        case list
        case grid
        case both
    }

    private let viewModel: FilesExplorerViewModel
    private var uploadViewModel: HomeUploadingViewModelType?
    private let viewPreference: ViewPreference
    
    private lazy var selectAllBarButtonItem = UIBarButtonItem(
        image: Asset.Images.Generic.moreList.image,
        style: .plain,
        target: self, action: #selector(moreButtonItemSelected(_:))
    )
    
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.hidesNavigationBarDuringPresentation = false
        return sc
    }()
    
    //MARK:- States

    lazy var currentState = states[FilesExplorerContainerListViewState.identifier]!
    lazy var states = [
        FilesExplorerContainerListViewState.identifier:
            FilesExplorerContainerListViewState(containerViewController: self,
                                                viewModel: viewModel),
        FilesExplorerContainerGridViewState.identifier:
            FilesExplorerContainerGridViewState(containerViewController: self,
                                                viewModel: viewModel)
    ]
    
    //MARK:-
    
    init(viewModel: FilesExplorerViewModel, viewPreference: ViewPreference) {
        self.viewModel = viewModel
        self.viewPreference = viewPreference
        super.init(nibName: nil, bundle: nil)
        if self.viewModel.getExplorerType() == .document, UserDefaults.standard.integer(forKey: MEGAExplorerViewModePreference) == ViewModePreference.thumbnail.rawValue, viewPreference != .list {
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
        showMoreRightBarButton()
        configureSearchBar()
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AudioPlayerManager.shared.addDelegate(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AudioPlayerManager.shared.removeDelegate(self)
    }
    
    //MARK:- Bar Buttons    
    func updateTitle(_ title: String?) {
        self.title = title
    }
    
    func showCancelRightBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: Strings.Localizable.cancel,
            style: .plain,
            target: self,
            action: #selector(cancelButtonPressed(_:)))
    }
    
    func showSelectAllBarButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "selectAll"),
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
        showMoreRightBarButton()
        navigationItem.leftBarButtonItem = nil
        updateTitle(currentState.title)
    }
    
    func setViewModePreference(_ preference: ViewModePreference) {
        assert(preference != .perFolder, "Preference cannot be per folder")
        UserDefaults.standard.setValue(preference.rawValue, forKey: MEGAExplorerViewModePreference)
    }
    
    func showMoreButton(_ show: Bool) {
        selectAllBarButtonItem.isEnabled = show
    }
    
    func showSelectButton(_ show: Bool) {
        if show {
            showSelectAllBarButton()
            showCancelRightBarButton()
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    private func showMoreRightBarButton() {
        navigationItem.rightBarButtonItem = selectAllBarButtonItem
    }
    
    func audioPlayer(hidden: Bool) {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.playerHidden(hidden, presenter: self)
        }
    }
    
    //MARK:- Actions

    @objc private func moreButtonItemSelected(_ button: UIBarButtonItem) {
        currentState.showPreferences(sender: button)
    }
    
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
    }
    
    //MARK:- Action sheet methods
    
    func showPreferences(withViewPreferenceAction viewPreferenceAction: ActionSheetAction?, sender: UIBarButtonItem) {
        let sortPreferenceAction = ActionSheetAction(
            title: Strings.Localizable.sortTitle,
            detail: NSString.localizedSortOrderType(Helper.sortType(for: nil)),
            image: Asset.Images.ActionSheetIcons.sort.image, style: .default) { [weak self] in
            self?.showSortOptions(sender: sender)
        }
        
        let selectAction = ActionSheetAction(
            title: Strings.Localizable.select,
            detail: nil,
            image: Asset.Images.ActionSheetIcons.select.image,
            style: .default) { [weak self] in
            self?.showCancelRightBarButton()
            self?.showSelectAllBarButton()
            self?.currentState.setEditingMode()
        }
        
        var customizeActions:Array<ActionSheetAction>? = []
        if (viewModel.getExplorerType() == .document) {
            let uploadViewModel = HomeUploadingViewModel(
                uploadFilesUseCase: HomeUploadFileUseCase(
                    uploadFromAlbum: .live,
                    uploadFromURL: .live,
                    uploadFromLocalPath: .live
                ),
                devicePermissionUseCase: DevicePermissionRequestUseCase(
                    photoPermission: .live,
                    devicePermission: .live
                ),
                reachabilityUseCase: ReachabilityUseCase(),
                router: FileUploadingRouter(navigationController: navigationController, baseViewController: self)
            )
            self.uploadViewModel = uploadViewModel
            
            let sources: [FileUploadingSourceItem.Source] = [.textFile, .documentScan, .imports]
            for source in sources {
                let item = FileUploadingSourceItem(source: source)
                let action = ActionSheetAction(title: item.title, detail: nil, accessoryView: nil, image: item.icon, style: .default) {
                    switch source {
                    case .textFile:
                        uploadViewModel.didTapUploadFromNewTextFile()
                    case .documentScan:
                        uploadViewModel.didTapUploadFromDocumentScan()
                    case .imports:
                        uploadViewModel.didTapUploadFromImports()
                    default:
                        break
                    }
                }
                customizeActions?.append(action)
            }
        }
        
        var actionList = [sortPreferenceAction, selectAction]
        if let action = viewPreferenceAction {
            actionList.insert(action, at: 0)
        }
        
        if let actions = customizeActions {
            actionList = actions + actionList
        }
        
        let actionSheetVC: ActionSheetViewController
        
        if viewPreference == .list {
            actionSheetVC = ActionSheetViewController(
                actions: [sortPreferenceAction],
                headerTitle: nil,
                dismissCompletion: nil,
                sender: sender
            )
        } else {
            actionSheetVC = ActionSheetViewController(
                actions: actionList,
                headerTitle: nil,
                dismissCompletion: nil,
                sender: sender
            )
        }
        
        present(actionSheetVC, animated: true)
    }
    
    func showSortOptions(sender: UIBarButtonItem) {
        let checkmarkImageView = UIImageView(image: Asset.Images.Generic.turquoiseCheckmark.image)
                
        let actions = SortOrderType.allValid.map { sortOrderType in
            ActionSheetAction(title: sortOrderType.localizedString,
                              detail: nil,
                              accessoryView: SortOrderType.defaultSortOrderType(forNode: nil) == sortOrderType ? checkmarkImageView : nil,
                              image: sortOrderType.image,
                              style: .default) { [weak self] in
                Helper.save(sortOrderType.megaSortOrderType, for: nil)
                
                guard let self = self else { return }
                self.updateSearchResults(for: self.searchController)
            }
        }
        
        let actionSheetVC = ActionSheetViewController(
            actions: actions,
            headerTitle: nil,
            dismissCompletion: nil,
            sender: sender
        )
        
        present(actionSheetVC, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension FilesExplorerContainerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.trim else {
            currentState.updateSearchResults(for: nil)
            return
        }
        
        currentState.updateSearchResults(for: searchText)
    }
}

extension FilesExplorerContainerViewController: TraitEnviromentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar,
                                               traitCollection: traitCollection)
    }
}

// MARK: - AudioPlayer
extension FilesExplorerContainerViewController: AudioPlayerPresenterProtocol {
    func updateContentView(_ height: CGFloat) {
        currentState.updateContentView(height)
    }
}
