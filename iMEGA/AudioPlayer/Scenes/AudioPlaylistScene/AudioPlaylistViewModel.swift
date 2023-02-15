import Foundation
import MEGAPresentation

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
    private var configEntity: AudioPlayerConfigEntity
    private let router: AudioPlaylistViewRouting
    private let nodeInfoUseCase: NodeInfoUseCaseProtocol
    private var selectedItems: [AudioPlayerItem]?
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(configEntity: AudioPlayerConfigEntity, router: AudioPlaylistViewRouting, nodeInfoUseCase: NodeInfoUseCaseProtocol) {
        self.configEntity = configEntity
        self.router = router
        self.nodeInfoUseCase = nodeInfoUseCase
    }
    
    // MARK: - Private functions
    private func initScreen() {
        configEntity.playerHandler.addPlayer(listener: self)
        guard !configEntity.playerHandler.isPlayerEmpty(), let currentItem = configEntity.playerHandler.playerCurrentItem() else { return }
        invokeCommand?(.reloadTracks(currentItem: currentItem, queue: configEntity.playerHandler.playerQueueItems(), selectedIndexPaths: selectedIndexPaths()))
        invokeCommand?(.title(title: configEntity.parentNode?.name ?? ""))
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
        
        configEntity.playerHandler.delete(items: items)
        selectedItems?.removeAll()
        invokeCommand?(.deselectAll)
        invokeCommand?(.hideToolbar)
    }
    
    private func selectedIndexPaths() -> [IndexPath]? {
        return Array(Set(configEntity.playerHandler.playerQueueItems() ?? [])
                        .intersection(Set(selectedItems ?? []))).compactMap {
            if let ind = configEntity.playerHandler.playerQueueItems()?.firstIndex(of: $0) {
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
            configEntity.playerHandler.move(item: movedItem, to: position, direction: direction)
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
            configEntity.playerHandler.removePlayer(listener: self)
        }
    }
}

extension AudioPlaylistViewModel: AudioPlayerObserversProtocol {
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, queue: [AudioPlayerItem]?) {
        guard let currentItem = configEntity.playerHandler.playerCurrentItem() else { return }
        
        invokeCommand?(.reloadTracks(currentItem: currentItem, queue: configEntity.playerHandler.playerQueueItems(), selectedIndexPaths: selectedIndexPaths()))
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
