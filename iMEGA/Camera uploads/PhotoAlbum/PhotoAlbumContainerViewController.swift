import Combine
import ContentLibraries
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPhotos
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
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
    private let isVisualMediaSearchFeatureEnabled = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .visualMediaSearch)
    private lazy var searchBarTextFieldUpdater = SearchBarTextFieldUpdater()
    private lazy var searchController: UISearchController = {
        let resultController = VisualMediaSearchResultsViewControllerFactory
            .makeViewController(viewModel: makeVisualMediaSearchResultsViewModel())
        let controller = UISearchController(searchResultsController: resultController)
        controller.searchResultsUpdater = resultController
        controller.searchBar.delegate = resultController
        controller.delegate = self
        controller.obscuresBackgroundDuringPresentation = false
        return controller
    }()
    private lazy var pageController: PhotosPageViewController = {
        PhotosPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }()
    
    let pageTabViewModel = PagerTabViewModel(tracker: DIContainer.tracker)
    let viewModel = PhotoAlbumContainerViewModel(tracker: DIContainer.tracker)
    
    private var subscriptions = Set<AnyCancellable>()
    private var pageTabHostingController: UIHostingController<PageTabView>?
    private var albumHostingController: UIViewController?
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
                hiddenNodesFeatureFlagEnabled: hiddenNodesFeatureFlagEnabled)
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
        guard isVisualMediaSearchFeatureEnabled else { return }
        navigationItem.searchController = searchController
        extendedLayoutIncludesOpaqueBars = true
        
        searchBarTextFieldUpdater.$searchBarText
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchBarText in
                guard let searchBar = self?.navigationItem.searchController?.searchBar,
                      searchBar.text != searchBarText else { return }
                searchBar.text = searchBarText
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
                if let viewController = self?.showViewController(at: $0) {
                    self?.pageController.setViewControllers([viewController], direction: $0 == .album ? .forward : .reverse, animated: true, completion: nil)
                    self?.pageController.currentPage = $0
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
        
        pageTabViewModel.$selectedTab
            .filter { $0 == .album }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRightBarButton()
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
        viewModel.showDeleteAlbumAlert.toggle()
    }
    
    @objc private func shareLinksButtonPressed() {
        viewModel.shareLinksTapped()
    }
    
    @objc private func removeLinksButtonPressed() {
        viewModel.showRemoveAlbumLinksAlert.toggle()
    }
}

// MARK: - Ads
extension PhotoAlbumContainerViewController {
    @objc func configureAdsVisibility() {
        guard let mainTabBar = UIApplication.mainTabBarRootViewController() as? MainTabBarController else { return }
        mainTabBar.configureAdsVisibility()
    }
}

// MARK: - UISearchControllerDelegate

extension PhotoAlbumContainerViewController: UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        searchController.showsSearchResultsController = true
    }
}

// MARK: - Visual Media Search

extension PhotoAlbumContainerViewController {
    private func makeVisualMediaSearchResultsViewModel() -> VisualMediaSearchResultsViewModel {
        VisualMediaSearchResultsViewModel(
            searchBarTextFieldUpdater: searchBarTextFieldUpdater,
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
                nodeRepository: NodeRepository.newRepo))
    }
    
    private func makeVisualMediaSearchHistoryUseCase() -> some VisualMediaSearchHistoryUseCaseProtocol {
        VisualMediaSearchHistoryUseCase(
            visualMediaSearchHistoryRepository: VisualMediaSearchHistoryCacheRepository.newRepo)
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
        return PhotoLibraryUseCase(photosRepository: photoLibraryRepository,
                                   searchRepository: FilesSearchRepository.newRepo,
                                   sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
                                   hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
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
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo))
        )
    }
}
