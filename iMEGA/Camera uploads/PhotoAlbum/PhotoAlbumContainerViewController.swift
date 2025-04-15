import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPhotos
import MEGARepo
import MEGAUIKit
import SwiftUI
import UIKit

final class PhotoAlbumContainerViewController: UIViewController {
    var photoViewController: PhotosViewController?
    
    lazy var toolbar = UIToolbar()
    
    override var isEditing: Bool {
        willSet {
            pageTabViewModel.isEditing = newValue
            pageController.dataSource = newValue ? nil : self
            pageTabHostingController?.view?.isUserInteractionEnabled = !newValue
        }
    }
    private lazy var photoAlbumContainerInteractionManager = PhotoAlbumContainerInteractionManager()
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.searchBar.delegate = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = true
        controller.searchBar.isTranslucent = false
        return controller
    }()
    private lazy var pageController: PhotosPageViewController = {
        PhotosPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }()
    
    let pageTabViewModel = PagerTabViewModel(tracker: DIContainer.tracker)
    let viewModel = PhotoAlbumContainerViewModel(
        tracker: DIContainer.tracker,
        overDiskQuotaChecker: OverDiskQuotaChecker(
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            appDelegateRouter: AppDelegateRouter()))
    
    private var subscriptions = Set<AnyCancellable>()
    private var pageTabHostingController: UIHostingController<PageTabView>?
    private var albumHostingController: UIViewController?
    private var visualMediaSearchResultsViewController: UIViewController?
    private var visualMediaSearchResultsViewModel: VisualMediaSearchResultsViewModel?
    
    var leftBarButton: UIBarButtonItem?
    lazy var shareLinkBarButton = UIBarButtonItem(image: UIImage(resource: .link),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(shareLinksButtonPressed))
    lazy var removeLinksBarButton = UIBarButtonItem(image: UIImage(resource: .removeLink),
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(removeLinksButtonPressed))
    lazy var deleteBarButton = UIBarButtonItem(image: UIImage(resource: .rubbishBin),
                                               style: .plain,
                                               target: self,
                                               action: #selector(deleteAlbumButtonPressed))
    lazy var selectBarButton = UIBarButtonItem(image: UIImage(resource: .selectAllItems).withRenderingMode(.alwaysTemplate).withTintColor(TokenColors.Icon.primary),
                                               style: .plain,
                                               target: self,
                                               action: #selector(toggleEditing))
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setUpPhotosAndAlbumsControllers()
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: Strings.Localizable.Photo.Navigation.title)
        configureSearchBar()
        setUpPagerTabView()
        setUpPageViewController()
        
        view.backgroundColor = TokenColors.Background.page
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        pageController.canScroll = false
        
        updatePageTabViewLayout()
        updatePageViewControllerLayout()
        
        coordinator.animate(alongsideTransition: nil) { _ in
            self.pageTabViewModel.tabOffset = CGFloat(self.pageController.currentPage.index) * self.pageController.view.bounds.size.width / 2
            self.pageController.canScroll = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.didAppear()
        pageTabViewModel.didAppear()
        configureAdsVisibility()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        configureAdsVisibility()
    }
    
    // MARK: Internal
    
    func showViewController(at page: PhotoLibraryTab) -> UIViewController? {
        var currentViewController: UIViewController?
        
        switch page {
        case .timeline: currentViewController = photoViewController
        case .album: currentViewController = albumHostingController
        }
        
        return currentViewController
    }
    
    func page(of viewController: UIViewController?) -> PhotoLibraryTab {
        switch viewController {
        case is PhotosViewController:
            return .timeline
        case is UIHostingController<AlbumListView>:
            return .album
        default:
            return .timeline
        }
    }
    
    func updateCurrentPage(_ page: PhotoLibraryTab) {
        pageController.currentPage = page
        pageTabViewModel.selectedTab = page
    }
    
    func isTimelineActive() -> Bool {
        pageTabViewModel.selectedTab == .timeline
    }
    
    // MARK: - Private
    
    private func setUpPhotosAndAlbumsControllers() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Photos", bundle: nil)
        photoViewController = storyboard.instantiateViewController(withIdentifier: "photoViewController") as? PhotosViewController
        
        if let photoViewController = photoViewController {
            let photoUpdatePublisher = PhotoUpdatePublisher(photosViewController: photoViewController)
            let photoLibraryRepository = PhotoLibraryRepository(
                cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
            let fileSearchRepository = FilesSearchRepository.newRepo
            let hiddenNodesFeatureFlagEnabled = { @Sendable in DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) }
            let photoLibraryUseCase = PhotoLibraryUseCase(
                photosRepository: photoLibraryRepository,
                searchRepository: fileSearchRepository,
                sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                    sensitiveNodeUseCase: SensitiveNodeUseCase(
                        nodeRepository: NodeRepository.newRepo,
                        accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
                    contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                        repo: UserAttributeRepository.newRepo),
                    hiddenNodesFeatureFlagEnabled: hiddenNodesFeatureFlagEnabled),
                hiddenNodesFeatureFlagEnabled: hiddenNodesFeatureFlagEnabled,
                searchByNodeTagsFeatureFlagEnabled: {
                    DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .searchByNodeTags)
                }
            )
            let viewModel = PhotosViewModel(
                photoUpdatePublisher: photoUpdatePublisher,
                photoLibraryUseCase: photoLibraryUseCase,
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                    repo: UserAttributeRepository.newRepo),
                sortOrderPreferenceUseCase: SortOrderPreferenceUseCase(
                    preferenceUseCase: PreferenceUseCase.default,
                    sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo),
                monitorCameraUploadUseCase: MonitorCameraUploadUseCase(
                    cameraUploadRepository: CameraUploadsStatsRepository.newRepo,
                    networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
                    preferenceUseCase: PreferenceUseCase.default),
                devicePermissionHandler: DevicePermissionsHandler.makeHandler(),
                cameraUploadsSettingsViewRouter: CameraUploadsSettingsViewRouter(presenter: navigationController) { }
            )
            photoViewController.viewModel = viewModel
            photoViewController.photoUpdatePublisher = photoUpdatePublisher
        }
        
        albumHostingController = AlbumListViewRouter(photoAlbumContainerViewModel: viewModel).build()
        
        photoViewController?.parentPhotoAlbumsController = self
        photoViewController?.configureMyAvatarManager()
    }
    
    private func configureSearchBar() {
        edgesForExtendedLayout = []
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        
        updateSearchBarAppearance(traitCollection: traitCollection)
        
        photoAlbumContainerInteractionManager.$searchBarText
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchBarText in
                guard let searchBar = self?.navigationItem.searchController?.searchBar,
                      searchBar.text != searchBarText else { return }
                searchBar.text = searchBarText
            }.store(in: &subscriptions)
        
        photoAlbumContainerInteractionManager.pageSwitchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] page in
                guard let self else { return }
                if navigationItem.searchController?.isActive == true {
                    navigationItem.searchController?.isActive = false
                    removeSearchResultsViewController()
                }
                let selectedTab: PhotoLibraryTab = switch page {
                case .timeline: .timeline
                case .album: .album
                }
                pageTabViewModel.selectedTab = selectedTab
            }.store(in: &subscriptions)
    }
    
    private func setUpPagerTabView() {
        let content = PageTabView(viewModel: pageTabViewModel)
        pageTabHostingController = UIHostingController(rootView: content)
        
        guard let hostingController = pageTabHostingController else { return }
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        updatePageTabViewLayout()
        
        hostingController.didMove(toParent: self)
        
        pageTabViewModel.$selectedTab
            .debounce(for: .seconds(0.4), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                if let viewController = showViewController(at: $0) {
                    pageController.setViewControllers(
                        [viewController], direction: $0 == .album ? .forward : .reverse,
                        animated: self.presentedViewController == nil,
                        completion: nil)
                    
                    pageController.currentPage = $0
                }
                if $0 == .album {
                    updateRightBarButton()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func setUpPageViewController() {
        addChild(pageController)
        view.addSubview(pageController.view)
        
        leftBarButton = navigationItem.leftBarButtonItem
        
        pageController.dataSource = self
        pageController.delegate = self
        
        if let viewController = showViewController(at: .timeline) {
            pageController.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
        }
        
        updatePageViewControllerLayout()
        
        pageController.didMove(toParent: self)
        
        pageController.$pageOffset
            .dropFirst()
            .filter { $0 >= 0 && $0 <= self.view.bounds.size.width / 2 }
            .sink { [weak self] in
                self?.pageTabViewModel.tabOffset = $0
            }
            .store(in: &subscriptions)
        
        viewModel.$shouldShowSelectBarButton
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRightBarButton()
            }
            .store(in: &subscriptions)
        
        viewModel.$editMode
            .dropFirst()
            .map { $0.isEditing }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isEditing = $0
                self?.updateBarButtons()
            }
            .store(in: &subscriptions)
        
        viewModel.$isAlbumsSelected
            .removeDuplicates()
            .sink { [weak self] in
                guard let self else { return }
                updateToolbarButtonEnabledState(isSelected: $0)
            }
            .store(in: &subscriptions)
        
        viewModel.$isOnlyExportedAlbumsSelected
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                updateRemoveLinksToolbarButtons(canRemoveLinks: $0)
            }
            .store(in: &subscriptions)
        
        viewModel.$showToolbar
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                $0 ? showToolbar() : hideToolbar()
            }.store(in: &subscriptions)
        
        viewModel.$disableSelectBarButton
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.selectBarButton.isEnabled = !$0
            }.store(in: &subscriptions)
    }
    
    private func updatePageTabViewLayout() {
        guard let hostingController = pageTabHostingController else { return }
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: 38)
        ])
    }
    
    private func updatePageViewControllerLayout() {
        guard let hostingController = pageTabHostingController else { return }
        self.pageController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.pageController.view.topAnchor.constraint(equalTo: hostingController.view.bottomAnchor, constant: 2),
            self.pageController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.pageController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.pageController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func deleteAlbumButtonPressed() {
        viewModel.deleteAlbumsTapped()
    }
    
    @objc private func shareLinksButtonPressed() {
        viewModel.shareLinksTapped()
    }
    
    @objc private func removeLinksButtonPressed() {
        viewModel.removeLinksTapped()
    }
    
    private func showSearchResultsViewController() {
        guard visualMediaSearchResultsViewController == nil else { return }
        let visualMediaSearchResultsViewModel = makeVisualMediaSearchResultsViewModel()
        self.visualMediaSearchResultsViewModel = visualMediaSearchResultsViewModel
        
        let visualMediaSearchResultsViewController = VisualMediaSearchResultsViewControllerFactory
                    .makeViewController(viewModel: visualMediaSearchResultsViewModel)
        self.visualMediaSearchResultsViewController = visualMediaSearchResultsViewController
        
        addChild(visualMediaSearchResultsViewController)
        view.addSubview(visualMediaSearchResultsViewController.view)
        visualMediaSearchResultsViewController.didMove(toParent: self)
        
        visualMediaSearchResultsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualMediaSearchResultsViewController.view.topAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            visualMediaSearchResultsViewController.view.leadingAnchor
                .constraint(equalTo: self.view.leadingAnchor),
            visualMediaSearchResultsViewController.view.trailingAnchor
                .constraint(equalTo: self.view.trailingAnchor),
            visualMediaSearchResultsViewController.view.bottomAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func removeSearchResultsViewController() {
        guard let visualMediaSearchResultsViewController else { return }
        
        visualMediaSearchResultsViewController.willMove(toParent: nil)
        visualMediaSearchResultsViewController.view.removeFromSuperview()
        visualMediaSearchResultsViewController.removeFromParent()
        
        self.visualMediaSearchResultsViewController = nil
        visualMediaSearchResultsViewModel = nil
    }
}

// MARK: - Ads
extension PhotoAlbumContainerViewController: AdsSlotDisplayable {}

// MARK: - UISearchResultsUpdating

extension PhotoAlbumContainerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            return
        }
        visualMediaSearchResultsViewModel?.updateSearchText(searchText)
    }
}

