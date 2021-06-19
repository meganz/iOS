import Foundation

enum AudioPlaylistAction: ActionType {
    case onViewDidLoad
    case move(AudioPlayerItem, IndexPath, MovementDirection)
    case removeSelectedItems
    case didSelect(AudioPlayerItem)
    case didDeselect(AudioPlayerItem)
    case dismiss
    case `deinit`
}

protocol AudioPlaylistViewRouting: Routing {
    func dismiss()
}

final class AudioPlaylistViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case title(title: String)
        case reloadTracks(currentItem: AudioPlayerItem, queue: [AudioPlayerItem]?, selectedIndexPaths: [IndexPath]?)
        case reload(item: AudioPlayerItem)
        case deselectAll
        case showToolbar
        case hideToolbar
        case enableUserInteraction
        case disableUserInteraction
    }
    
    // MARK: - Private properties
    private let router: AudioPlaylistViewRouting
    private let parentNode: MEGANode?
    private let nodeInfoUseCase: NodeInfoUseCaseProtocol
    private let playerHandler: AudioPlayerHandlerProtocol?
    private var selectedItems: [AudioPlayerItem]?
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: AudioPlaylistViewRouting,
         parentNode: MEGANode?,
         nodeInfoUseCase: NodeInfoUseCaseProtocol,
         playerHandler: AudioPlayerHandlerProtocol?) {
        self.router = router
        self.parentNode = parentNode
        self.playerHandler = playerHandler
        self.nodeInfoUseCase = nodeInfoUseCase
    }
    
    // MARK: - Private functions
    private func initScreen() {
        playerHandler?.addPlayer(listener: self)
        guard let handler = playerHandler, !handler.isPlayerEmpty(), let currentItem = handler.playerCurrentItem() else { return }
        invokeCommand?(.reloadTracks(currentItem: currentItem, queue: handler.playerQueueItems(), selectedIndexPaths: selectedIndexPaths()))
        invokeCommand?(.title(title: parentNode?.name ?? ""))
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
           let index = selectedItems?.firstIndex(where:{$0 == item}) {
            selectedItems?.remove(at: index)
        }
    }
    
    private func removeAllSelectedItems() {
        guard let items = selectedItems else { return }
        
        playerHandler?.delete(items: items)
        selectedItems?.removeAll()
        invokeCommand?(.deselectAll)
        invokeCommand?(.hideToolbar)
    }
    
    private func selectedIndexPaths() -> [IndexPath]? {
        guard let handler = playerHandler else { return nil }
        return Array(Set(handler.playerQueueItems() ?? [])
                        .intersection(Set(selectedItems ?? []))).compactMap {
            if let ind = handler.playerQueueItems()?.firstIndex(of: $0) {
                return IndexPath(row: ind, section: 1)
            }
            return nil
        }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: AudioPlaylistAction) {
        switch action {
        case .onViewDidLoad:
            initScreen()
        case .move(let movedItem, let position, let direction):
            playerHandler?.move(item: movedItem, to: position, direction: direction)
        case .removeSelectedItems:
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
        case .deinit:
            playerHandler?.removePlayer(listener: self)
        }
    }
}

extension AudioPlaylistViewModel: AudioPlayerObserversProtocol {
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, queue: [AudioPlayerItem]?) {
        guard let handler = playerHandler, let currentItem = handler.playerCurrentItem() else { return }
        
        invokeCommand?(.reloadTracks(currentItem: currentItem, queue: handler.playerQueueItems(), selectedIndexPaths: selectedIndexPaths()))
    }

    func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?) {
        guard let item = item else { return }
        invokeCommand?(.reload(item: item))
    }
    
    func audioPlayerWillStartBlockingAction() {
        invokeCommand?(.disableUserInteraction)
    }
    
    func audioPlayerDidFinishBlockingAction() {
        invokeCommand?(.enableUserInteraction)
    }
}
