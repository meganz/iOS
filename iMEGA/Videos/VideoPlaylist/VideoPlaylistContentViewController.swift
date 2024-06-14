import Combine
import MEGADomain
import MEGASDKRepo
import SwiftUI
import UIKit
import Video

final class VideoPlaylistContentViewController: UIViewController {
    
    private let videoConfig: VideoConfig
    private let videoPlaylistEntity: VideoPlaylistEntity
    private let videoPlaylistContentsUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let router: any VideoRevampRouting
    private let presentationConfig: VideoPlaylistContentSnackBarPresentationConfig
    
    private var snackBarContainer: UIView?
    
    private let moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage.moreNavigationBar, style: .plain, target: nil, action: nil)
    
    private lazy var contextMenuManager = ContextMenuManager(
        displayMenuDelegate: self,
        createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
    )
    
    private let sharedUIState = VideoPlaylistContentSharedUIState()
    private var subscriptions = Set<AnyCancellable>()
    private var snackBarViewModel: SnackBarViewModel?
    private var showSnackBarSubscription: AnyCancellable?
    
    init(
        videoConfig: VideoConfig,
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: some VideoPlaylistContentsUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        router: some VideoRevampRouting,
        presentationConfig: VideoPlaylistContentSnackBarPresentationConfig,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol
    ) {
        self.videoConfig = videoConfig
        self.videoPlaylistEntity = videoPlaylistEntity
        self.videoPlaylistContentsUseCase = videoPlaylistContentsUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.router = router
        self.presentationConfig = presentationConfig
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupContentView()
        configureSnackBarPresenter()
        listenToSnackBarPresentation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeSnackBarPresenter()
    }
    
    private func setupContentView() {
        let contentView = VideoRevampFactory.makeVideoContentContainerView(
            videoConfig: videoConfig,
            previewEntity: videoPlaylistEntity,
            videoPlaylistContentUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            router: router,
            sharedUIState: sharedUIState,
            presentationConfig: presentationConfig
        )
        
        add(contentView, container: view, animate: false)
        
        view.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
    }
    
    private func setupNavigationBar() {
        if videoPlaylistEntity.type == .user {
            navigationItem.rightBarButtonItems = [moreBarButtonItem]
        }
        setupContextMenuBarButton()
        
        if let navigationBar = navigationController?.navigationBar {
            AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
        }
    }
}

// MARK: - VideoPlaylistContentViewController+ContextMenu

extension VideoPlaylistContentViewController {
    
    private func setupContextMenuBarButton() {
        guard videoPlaylistEntity.type == .user else {
            return
        }
        
        Publishers.CombineLatest(
            sharedUIState.$videosCount.map { $0 == 0 }.removeDuplicates(),
            sortOrderChangedSequence()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isEmptyVideos, sortOrder in
            self?.setupMoreBarButtonItem(isEmptyState: isEmptyVideos, sortOrder: sortOrder)
        }
        .store(in: &subscriptions)
    }
    
    private func sortOrderChangedSequence() -> AnyPublisher<SortOrderEntity, Never> {
        sortOrderPreferenceUseCase.monitorSortOrder(for: . videoPlaylistContent)
            .map { [weak self] sortOrder in
                guard let self else {
                    return SortOrderEntity.defaultAsc
                }
                return doesSupport(sortOrder) ? sortOrder : .defaultAsc
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private func doesSupport(_ sortOrder: SortOrderEntity) -> Bool {
        [.defaultAsc, .defaultDesc, .modificationAsc, .modificationDesc].contains(sortOrder)
    }
    
    private func setupMoreBarButtonItem(isEmptyState: Bool, sortOrder: SortOrderEntity) {
        let contextMenuConfiguration = CMConfigEntity(
            menuType: .menu(type: .videoPlaylistContent),
            sortType: sortOrder,
            isVideoPlaylistContent: true,
            isSelectHidden: false,
            isEmptyState: isEmptyState
        )
        
        moreBarButtonItem.menu = contextMenuManager.contextMenu(with: contextMenuConfiguration)
    }
}

// MARK: - TabContainerViewController+DisplayMenuDelegate

extension VideoPlaylistContentViewController: DisplayMenuDelegate {
    
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        sharedUIState.selectedDisplayActionEntity = action
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        guard doesSupport(sortType.toSortOrderEntity()) else {
            return
        }
        sortOrderPreferenceUseCase.save(sortOrder: sortType.toSortOrderEntity(), for: .videoPlaylistContent)
    }
}

extension VideoPlaylistContentViewController: SnackBarPresenting {
    
    private func listenToSnackBarPresentation() {
        snackBarViewModel = makeSnackBarViewModel(message: sharedUIState.snackBarText)
        
        sharedUIState.$shouldShowSnackBar
            .removeDuplicates()
            .filter { $0 == true }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.snackBarViewModel?.update(snackBar: SnackBar(message: self.sharedUIState.snackBarText))
                guard let snackBar = self.snackBarViewModel?.snackBar else { return }
                SnackBarRouter.shared.present(snackBar: snackBar)
            }
            .store(in: &subscriptions)
    }
    
    private func makeSnackBarViewModel(message: String) -> SnackBarViewModel {
        showSnackBarSubscription?.cancel()
        
        let snackBar = SnackBar(message: message)
        let viewModel = SnackBarViewModel(snackBar: snackBar)
        
        showSnackBarSubscription = viewModel.$isShowSnackBar
            .filter { !$0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                snackBarViewModel = nil
            }
        return viewModel
    }
    
    @MainActor
    func layout(snackBarView: UIView?) {
        snackBarContainer?.removeFromSuperview()
        snackBarContainer = snackBarView
        snackBarContainer?.backgroundColor = .clear
        
        guard let snackBarView else {
            return
        }
        
        snackBarView.translatesAutoresizingMaskIntoConstraints = false
        let toolbarHeight = (navigationController?.toolbar.isHidden == true) ? 0 : (navigationController?.toolbar.frame.height ?? 0)
        let bottomOffset: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > 0 ? 32 : 0
        
        [
            snackBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            snackBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            snackBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -toolbarHeight - bottomOffset)
        ].activate()
    }
    
    func snackBarContainerView() -> UIView? {
        snackBarContainer
    }
    
    private func configureSnackBarPresenter() {
        SnackBarRouter.shared.configurePresenter(self)
    }

    private func removeSnackBarPresenter() {
        SnackBarRouter.shared.removePresenter()
    }
}