// MARK: - UISearchBarDelegate

extension PhotoAlbumContainerViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showSearchResultsViewController()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        removeSearchResultsViewController()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        Task {
            await visualMediaSearchResultsViewModel?.saveSearch()
        }
    }
}

// MARK: - Visual Media Search

extension PhotoAlbumContainerViewController {
    private func makeVisualMediaSearchResultsViewModel() -> VisualMediaSearchResultsViewModel {
        VisualMediaSearchResultsViewModel(
            photoAlbumContainerInteractionManager: photoAlbumContainerInteractionManager,
            visualMediaSearchHistoryUseCase: makeVisualMediaSearchHistoryUseCase(),
            monitorAlbumsUseCase: makeMonitorAlbumsUseCase(),
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(),
            monitorUserAlbumPhotosUseCase: makeMonitorUserAlbumPhotosUseCase(),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo)),
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            albumCoverUseCase: AlbumCoverUseCase(
                nodeRepository: NodeRepository.newRepo),
            monitorPhotosUseCase: makeMonitorPhotosUseCase(),
            photoSearchResultRouter: PhotoSearchResultRouter(
                presenter: self,
                nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                    viewController: self,
                    moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: self)
                ),
                backupsUseCase: BackupsUseCase(
                    backupsRepository: BackupsRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo)
            ))
    }
    
    private func makeVisualMediaSearchHistoryUseCase() -> some VisualMediaSearchHistoryUseCaseProtocol {
        VisualMediaSearchHistoryUseCase(
            visualMediaSearchHistoryRepository: VisualMediaSearchHistoryCacheRepository.sharedRepo)
    }
    
    private func makeMonitorAlbumsUseCase() -> some MonitorAlbumsUseCaseProtocol {
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo))
        
        return MonitorAlbumsUseCase(
            monitorPhotosUseCase: MonitorPhotosUseCase(
                photosRepository: PhotosRepository.sharedRepo,
                photoLibraryUseCase: makePhotoLibraryUseCase(),
                sensitiveNodeUseCase: sensitiveNodeUseCase),
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            userAlbumRepository: UserAlbumRepository.newRepo,
            photosRepository: PhotosRepository.sharedRepo,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
    
    private func makePhotoLibraryUseCase() -> some PhotoLibraryUseCaseProtocol {
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        return PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: FilesSearchRepository.newRepo,
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            },
            searchByNodeTagsFeatureFlagEnabled: {
                DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .searchByNodeTags)
            }
        )
    }
    
    private func makeSensitiveDisplayPreferenceUseCase() -> some SensitiveDisplayPreferenceUseCaseProtocol {
        SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
    
    private func makeMonitorUserAlbumPhotosUseCase() -> some MonitorUserAlbumPhotosUseCaseProtocol {
        MonitorUserAlbumPhotosUseCase(
            userAlbumRepository: UserAlbumCacheRepository.newRepo,
            photosRepository: PhotosRepository.sharedRepo,
            sensitiveNodeUseCase: makeSensitiveNodeUseCase()
        )
    }
    
    private func makeMonitorPhotosUseCase() -> some MonitorPhotosUseCaseProtocol {
        MonitorPhotosUseCase(
            photosRepository: PhotosRepository.sharedRepo,
            photoLibraryUseCase: makePhotoLibraryUseCase(),
            sensitiveNodeUseCase: makeSensitiveNodeUseCase())
    }
    
    private func makeSensitiveNodeUseCase() -> some SensitiveNodeUseCaseProtocol {
        SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo)
        )
    }
    
    private func updateSearchBarAppearance(traitCollection: UITraitCollection) {
        AppearanceManager.forceSearchBarUpdate(
            searchController.searchBar,
            backgroundColorWhenDesignTokenEnable: UIColor.surface1Background())
    }
}

extension PhotoAlbumContainerViewController: TraitEnvironmentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        updateSearchBarAppearance(traitCollection: currentTrait)
    }
}

extension PhotoAlbumContainerViewController: BottomOverlayPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}
