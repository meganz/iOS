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
    
    private let moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage.moreNavigationBar, style: .plain, target: nil, action: nil)
    
    private lazy var contextMenuManager = ContextMenuManager(
        displayMenuDelegate: self,
        createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
    )
    
    private let sharedUIState = VideoPlaylistContentSharedUIState()
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        videoConfig: VideoConfig,
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: some VideoPlaylistContentsUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        router: some VideoRevampRouting
    ) {
        self.videoConfig = videoConfig
        self.videoPlaylistEntity = videoPlaylistEntity
        self.videoPlaylistContentsUseCase = videoPlaylistContentsUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupContentView()
        setupNavigationBar()
    }
    
    private func setupContentView() {
        let contentView = VideoRevampFactory.makeVideoContentContainerView(
            videoConfig: videoConfig,
            previewEntity: videoPlaylistEntity,
            videoPlaylistContentUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            router: router,
            sharedUIState: sharedUIState
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
