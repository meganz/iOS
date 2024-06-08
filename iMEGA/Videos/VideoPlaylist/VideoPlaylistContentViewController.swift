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
        router: some VideoRevampRouting
    ) {
        self.videoConfig = videoConfig
        self.videoPlaylistEntity = videoPlaylistEntity
        self.videoPlaylistContentsUseCase = videoPlaylistContentsUseCase
        self.thumbnailUseCase = thumbnailUseCase
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
    
    func setupContextMenuBarButton() {
        guard videoPlaylistEntity.type == .user else {
            return
        }
        
        sharedUIState.$videosCount
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.setupMoreBarButtonItem(from: count)
            }
            .store(in: &subscriptions)
    }
    
    private func setupMoreBarButtonItem(from videosCount: Int) {
        let contextMenuConfiguration = CMConfigEntity(
            menuType: .menu(type: .videoPlaylistContent),
            sortType: SortOrderEntity.creationAsc,
            isVideoPlaylistContent: true,
            isSelectHidden: false,
            isEmptyState: videosCount == 0
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
        sharedUIState.selectedSortOrderEntity = sortType.toSortOrderEntity()
    }
}
