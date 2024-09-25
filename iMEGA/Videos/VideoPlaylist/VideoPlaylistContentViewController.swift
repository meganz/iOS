import Combine
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI
import UIKit
import Video

final class VideoPlaylistContentViewController: UIViewController {
    
    private let videoConfig: VideoConfig
    private let videoPlaylistEntity: VideoPlaylistEntity
    private let videoPlaylistContentsUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let videoPlaylistUseCase: any VideoPlaylistUseCaseProtocol
    private let videoPlaylistModificationUseCase: any VideoPlaylistModificationUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let router: any VideoRevampRouting
    private let presentationConfig: VideoPlaylistContentSnackBarPresentationConfig
    private let syncModel: VideoRevampSyncModel
    
    private var snackBarContainer: UIView?
    
    private let moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage.moreNavigationBar, style: .plain, target: nil, action: nil)
    
    private lazy var contextMenuManager = ContextMenuManager(
        displayMenuDelegate: self,
        quickActionsMenuDelegate: self,
        createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo),
        videoPlaylistMenuDelegate: self
    )
    private lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    private(set) var sharedUIState = VideoPlaylistContentSharedUIState()
    private var subscriptions = Set<AnyCancellable>()
    private var showSnackBarSubscription: AnyCancellable?
    
    private let videoSelection: VideoSelection
    private let selectionAdapter: VideoPlaylistContentViewModelSelectionAdapter
    private let videoToolbarViewModel = VideoToolbarViewModel()
    private var toolbar = UIToolbar()
    
    init(
        videoConfig: VideoConfig,
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: some VideoPlaylistContentsUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        router: some VideoRevampRouting,
        presentationConfig: VideoPlaylistContentSnackBarPresentationConfig,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        nodeIconUseCase: some NodeIconUsecaseProtocol,
        videoSelection: VideoSelection,
        selectionAdapter: VideoPlaylistContentViewModelSelectionAdapter,
        syncModel: VideoRevampSyncModel
    ) {
        self.videoConfig = videoConfig
        self.videoPlaylistEntity = videoPlaylistEntity
        self.videoPlaylistContentsUseCase = videoPlaylistContentsUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.nodeIconUseCase = nodeIconUseCase
        self.videoPlaylistUseCase = videoPlaylistUseCase
        self.videoPlaylistModificationUseCase = videoPlaylistModificationUseCase
        self.nodeUseCase = nodeUseCase
        self.router = router
        self.presentationConfig = presentationConfig
        self.videoSelection = videoSelection
        self.selectionAdapter = selectionAdapter
        self.syncModel = syncModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupContentView()
        setupNavigationBar()
        subscribeToVideoSelection()
        listenToSelectedDisplayActionChanged()
        listenToVideoSelectionForTitle()
        listenToDidFinishDeleteVideoFromVideoPlaylistContentThenAboutToMoveToRubbishBinAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetsTraitOverridesIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listenToSnackBarPresentation()
    }
    
    private func setupContentView() {
        let contentView = VideoRevampFactory.makeVideoContentContainerView(
            videoConfig: videoConfig,
            previewEntity: videoPlaylistEntity,
            videoPlaylistContentUseCase: videoPlaylistContentsUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            videoPlaylistUseCase: videoPlaylistUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            nodeIconUseCase: nodeIconUseCase,
            nodeUseCase: nodeUseCase,
            router: router,
            sharedUIState: sharedUIState,
            videoSelection: videoSelection,
            selectionAdapter: selectionAdapter,
            presentationConfig: presentationConfig,
            syncModel: syncModel
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
    
    // MARK: - Toolbar
    
    private func subscribeToVideoSelection() {
        videoSelection.$videos
            .map { $0.isNotEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasSelectedItem in
                self?.videoToolbarViewModel.isDisabled = !hasSelectedItem
            }
            .store(in: &subscriptions)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        setupToolbar(editing: editing)
    }
    
    private func setupToolbar(editing: Bool) {
        if editing {
            showToolbar()
        } else {
            hideToolbar()
        }
    }
    
    private func showToolbar() {
        toolbar.alpha = 0
        configureToolbar()
        
        tabBarController?.view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        if let tabBar = tabBarController?.tabBar {
            NSLayoutConstraint.activate([
                toolbar.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: 0),
                toolbar.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: 0),
                toolbar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor, constant: 0),
                toolbar.bottomAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.bottomAnchor, constant: 0)
            ])
        }
        
        UIView.animate(
            withDuration: 0.33,
            animations: { [weak self] in
                self?.toolbar.alpha = 1
            }
        )
    }
    
    private func configureToolbar() {
        toolbar.items = [
            UIBarButtonItem(image: videoConfig.toolbarAssets.offlineImage, style: .plain, target: self, action: #selector(downloadAction(_:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: videoConfig.toolbarAssets.linkImage, style: .plain, target: self, action: #selector(linkAction(_:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: videoConfig.toolbarAssets.saveToPhotosImage, style: .plain, target: self, action: #selector(saveToPhotosAction(_:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage.hudMinus, style: .plain, target: self, action: #selector(removeVideoFromPlaylistAction(_:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: videoConfig.toolbarAssets.moreListImage, style: .plain, target: self, action: #selector(moreAction(_:)))
        ]
        
        configureToolbarAppearance()
    }
    
    private func configureToolbarAppearance() {
        videoToolbarViewModel.$isDisabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDisabled in
                self?.toolbar.items?.forEach { $0.isEnabled = !isDisabled }
            }
            .store(in: &subscriptions)
        
        toolbar.items?.forEach { $0.tintColor = UIColor(videoConfig.colorAssets.primaryIconColor) }
        toolbar.backgroundColor = UIColor(videoConfig.colorAssets.toolbarBackgroundColor)
    }
    
    private func hideToolbar() {
        UIView.animate(
            withDuration: 0.33,
            animations: { [weak self] in
                self?.toolbar.alpha = 0
            },
            completion: {  [weak self] _ in
                self?.toolbar.removeFromSuperview()
            }
        )
    }
    
    @objc private func downloadAction(_ sender: UIBarButtonItem) {
        let nodeActionViewController = nodeActionViewController(with: selectedVideos, from: sender)
        nodeAction(nodeActionViewController, didSelect: .download, forNodes: selectedVideos, from: sender)
    }
    
    @objc private func linkAction(_ sender: UIBarButtonItem) {
        let nodeActionViewController = nodeActionViewController(with: selectedVideos, from: sender)
        nodeAction(nodeActionViewController, didSelect: .manageLink, forNodes: selectedVideos, from: sender)
    }
    
    @objc private func saveToPhotosAction(_ sender: UIBarButtonItem) {
        let nodeActionViewController = nodeActionViewController(with: selectedVideos, from: sender)
        nodeAction(nodeActionViewController, didSelect: .saveToPhotos, forNodes: selectedVideos, from: sender)
    }
    
    @objc private func removeVideoFromPlaylistAction(_ sender: UIBarButtonItem) {
        removeVideoFromPlaylistAction()
    }
    
    func removeVideoFromPlaylistAction() {
        let videos = videoSelection.videos.values.map { $0 }
        guard videos.isNotEmpty else { return }
        sharedUIState.didSelectRemoveVideoFromPlaylistAction.send(videos)
    }
    
    @objc private func moreAction(_ sender: UIBarButtonItem) {
        let nodeActionViewController = nodeActionViewController(with: selectedVideos, from: sender)
        present(nodeActionViewController, animated: true, completion: nil)
    }
    
    func didSelectMoveVideoInVideoPlaylistContentToRubbishBinAction() {
        let videos = videoSelection.videos.values.map { $0 }
        guard videos.isNotEmpty else { return }
        sharedUIState.didSelectMoveVideoInVideoPlaylistContentToRubbishBinAction.send(videos)
    }
    
    private func listenToDidFinishDeleteVideoFromVideoPlaylistContentThenAboutToMoveToRubbishBinAction() {
        sharedUIState.didFinishDeleteVideoFromVideoPlaylistContentThenAboutToMoveToRubbishBinAction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] removedVideosFromVideoPlaylist in
                self?.moveVideoToRubbishBinAction(removedVideosFromVideoPlaylist)
            }
            .store(in: &subscriptions)
    }
    
    private func moveVideoToRubbishBinAction(_ videos: [NodeEntity]) {
        let removedVideosFromVideoPlaylist = videos.compactMap { $0.toMEGANode(in: .sharedSdk) }
        let nodeActionViewController = nodeActionViewController(with: removedVideosFromVideoPlaylist, from: moreBarButtonItem)
        nodeAction(nodeActionViewController, didSelect: .moveToRubbishBin, forNodes: removedVideosFromVideoPlaylist, from: moreBarButtonItem)
    }
    
    func resetNavigationBar() {
        setEditing(false, animated: true)
        videoSelection.editMode = .inactive
        setupNavigationBarButtons()
    }
    
    private func listenToSelectedDisplayActionChanged() {
        sharedUIState.$selectedDisplayActionEntity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedDisplayActionEntity in
                guard let self else { return }
                switch selectedDisplayActionEntity {
                case .select:
                    toggleEditing()
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }
    
    private func toggleEditing() {
        setEditing(!isEditing, animated: true)
        setupNavigationBarButtons()
        videoSelection.editMode = isEditing ? .active : .inactive
    }
    
    private func setupNavigationBarButtons() {
        setupLeftNavigationBarButtons()
        setupRightNavigationBarButtons()
    }
    
    private func setupLeftNavigationBarButtons() {
        navigationItem.setLeftBarButtonItems(isEditing ? [selectAllBarButtonItem] : nil, animated: true)
    }
    
    private func setupRightNavigationBarButtons() {
        navigationItem.setRightBarButtonItems(isEditing ? [cancelBarButtonItem] : [moreBarButtonItem], animated: true)
    }
    
    private lazy var selectAllBarButtonItem = {
        UIBarButtonItem(image: UIImage.selectAllItems, style: .plain, target: self, action: #selector(selectAllBarButtonItemTapped))
    }()
    
    @objc private func selectAllBarButtonItemTapped() {
        sharedUIState.isAllSelected = !sharedUIState.isAllSelected
    }
    
    private lazy var cancelBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonItemTapped))
    }()
    
    @objc private func cancelBarButtonItemTapped() {
        resetNavigationBar()
    }
    
    private func listenToVideoSelectionForTitle() {
        videoSelection.videoPlaylistContentTitlePublisher()
            .receive(on: DispatchQueue.main)
            .sink {  [weak self] navigationItemTitle in
                self?.navigationItem.title = navigationItemTitle
            }
            .store(in: &subscriptions)
    }
    
    private func nodeActionViewController(with selectedVideos: [MEGANode], from sender: UIBarButtonItem) -> NodeActionViewController {
        let viewController = NodeActionViewController(
            nodes: selectedVideos, delegate: self, displayMode: .videoPlaylistContent, sender: sender)
        viewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        return viewController
    }
    
    private var selectedVideos: [MEGANode] {
        videoSelection.videos.values
            .compactMap { $0.toMEGANode(in: .sharedSdk) }
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

// MARK: - TabContainerViewController+QuickActionsMenuDelegate

extension VideoPlaylistContentViewController: QuickActionsMenuDelegate {
    
    func quickActionsMenu(didSelect action: QuickActionEntity, needToRefreshMenu: Bool) {
        sharedUIState.selectedQuickActionEntity = action
    }
}

// MARK: - TabContainerViewController+VideoPlaylistMenuDelegate

extension VideoPlaylistContentViewController: VideoPlaylistMenuDelegate {
    
    func videoPlaylistMenu(didSelect action: VideoPlaylistActionEntity) {
        sharedUIState.selectedVideoPlaylistActionEntity = action
    }
}

// MARK: - SnackBarPresenting

extension VideoPlaylistContentViewController {
    
    private func listenToSnackBarPresentation() {
        sharedUIState.$shouldShowSnackBar
            .filter { $0 == true }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                resetNavigationBar()
                let snackBar = SnackBar(message: sharedUIState.snackBarText)
                showSnackBar(snackBar: snackBar)
            }
            .store(in: &subscriptions)
    }
}
