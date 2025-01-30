import Combine
import MEGADomain
import MEGAL10n

@MainActor
public final class AddToCollectionViewModel: ObservableObject {
    enum Tabs: Identifiable {
        var id: Self { self }
        case albums
        case videoPlaylists
    }
    @Published public var isAddButtonDisabled: Bool = true
    @Published public var showBottomBar: Bool = false
    @Published var selectedTab: Tabs = .albums
    
    let mode: AddToMode
    let addToAlbumsViewModel: AddToAlbumsViewModel
    let addToPlaylistViewModel: AddToPlaylistViewModel
    
    private let selectedPhotos: [NodeEntity]
    
    public var title: String {
        switch mode {
        case .album: Strings.Localizable.Set.AddTo.album
        case .collection: Strings.Localizable.Set.addTo
        }
    }
    
    public init(
        mode: AddToMode,
        selectedPhotos: [NodeEntity],
        addToAlbumsViewModel: AddToAlbumsViewModel,
        addToPlaylistViewModel: AddToPlaylistViewModel
    ) {
        self.mode = mode
        self.selectedPhotos = selectedPhotos
        self.addToAlbumsViewModel = addToAlbumsViewModel
        self.addToPlaylistViewModel = addToPlaylistViewModel
        
        subscribeToTabSelectionChanges()
    }
    
    public func addToCollectionTapped() {
        switch selectedTab {
        case .albums:
            addToAlbumsViewModel.addItems(selectedPhotos)
        case .videoPlaylists:
            addToPlaylistViewModel.addItems(selectedPhotos)
        }
    }
    
    private func subscribeToTabSelectionChanges() {
        $selectedTab
            .map { [weak self] tab -> AnyPublisher<Bool, Never> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                return switch tab {
                case .albums:
                    addToAlbumsViewModel.isAddButtonDisabled
                case .videoPlaylists:
                    addToPlaylistViewModel.isAddButtonDisabled
                }
            }
            .switchToLatest()
            .removeDuplicates()
            .assign(to: &$isAddButtonDisabled)
        
        $selectedTab
            .compactMap { [weak self] tab -> AnyPublisher<Bool, Never>? in
                guard let self else { return nil }
                return switch tab {
                case .albums:
                    addToAlbumsViewModel.isItemsNotEmptyPublisher
                case .videoPlaylists:
                    addToPlaylistViewModel.isItemsNotEmptyPublisher
                }
            }
            .switchToLatest()
            .removeDuplicates()
            .assign(to: &$showBottomBar)
    }
}
