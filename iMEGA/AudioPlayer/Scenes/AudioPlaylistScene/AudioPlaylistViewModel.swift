import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation

enum AudioPlaylistAction: ActionType {
    case onViewDidLoad
    case move(AudioPlayerItem, IndexPath, MovementDirection)
    case removeSelectedItems
    case didSelect(AudioPlayerItem)
    case didDeselect(AudioPlayerItem)
    case willDraggBegin
    case didDraggEnd
    case dismiss
    case onViewWillDisappear
}

protocol AudioPlaylistViewRouting: Routing {
    func dismiss()
}

final class AudioPlaylistViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case title(title: String)
        case reloadTracks(currentItem: AudioPlayerItem, queue: [AudioPlayerItem]?, selectedIndexPaths: [IndexPath]?)
        case reload(items: [AudioPlayerItem])
        case deselectAll
        case showToolbar
        case hideToolbar
        case enableUserInteraction
        case disableUserInteraction
    }
    
    // MARK: - Private properties
    private let title: String
    private let playerHandler: any AudioPlayerHandlerProtocol
    private let router: any AudioPlaylistViewRouting
    private let tracker: any AnalyticsTracking
    private var selectedItems: [AudioPlayerItem]?
    private var isDataReloadingEnabled = true
    private var pendingItemsToBeUpdatedArray = [AudioPlayerItem]()
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(
        title: String,
        playerHandler: some AudioPlayerHandlerProtocol = AudioPlayerManager.shared,
        router: some AudioPlaylistViewRouting,
        tracker: some AnalyticsTracking
    ) {
        self.title = title
        self.playerHandler = playerHandler
        self.router = router
        self.tracker = tracker
    }
    
    // MARK: - Private functions
    private func initScreen() {
        playerHandler.configurePlayer(listener: self)
        guard !playerHandler.isPlayerEmpty(), let currentItem = playerHandler.playerCurrentItem() else { return }
        invokeCommand?(.reloadTracks(currentItem: currentItem, queue: playerHandler.playerQueueItems(), selectedIndexPaths: selectedIndexPaths()))
        invokeCommand?(.title(title: title))
    }

    private func addSelected(_ item: AudioPlayerItem) {
        if selectedItems == nil {
            selectedItems = [AudioPlayerItem]()
        }
        
        if !(selectedItems?.contains(item) ?? true) {
            selectedItems?.append(item)
        }
    }
    
    private func removeSelected(_ item: AudioPlayerItem) {
        if selectedItems?.contains(item) ?? false,
           let index = selectedItems?.firstIndex(where: { $0 == item }) {
            selectedItems?.remove(at: index)
        }
    }
    
    private func removeAllSelectedItems() {
        guard let items = selectedItems else { return }
        
        playerHandler.delete(items: items)
        selectedItems?.removeAll()
        invokeCommand?(.deselectAll)
        invokeCommand?(.hideToolbar)
    }
    
    private func selectedIndexPaths() -> [IndexPath]? {
        Array(Set(playerHandler.playerQueueItems() ?? [])
                        .intersection(Set(selectedItems ?? []))).compactMap {
            if let ind = playerHandler.playerQueueItems()?.firstIndex(of: $0) {
                return IndexPath(row: ind, section: 1)
            }
            return nil
        }
    }
    
    private func reloadPendingItems() {
        guard isDataReloadingEnabled, pendingItemsToBeUpdatedArray.isNotEmpty else {
            return
        }
        
        invokeCommand?(.reload(items: pendingItemsToBeUpdatedArray))
        pendingItemsToBeUpdatedArray.removeAll()
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: AudioPlaylistAction) {
        switch action {
        case .onViewDidLoad:
            initScreen()
        case .move(let movedItem, let position, let direction):
            trackReorderItemsInPlaylist()
            playerHandler.move(item: movedItem, to: position, direction: direction)
        case .removeSelectedItems:
            trackRemoveTracksButtonTapped()
            removeAllSelectedItems()
        case .didSelect(let item):
            invokeCommand?(.showToolbar)
            addSelected(item)
        case .didDeselect(let item):
            removeSelected(item)
            if selectedItems?.isEmpty ?? true {
                invokeCommand?(.hideToolbar)
            }
        case .dismiss:
            router.dismiss()
        case .onViewWillDisappear:
            playerHandler.removePlayer(listener: self)
        case .willDraggBegin:
            isDataReloadingEnabled = false
        case .didDraggEnd:
            isDataReloadingEnabled = true
            reloadPendingItems()
        }
    }
    
    // MARK: - Analytics
    private func trackReorderItemsInPlaylist() {
        tracker.trackAnalyticsEvent(with: AudioPlayerQueueReorderedEvent())
    }
    
    private func trackRemoveTracksButtonTapped() {
        tracker.trackAnalyticsEvent(with: AudioPlayerQueueItemRemovedEvent())
    }
}

extension AudioPlaylistViewModel: AudioPlayerObserversProtocol {
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, queue: [AudioPlayerItem]?) {
        guard let currentItem = playerHandler.playerCurrentItem() else { return }
        
        invokeCommand?(.reloadTracks(currentItem: currentItem, queue: playerHandler.playerQueueItems(), selectedIndexPaths: selectedIndexPaths()))
    }

    func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?) {
        guard let item = item else { return }
        pendingItemsToBeUpdatedArray.append(item)
        reloadPendingItems()
    }
    
    func audioPlayerWillStartBlockingAction() {
        invokeCommand?(.disableUserInteraction)
    }
    
    func audioPlayerDidFinishBlockingAction() {
        invokeCommand?(.enableUserInteraction)
    }
}
